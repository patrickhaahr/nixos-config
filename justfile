set shell := ["bash", "-c"]
export NIX_CONFIG := env('NIX_CONFIG', '') + "\nextra-experimental-features = nix-command flakes"

flake := env('FLAKE', justfile_directory())
rebuild := "nixos-rebuild"
system-args := "--elevate run0 --no-reexec"
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
    just update-browser-use
    just update-hermes
    just update-osu
    just update-kaigen
    just update-t3
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

# Bump hermes-agent to its latest upstream tag: rewrites the tag pin in
# flake.nix and refreshes the lock entry, then syncs the vendored openwakeword
# pin (hermes' lazy_deps.py) and the hey_hermes.onnx model rev in
# agent/hermes/openwakeword.nix. (openhome follows master, so the plain
# `nix flake update` above already covers it.)
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
    aspect="{{ justfile_directory() }}/modules/aspects/agent/hermes/openwakeword.nix"
    rev="$(nix flake metadata {{ flake }} --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["locks"]["nodes"]["hermes-agent"]["locked"]["rev"])')"
    pin="$(curl -sL "https://raw.githubusercontent.com/NousResearch/hermes-agent/$rev/tools/lazy_deps.py" \
      | sed -n 's/.*"openwakeword==\([^"]*\)".*/\1/p')"
    [[ -n "$pin" ]] || { echo "cannot read openwakeword pin from hermes $rev" >&2; exit 1; }
    current="$(sed -n 's/^[[:space:]]*version = "\(.*\)";$/\1/p' "$aspect")"
    if [[ "$pin" != "$current" ]]; then
      url_digest="$(curl -sL "https://pypi.org/pypi/openwakeword/$pin/json" | python3 -c '
        import json, sys
        u = [x for x in json.load(sys.stdin)["urls"] if x["filename"].endswith("-py3-none-any.whl")][0]
        print(u["url"], u["digests"]["sha256"])')"
      read -r url digest <<<"$url_digest"
      sri="$(nix hash convert --hash-algo sha256 --to sri "$digest")"
      sed -i "s|^\([[:space:]]*version = \)".*";|\1\"$pin\";|" "$aspect"
      sed -i "s|https://files.pythonhosted.org/[^\"]*openwakeword-[^\"]*\.whl|$url|" "$aspect"
      sed -i "/py3-none-any.whl/{n;s|hash = \"[^\"]*\"|hash = \"$sri\"|;}" "$aspect"
      echo "openwakeword $current -> $pin"
    fi
    oldrev="$(grep -oP 'hermes-agent/\K[0-9a-f]{40}' "$aspect" | head -1)"
    if [[ -n "$oldrev" && "$rev" != "$oldrev" ]]; then
      meta="$(nix store prefetch-file --json "https://raw.githubusercontent.com/NousResearch/hermes-agent/$rev/tools/wakewords/hey_hermes.onnx")"
      hash="$(sed -n 's/.*"hash": *"\([^"]*\)".*/\1/p' <<<"$meta")"
      sed -i "s|hermes-agent/$oldrev/tools/wakewords/hey_hermes.onnx|hermes-agent/$rev/tools/wakewords/hey_hermes.onnx|" "$aspect"
      sed -i "/hey_hermes.onnx\";/{n;s|hash = \"[^\"]*\"|hash = \"$hash\"|;}" "$aspect"
      echo "hey_hermes.onnx re-pinned to hermes $rev"
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
    projdir="$src"
    [[ -f "$projdir/pyproject.toml" ]] || projdir="$(echo "$src"/browser-use-*/pyproject.toml)"
    cp "$(dirname "$projdir")/pyproject.toml" "$workdir/"
    (cd "$workdir" && nix shell nixpkgs#uv -c uv lock --python 3.12)
    cp "$workdir/uv.lock" "$aspect/uv.lock"
    echo "browser-use $current -> $latest"

# Bump kaigen-studio to the release pinned by the vendor's installer script
# (https://api.kaigen3d.com/studio.sh): rewrites version + binary/icon sha512
# pins in desktop/kaigen-studio.nix.
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
    [[ -n "$latest" && -n "$studio_sha" && -n "$icon_sha" ]] || { echo "cannot parse https://api.kaigen3d.com/studio.sh" >&2; exit 1; }
    current="$(sed -n 's/^[[:space:]]*version = "\(.*\)";$/\1/p' "$aspect")"
    if [[ "$latest" == "$current" ]]; then
      echo "kaigen-studio $current already latest"
      exit 0
    fi
    old_hashes="$(grep -oP 'sha512 = "\K[0-9a-f]{128}' "$aspect")"
    old_studio="$(sed -n 1p <<<"$old_hashes")"
    old_icon="$(sed -n 2p <<<"$old_hashes")"
    [[ -n "$old_studio" && -n "$old_icon" ]] || { echo "cannot read current kaigen-studio pins from $aspect" >&2; exit 1; }
    sed -i \
      -e "s|version = \"$current\";|version = \"$latest\";|" \
      -e "s|$old_studio|$studio_sha|" \
      -e "s|$old_icon|$icon_sha|" \
      "$aspect"
    echo "kaigen-studio $current -> $latest"

# Bump the shared desktop/server pin to the newest stable or nightly release.
# Exclude maintainer previews and resolve both hashes before editing the pin.
[group('dev')]
[no-exit-message]
update-t3:
    #!/usr/bin/env bash
    set -euo pipefail
    aspect="{{ justfile_directory() }}/modules/aspects/agent/t3code-package.nix"
    latest="$(gh api 'repos/pingdotgg/t3code/releases?per_page=100' --paginate --jq \
      '.[] | select(.draft == false) | select((.name // "" | test("preview"; "i")) | not) | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+(-nightly\\.[0-9]{8}\\.[0-9]+)?$")) | [.published_at, .tag_name] | @tsv' \
      | sort -r | awk 'NR == 1 { print $2 }')"
    [[ -n "$latest" ]] || { echo "cannot read latest T3 Code release" >&2; exit 1; }
    ver="${latest#v}"
    current="$(sed -n 's/^[[:space:]]*version = "\(.*\)";$/\1/p' "$aspect")"
    if [[ "$ver" == "$current" ]]; then
      echo "T3 Code $current already latest"
      exit 0
    fi
    echo "Fetching T3 Code $ver and resolving its dependencies"
    meta="$(nix store prefetch-file --unpack --hash-type sha256 --json "https://github.com/pingdotgg/t3code/archive/refs/tags/$latest.tar.gz")"
    hash="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["hash"])' <<<"$meta")"
    workdir="$(mktemp -d)"
    trap 'rm -rf "$workdir"' EXIT
    export T3CODE_VERSION="$ver" T3CODE_SOURCE_HASH="$hash"
    # A fixed-output build with a dummy hash reports the actual pnpm store hash.
    if nix build --no-link --impure --expr '
      let
        flake = builtins.getFlake "{{ flake }}";
        pkgs = flake.nixosConfigurations.zaza.pkgs;
        version = builtins.getEnv "T3CODE_VERSION";
      in pkgs.t3code.unwrapped.pnpmDeps.overrideAttrs {
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = "pingdotgg";
          repo = "t3code";
          tag = "v${version}";
          hash = builtins.getEnv "T3CODE_SOURCE_HASH";
        };
        outputHash = pkgs.lib.fakeHash;
      }' 2>"$workdir/deps.log"; then
      echo "expected a pnpm dependency hash mismatch" >&2
      exit 1
    fi
    if ! grep -q "hash mismatch in fixed-output derivation '.*t3code-unwrapped-pnpm-deps.drv'" "$workdir/deps.log"; then
      cat "$workdir/deps.log" >&2
      exit 1
    fi
    deps_hash="$(sed -n 's/.*got:[[:space:]]*\(sha256-[A-Za-z0-9+/=]*\)$/\1/p' "$workdir/deps.log")"
    [[ -n "$deps_hash" ]] || { cat "$workdir/deps.log" >&2; exit 1; }
    sed -i \
      -e "s|version = \".*\";|version = \"$ver\";|" \
      -e "s|hash = \"sha256-.*\";|hash = \"$hash\";|" \
      -e "s|outputHash = \"sha256-.*\";|outputHash = \"$deps_hash\";|" \
      "$aspect"
    echo "T3 Code $current -> $ver"

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
