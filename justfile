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
deploy host action="switch" *args:
    #!/usr/bin/env bash
    set -euo pipefail

    build_host="${BUILD_HOST:-{{ host }}}"
    before="$(ssh -q {{ host }} 'readlink -e /run/current-system || true')"

    nixos-rebuild "{{ action }}" \
      --flake {{ flake }}#{{ host }} \
      --target-host {{ host }} \
      --build-host "$build_host" \
      --use-substitutes \
      --elevate {{ deploy-elevate }} \
      --ask-elevate-password \
      --log-format internal-json \
      {{ args }}

    after="$(ssh -q {{ host }} 'readlink -e /run/current-system || true')"
    if [[ -n "$before" && -n "$after" && "$before" != "$after" ]]; then
      echo
      echo "===== {{ host }} ({{ action }}) ====="
      ssh {{ host }} TERM=xterm-256color nix store diff-closures "$before" "$after" || true
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
    nix flake update {{ inputs }} --flake {{ flake }}

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
