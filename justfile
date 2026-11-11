set shell := ["bash", "-c"]
export NIX_CONFIG := env('NIX_CONFIG', '') + "\nextra-experimental-features = nix-command flakes"

flake := env('FLAKE', justfile_directory())
rebuild := "nixos-rebuild"
# WSL has no polkit agent to prompt for run0, so nixos-rebuild asks for the password itself.
system-args := "--elevate run0 --no-reexec" + if env('WSL_DISTRO_NAME', '') != '' { " --ask-elevate-password" } else { "" }
elevate := env('ELEVATE', 'doas')
deploy-elevate := env('DEPLOY_ELEVATE', 'run0')

[private]
default:
    @just --list --unsorted

# ------------------------------------------------------------------------------
# rebuild
# ------------------------------------------------------------------------------

[group('rebuild')]
[no-exit-message]
[private]
builder goal host=`hostname -s` *args:
    {{ rebuild }} {{ goal }} \
      --flake {{ flake }}#{{ host }} \
      {{ system-args }} \
      {{ args }}

[group('rebuild')]
[no-exit-message]
switch host=`hostname -s` *args: (builder "switch" host args)

[group('rebuild')]
[no-exit-message]
boot host=`hostname -s` *args: (builder "boot" host args)

[group('rebuild')]
[no-exit-message]
test host=`hostname -s` *args: (builder "test" host args)

[group('rebuild')]
[no-exit-message]
rollback *args:
    {{ rebuild }} switch --rollback \
      {{ system-args }} \
      {{ args }}

[group('rebuild')]
[no-exit-message]
deploy host target=host action="switch" *args:
    #!/usr/bin/env bash
    set -euo pipefail

    build_host="${BUILD_HOST:-{{ target }}}"
    ssh_args=()
    if [[ -f "$HOME/.ssh/id_ed25519_{{ target }}" ]]; then
      ssh_args=(-i "$HOME/.ssh/id_ed25519_{{ target }}" -o IdentitiesOnly=yes)
      export NIX_SSHOPTS="-i $HOME/.ssh/id_ed25519_{{ target }} -o IdentitiesOnly=yes"
    fi
    before="$(ssh -q "${ssh_args[@]}" {{ target }} "bash -lc 'readlink -e /run/current-system || true'")"

    nixos-rebuild "{{ action }}" \
      --flake {{ flake }}#{{ host }} \
      --target-host {{ target }} \
      --build-host "$build_host" \
      --use-substitutes \
      --elevate {{ deploy-elevate }} \
      --ask-elevate-password \
      {{ args }}

    after="$(ssh -q "${ssh_args[@]}" {{ target }} "bash -lc 'readlink -e /run/current-system || true'")"
    if [[ -n "$before" && -n "$after" && "$before" != "$after" ]]; then
      echo
      echo "===== {{ target }} ({{ action }}) ====="
      ssh "${ssh_args[@]}" {{ target }} TERM=xterm-256color nix store diff-closures "$before" "$after" || true
    fi

# ------------------------------------------------------------------------------
# validation
# ------------------------------------------------------------------------------

[group('validation')]
[no-exit-message]
check *args: fmt lint
    nix flake check {{ flake }} {{ args }}

[group('validation')]
[no-exit-message]
build host=`hostname -s` *args:
    nix build \
      {{ flake }}#nixosConfigurations.{{ host }}.config.system.build.toplevel \
      --dry-run \
      {{ args }}

[group('validation')]
[no-exit-message]
verify host=`hostname -s` *args:
    just check
    just build {{ host }} {{ args }}

[group('validation')]
[no-exit-message]
lint *args:
    statix check {{ args }} .

# ------------------------------------------------------------------------------
# dev
# ------------------------------------------------------------------------------

[group('dev')]
[no-exit-message]
fmt:
    nix fmt {{ flake }}

[group('dev')]
[no-exit-message]
[positional-arguments]
update *inputs:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ $# -gt 0 ]]; then
      exec just update-flake "$@"
    fi
    just update-flake
    just update-skills
    just update-browser-use
    just update-hermes
    just update-osu
    just update-kaigen
    just update-learnharness

