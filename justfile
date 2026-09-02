set shell := ["bash", "-c"]
export NIX_CONFIG := "experimental-features = nix-command flakes"

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
update *inputs:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ $# -gt 0 ]]; then
      exec nix flake update "$@" --flake {{ flake }}
    fi
    nix flake update --flake {{ flake }}
    just update-browser-use
    just update-hermes

# Bump hermes-agent to its latest upstream tag: rewrites the tag pin in
# flake.nix and refreshes the lock entry. (openhome follows master, so the
# plain `nix flake update` above already covers it.)
[group('dev')]
[no-exit-message]
update-hermes:
    #!/usr/bin/env bash
    set -euo pipefail
    latest="$(curl -fsSL https://api.github.com/repos/NousResearch/hermes-agent/releases/latest |
      sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p')"
    [[ -n "$latest" ]] || { echo "cannot read latest hermes-agent release" >&2; exit 1; }
    if grep -q "hermes-agent/$latest\";" flake.nix; then
      echo "hermes-agent $latest already latest"
    else
      sed -i "s|hermes-agent/[^\"]*\";|hermes-agent/$latest\";|" flake.nix
      nix flake update hermes-agent --flake {{ flake }}
    fi

# Bump browser-use to its latest upstream tag: rewrites version + source
# hash in agent/browser-use/default.nix and regenerates the vendored uv.lock.
[group('dev')]
[no-exit-message]
update-browser-use:
    #!/usr/bin/env bash
    set -euo pipefail
    aspect="{{ justfile_directory() }}/modules/aspects/agent/browser-use"
    latest="$(curl -fsSL https://api.github.com/repos/browser-use/browser-use/releases/latest |
      sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p')"
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
