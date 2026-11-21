#!/bin/sh
has() { command -v "$1" >/dev/null 2>&1; }
section() { printf "\n== %s\n" "$1"; }
section host; cat /proc/sys/kernel/hostname; uname -sr; uptime
section cpu; nproc 2>/dev/null; cat /proc/loadavg
section pressure; for r in cpu memory io; do [ -r /proc/pressure/$r ] && printf "%s: %s\n" "$r" "$(head -1 /proc/pressure/$r)"; done
section memory; free -h 2>/dev/null || free
section disks; df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null || df -h
section temperature
for z in /sys/class/thermal/thermal_zone*/temp; do [ -r "$z" ] && printf "%s %s C\n" "$(cat "${z%temp}type")" "$(($(cat "$z") / 1000))"; done
has sensors && sensors 2>/dev/null | grep -E "^(Tctl|Tdie|Package|Composite|edge)" | head -6
has nvidia-smi && nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv,noheader
section failed-units
if has systemctl; then systemctl --failed --no-legend --plain 2>/dev/null | head -20; systemctl --user --failed --no-legend --plain 2>/dev/null | head -10; fi
section containers
has docker && docker ps --format "{{.Names}} {{.Status}}" 2>/dev/null | head -40
has kubectl && kubectl get pods -A --no-headers 2>/dev/null | awk "\$4 != \"Running\" && \$4 != \"Completed\" && \$4 != \"ContainerStatusUnknown\"" | head -20
section top-processes; ps -eo pid,pcpu,pmem,comm --sort=-pcpu 2>/dev/null | head -8 || top -bn1 | head -15
section recent-errors
has journalctl && journalctl -p err -b --since "-24h" --no-pager -q 2>/dev/null | tail -15