# Update AI packages (Codex, Claude, OpenCode, T3 Code, Pi, Hermes, and more).
[group('dev')]
[no-exit-message]
update-ai:
    just update-flake llm-agents cliproxyapi
    just update-browser-use
    just update-hermes
    just update-learnharness

# Flake input resolution runs in the client, which needs its own GitHub token.
[private]
[no-exit-message]
[positional-arguments]
update-flake *inputs:
    #!/usr/bin/env bash
    set -euo pipefail
    token="$(gh auth token --hostname github.com)"
    export NIX_CONFIG="${NIX_CONFIG}"$'\n'"extra-access-tokens = github.com=$token"
    exec nix flake update "$@" --flake {{ flake }}

# Pin the skill repos in agents/skill-sources/sources.nix to their default
# branch heads and rewrite sources.lock.json. Pass owner/repo slugs to bump only
# those; other entries keep their pins. Repos no longer listed are dropped.
[group('dev')]
[no-exit-message]
[positional-arguments]
update-skills *repos:
    #!/usr/bin/env bash
    set -euo pipefail
    dir="{{ justfile_directory() }}/agents/skill-sources"
    lock="$dir/sources.lock.json"
    spec="$(nix eval --json --file "$dir/sources.nix")"
    prefetch="$(nix build --no-link --print-out-paths nixpkgs#nix-prefetch-git)/bin/nix-prefetch-git"
    new='{}'
    for slug in $(jq -r 'keys[]' <<<"$spec"); do
      # Same order and whole-repo rule as sparseCheckout in default.nix.
      paths="$(jq -c --arg s "$slug" '.[$s] | [.[]] | if any(. == "") then [] else . end' <<<"$spec")"
      if [[ $# -gt 0 && " $* " != *" $slug "* ]]; then
        pin="$(jq -c --arg s "$slug" '.[$s] // empty' "$lock")"
        [[ -n "$pin" ]] || { echo "$slug is not locked; run just update-skills $slug" >&2; exit 1; }
        new="$(jq --arg s "$slug" --argjson pin "$pin" '.[$s] = $pin' <<<"$new")"
        continue
      fi
      url="https://github.com/$slug"
      old="$(jq -r --arg s "$slug" '.[$s].rev // "none"' "$lock")"
      rev="$(git ls-remote "$url" HEAD | cut -f1)"
      [[ -n "$rev" ]] || { echo "cannot read HEAD of $slug" >&2; exit 1; }
      hash="$("$prefetch" --quiet --url "$url" --rev "$rev" --sparse-checkout "$(jq -r 'join("\n")' <<<"$paths")" | jq -r .hash)"
      new="$(jq --arg s "$slug" --arg rev "$rev" --arg hash "$hash" --argjson paths "$paths" \
        '.[$s] = {rev: $rev, hash: $hash, paths: $paths}' <<<"$new")"
      [[ "$rev" == "$old" ]] || echo "$slug ${old:0:7} -> ${rev:0:7}"
    done
    jq -S . <<<"$new" >"$lock"

# Bump hermes-agent to its latest upstream tag and refresh the lock entry.
[group('dev')]
[no-exit-message]
update-hermes:
    #!/usr/bin/env bash
    set -euo pipefail
    latest="$(gh api repos/NousResearch/hermes-agent/releases/latest --jq .tag_name)"
    [[ -n "$latest" ]] || { echo "cannot read latest hermes-agent release" >&2; exit 1; }
    if grep -q "hermes-agent/$latest\";" flake.nix; then
      echo "hermes-agent $latest already latest"
    else
      sed -i "s|hermes-agent/[^\"]*\";|hermes-agent/$latest\";|" flake.nix
      just update-flake hermes-agent
    fi

# Bump browser-use to its latest upstream tag: rewrites version + source
# hash in agent/browser-use/default.nix and regenerates the vendored uv.lock.
[group('dev')]
[no-exit-message]
update-browser-use:
    #!/usr/bin/env bash
    set -euo pipefail
    aspect="{{ justfile_directory() }}/modules/aspects/agent/browser-use"
    latest="$(gh api repos/browser-use/browser-use/releases/latest --jq .tag_name)"
    [[ -n "$latest" ]] || { echo "cannot read latest browser-use release" >&2; exit 1; }
    current="$(sed -n 's/^[[:space:]]*version = "\(.*\)";$/\1/p' "$aspect/default.nix")"
    if [[ "$latest" == "$current" ]]; then
      echo "browser-use $current already latest"
      exit 0
    fi
    url="https://github.com/browser-use/browser-use/archive/refs/tags/$latest.tar.gz"
    meta="$(nix store prefetch-file --unpack --hash-type sha256 --json "$url")"
    hash="$(sed -n 's/.*"hash": *"\([^"]*\)".*/\1/p' <<<"$meta")"
    src="$(sed -n 's/.*"storePath": *"\([^"]*\)".*/\1/p' <<<"$meta")"
    sed -i "s|^[[:space:]]*version = \".*\";|  version = \"$latest\";|" "$aspect/default.nix"
    sed -i "s|hash = \"sha256-.*\";|hash = \"$hash\";|" "$aspect/default.nix"
    workdir="$(mktemp -d)"
    trap 'rm -rf "$workdir"' EXIT
    projfile="$src/pyproject.toml"
    [[ -f "$projfile" ]] || projfile="$(echo "$src"/browser-use-*/pyproject.toml)"
    cp "$projfile" "$workdir/"
    (cd "$workdir" && nix shell nixpkgs#uv -c uv lock --python 3.12)
    cp "$workdir/uv.lock" "$aspect/uv.lock"
    echo "browser-use $current -> $latest"

# Refresh Kaigen CLI and Studio versions and checksums from the vendor's
# install.sh (Linux) and studio.sh, including pins for an unchanged version.
[group('dev')]
[no-exit-message]
update-kaigen:
    #!/usr/bin/env bash
    set -euo pipefail
    aspect="{{ justfile_directory() }}/modules/aspects/desktop/kaigen-studio.nix"
    script="$(curl -fsSL https://api.kaigen3d.com/studio.sh)"
    latest="$(sed -n 's/^VERSION="\([^"]*\)"/\1/p' <<<"$script")"
    studio_sha="$(sed -n 's/^STUDIO_SHA512="\([^"]*\)"/\1/p' <<<"$script")"
    icon_sha="$(sed -n 's/^ICON_SHA512="\([^"]*\)"/\1/p' <<<"$script")"
    cli_script="$(curl -fsSL https://api.kaigen3d.com/install.sh)"
    cli_latest="$(sed -n '/^  Linux)/,/^    ;;/s/^    VERSION="\([^"]*\)"$/\1/p' <<<"$cli_script")"
    cli_sha="$(sed -n '/^  Linux)/,/^    ;;/s/^    SHA512="\([^"]*\)"$/\1/p' <<<"$cli_script")"
    [[ "$latest" =~ ^[0-9]+(\.[0-9]+)+$ && "$cli_latest" =~ ^[0-9]+(\.[0-9]+)+$ \
      && "$studio_sha" =~ ^[0-9a-f]{128}$ && "$icon_sha" =~ ^[0-9a-f]{128}$ \
      && "$cli_sha" =~ ^[0-9a-f]{128}$ ]] || { echo "cannot parse Kaigen installer versions and checksums" >&2; exit 1; }
    sed -i -E \
      -e "s|^([[:space:]]*version = )\"[^\"]*\";|\1\"$latest\";|" \
      -e "s|^([[:space:]]*cliVersion = )\"[^\"]*\";|\1\"$cli_latest\";|" \
      -e "s|^([[:space:]]*cliSha512 = )\"[^\"]*\";|\1\"$cli_sha\";|" \
      -e "s|^([[:space:]]*studioSha512 = )\"[^\"]*\";|\1\"$studio_sha\";|" \
      -e "s|^([[:space:]]*iconSha512 = )\"[^\"]*\";|\1\"$icon_sha\";|" \
      "$aspect"
    echo "refreshed kaigen $cli_latest and kaigen-studio $latest release pins"

# Bump osu-tachyon to the latest tachyon stream tag: rewrites version, tag URL
# and AppImage hash in desktop/osu-lazer.nix. (Stable osu-lazer tracks nixpkgs.)
[group('dev')]
[no-exit-message]
update-osu:
    #!/usr/bin/env bash
    set -euo pipefail
    aspect="{{ justfile_directory() }}/modules/aspects/desktop/osu-lazer.nix"
    latest="$(gh api repos/ppy/osu/releases --jq '[.[] | select(.prerelease)][0].tag_name')"
    [[ -n "$latest" ]] || { echo "cannot read latest osu tachyon release" >&2; exit 1; }
    ver="${latest%-tachyon}"
    current="$(sed -n 's/^[[:space:]]*version = "\(.*\)";$/\1/p' "$aspect")"
    if [[ "$ver" == "$current" ]]; then
      echo "osu-tachyon $current already latest"
      exit 0
    fi
    meta="$(nix store prefetch-file --json "https://github.com/ppy/osu/releases/download/$latest/osu.AppImage")"
    hash="$(sed -n 's/.*"hash": *"\([^"]*\)".*/\1/p' <<<"$meta")"
    sed -i "s|version = \".*\";|version = \"$ver\";|" "$aspect"
    sed -i "s|releases/download/[^\"]*/osu.AppImage|releases/download/$latest/osu.AppImage|" "$aspect"
    sed -i "s|hash = \"sha256-.*\";|hash = \"$hash\";|" "$aspect"
    echo "osu-tachyon $current -> $ver"

# Bump LearnHarness to its latest upstream release: rewrites version + AppImage
# hash in desktop/learnharness.nix. (URL and artifact name interpolate version.)
[group('dev')]
[no-exit-message]
update-learnharness:
    #!/usr/bin/env bash
    set -euo pipefail
    aspect="{{ justfile_directory() }}/modules/aspects/desktop/learnharness.nix"
    latest="$(gh api repos/amosblomqvist/learnharness/releases/latest --jq .tag_name)"
    [[ -n "$latest" ]] || { echo "cannot read latest learnharness release" >&2; exit 1; }
    ver="${latest#v}"
    current="$(sed -n 's/^[[:space:]]*version = "\(.*\)";$/\1/p' "$aspect")"
    if [[ "$ver" == "$current" ]]; then
      echo "learnharness $current already latest"
      exit 0
    fi
    meta="$(nix store prefetch-file --json "https://github.com/amosblomqvist/learnharness/releases/download/v${ver}/LearnHarness-${ver}-x86_64.AppImage")"
    hash="$(sed -n 's/.*"hash": *"\([^"]*\)".*/\1/p' <<<"$meta")"
    sed -i "s|version = \".*\";|version = \"$ver\";|" "$aspect"
    sed -i "s|hash = \"sha256-.*\";|hash = \"$hash\";|" "$aspect"
    echo "learnharness $current -> $ver"

[group('dev')]
[no-exit-message]
repl:
    nix repl {{ flake }}

[group('dev')]
[no-exit-message]
repl-host host=`hostname -s`:
    nix repl {{ flake }}#nixosConfigurations.{{ host }}

[group('dev')]
[no-exit-message]
dev name="default":
    nix develop {{ flake }}#{{ name }}

[group('dev')]
[no-exit-message]
history:
    nix profile history --profile /nix/var/nix/profiles/system

# ------------------------------------------------------------------------------
# utils
# ------------------------------------------------------------------------------

alias fix := repair

[group('utils')]
[no-exit-message]
clean:
    {{ elevate }} nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d

[group('utils')]
[no-exit-message]
gc:
    {{ elevate }} nix-collect-garbage --delete-older-than 7d
    {{ elevate }} nix store optimise

[group('utils')]
[no-exit-message]
gcroot:
    ls -al /nix/var/nix/gcroots/auto/

[group('utils')]
[no-exit-message]
verify-store:
    {{ elevate }} nix store verify --all

[group('utils')]
[no-exit-message]
repair *paths:
    {{ elevate }} nix store repair {{ paths }}
