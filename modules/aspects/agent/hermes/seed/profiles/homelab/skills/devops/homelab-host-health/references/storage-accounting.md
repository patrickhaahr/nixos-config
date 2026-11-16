# Storage accounting and targeted cleanup

## Attribute usage without creating more pressure
- Capture `df -B1 /` and `lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS` first. Establish filesystem and mount topology before summing paths.
- Start at likely consumers: `du -x -B1 --max-depth=1 /home/hermes`, then the largest project and its build directories. Inspect system storage separately with appropriate privileges: `/var/lib/rancher/k3s`, logs, other user homes, temporary storage, and the Nix store.
- Do not assume `du -x /` avoids all duplicate accounting. Bind mounts on the same filesystem can still be traversed, including store and kubelet paths. Permission-denied totals are lower bounds, not complete measurements; do not hide that limitation when reporting them.
- Prefer one targeted expensive traversal using `ionice -c 3 nice -n 19 du -sx -B1 <path>` over broad parallel scans. Use explicit output piping with headless run0, and inspect its transient command if the caller times out; the root scan can survive the caller.
- For a fast Nix inventory, `nix path-info --all --json --json-format 1` exposes path metadata including narSize. Sum programmatically, but label the result as serialized NAR size, not allocated filesystem usage or reclaimable bytes. Do not hand-delete store paths or claim a garbage-collection estimate from this sum.

## Investigate space that cleanup did not free
Inspect deleted-but-open regular files using lsof when available, or scan `/proc/<pid>/fd` with elevated Python. For links ending in ` (deleted)`, stat the descriptor and deduplicate by `(st_dev, st_ino)`. Sum `st_blocks * 512` for allocated bytes, not merely st_size; skip sockets and pipes. A deleted pathname is not a reason to restart its owning service unless retained space is material and restart impact is understood.

## Rust build artifacts
1. Measure each crate's `target` independently; separate `debug/{incremental,deps,examples,build}` and `release`. Do not mistake cache-registry size for project build-output size.
2. Inspect large files and modification times in debug/deps. Many separately linked integration-test executables can each contain substantial debug information, so a recent clean build can legitimately recreate large output. File size alone does not prove an artifact is stale or duplicated.
3. Before cleanup, check for cargo, rustc, linker processes and any task using the target. Resolve exact paths; reject symlinked targets. Avoid racing an active build.
4. Within an authorized cleanup, removing only `target/debug/incremental` discards regenerable incremental state while retaining linked outputs and compiled dependencies. Report that the next build may lose incremental reuse and recreate this cache. Do not run a full build solely to verify space reclamation, because it repopulates what was removed.
5. Verify path removal and `df` delta. Do not promise the per-directory sum equals newly available space exactly: concurrent writes, hardlinks, filesystem metadata, and allocation timing affect it.

## Interpreting the final sample
- Available RAM includes reclaimable cache; low free RAM alone is not exhaustion. Existing swap usage does not prove current thrashing—inspect si/so and memory PSI.
- Use CPU and I/O PSI with vmstat wait/blocked tasks to distinguish scheduling contention from storage stalls.
- If iostat is unavailable, sample `/sys/block/<device>/stat` twice. Field indexes 2 and 6 are sectors read/written, index 9 is milliseconds doing I/O; use 512-byte sectors for those counters. Disk busy time alone is not a health diagnosis.
- Record temperatures separately from utilization. An idle, cool GPU does not explain or resolve a storage-bound build.
