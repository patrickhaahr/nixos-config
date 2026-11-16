---
name: homelab-host-health
description: Use when checking homelab CPU, GPU, RAM or disk pressure.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [homelab, performance, storage, diagnostics]
---
# Homelab host health and storage diagnosis

## When to use
Use for resource-health checks, unexplained disk usage, slow hosts, and requests to reclaim space. Load the SSH skill for remote hosts and the relevant repository guidance before touching project artifacts.

## Fast path
For a status question, run `scripts/snapshot.sh` in one round trip and answer from it: `ssh <alias> sh -s < scripts/snapshot.sh` (works on nika, pi, router; on zaza run `sh scripts/snapshot.sh`). It covers load, pressure, memory, disks, temperatures, GPU, failed units, containers, top processes and recent errors. Go to the procedure below only when the snapshot shows a problem or Patrick asks for a diagnosis.

## Procedure
1. Establish live state with `hostname`, `uptime`, `nproc`, `free -h`, `df -hT /`, `vmstat 1 5`, `/proc/pressure/{cpu,memory,io}`, and a bounded process listing. Query `nvidia-smi` and thermal sensors when relevant. Treat the first vmstat row as since-boot history; use subsequent rows for current behavior.
2. Separate compute saturation from blocked I/O. High load with high I/O wait and many blocked tasks is not proof that the CPU is undersized. Follow busy processes to their parent command and project; truncate command arguments before printing because linker invocations can be enormous.
3. Measure storage before blaming a workload. Patrick expects actual path attribution, especially after a recent cleanup; never infer that a running Rust build accounts for an arbitrary amount of used space. Start with bounded directory depths on likely paths, then drill into the largest child. See [storage accounting](references/storage-accounting.md) for commands and caveats.
4. Keep diagnostics cheaper than the problem. Avoid concurrent recursive scans of `/` and `/nix/store`. Run one necessary expensive scan at low CPU/I/O priority in a tracked job; consume its completion notification instead of repeated polling. After a timed-out elevated command, check for surviving diagnostic processes before retrying.
5. Reclaim only clearly regenerable data within the authorized scope. Check for active builds and users of the target first. Prefer a narrow incremental-cache cleanup over a full target wipe; preserve source, databases, dependency artifacts, release binaries, and rollback generations unless a broader deletion is explicitly justified. Never kill another agent's build merely to make the metrics look better.
6. Verify freed space with before/after filesystem bytes and re-sample vmstat/PSI after cleanup writes settle. Recheck build activity: distinguish improvement from a build finishing from improvement caused by cleanup. Do not claim a durable fix from one idle sample or from deleting caches that the next build recreates.
7. Report concise measured findings, the exact cleanup scope, remaining uncertainty, and whether any long scan is still pending. Separate physical bytes from logical/apparent sizes, and label GiB versus GB correctly. Keep incomplete attribution explicitly incomplete.

## Recurrence prevention
Only change build profiles, debug symbols, incremental settings, or concurrency after inspecting the project's actual configuration and checking the workflow impact. A large debug/test build can legitimately regenerate soon after cleaning; cache removal alone is not proof that future growth is solved. Ship persistent Nix/project changes through their normal review and verification workflow rather than altering unrelated runtime configuration.

## tailscaled post-start regression on zaza
Trace this to nixos-config commit `85cba40` (`fix(homelab): t3code tailscale serve`): `modules/aspects/homelab/traefik.nix` added the fatal postStart hook. Do not describe it as an established upstream 1.104.x regression: the evidence identifies a local lifecycle/idempotency bug. T3 itself runs without `--tailscale-serve`. Prefer a `/run/systemd/system/tailscaled.service.d/zz-recovery.conf` override clearing ExecStartPost via `run0 --no-ask-password --pipe`, then daemon-reload/reset-failed/start the normal unit; verify tailnet login and SSH. This override is temporary. Ship the lasting fix through the repo workflow.

### Historical workaround
NixOS's tailscaled-unit ExecStartPost runs `tailscale serve --https=443 off`; on tailscale 1.104.4 it exits (~1s) with `unexpected state: NoState` when the backend isn't logged in yet, the unit restart-spins and trips its start limit. Symptoms: `tailscaled.service: Start request repeated too quickly`, `tailscaled-post-start: unexpected state: NoState`. Workaround (runtime only, gone after reboot): transient `systemd-run --unit=tailscale-emergency` with `ExecStartPost=/run/tailscale-wait.sh` script that polls `tailscale status` until non-NoState, then runs the serve call and treats "handler does not exist" as success; transient default PATH lacks coreutils, so the script must set PATH itself. Real fix must land in zaza.nix (systemd.services.tailscaled override) — /etc is read-only for the agent sandbox.
