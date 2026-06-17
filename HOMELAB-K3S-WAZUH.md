# Homelab NixOS, k3s, Monitoring, and Wazuh Plan

## Goal

Run the homelab declaratively on NixOS while using k3s to learn Kubernetes. Keep the system reliable enough for real services, but use low-risk workloads first while learning Kubernetes operations. Start with the Intel homelab machine and migrate the Raspberry Pi only after the Intel setup is stable.

## Recommended Architecture

```text
zaza host: Intel i5-8600 / GTX 1060 / 16 GB RAM
└── NixOS
    ├── k3s server / control plane
    ├── host-level services
    │   ├── Wazuh agent
    │   ├── node exporter
    │   └── backup jobs
    ├── k3s workloads
    │   ├── Prometheus / Grafana
    │   ├── kube-state-metrics
    │   ├── blackbox exporter
    │   ├── Traefik ingress
    │   ├── Homepage
    │   ├── SearXNG
    │   ├── Excalidraw
    │   ├── Hermes agent
    │   └── small custom apps
    └── Wazuh server stack
        └── Podman/Docker first, k3s later if desired

Raspberry Pi 5 / 8 GB RAM
└── NixOS, later
    ├── k3s agent / worker
    ├── Wazuh agent
    ├── node exporter
    └── lightweight or backup services
```

## k3s vs Full Kubernetes

Use k3s.

k3s teaches the useful Kubernetes concepts with much less operational overhead:

- Deployments
- Services
- Ingress
- ConfigMaps
- Secrets
- PersistentVolumes
- StatefulSets
- Helm
- Namespaces
- RBAC
- Kubernetes monitoring

Avoid full upstream Kubernetes with kubeadm unless the goal is specifically to learn kubeadm, etcd management, CNI setup, and control-plane internals.

## NixOS Role

Do not manually install services imperatively. Use NixOS as the declarative host layer.

Use NixOS for:

- host networking
- firewall rules
- users and groups
- disks and mounts
- k3s service management
- backup jobs
- host exporters
- Wazuh agents
- secrets management

Use containers or Kubernetes for app workloads.

## Kubernetes Workload Strategy

Start with low-risk services in k3s:

- Homepage
- Excalidraw
- SearXNG
- Wishlist
- Hermes agent
- small custom apps
- Prometheus / Grafana
- blackbox exporter

Be more careful with stateful or device-heavy services:

- Immich
- Vaultwarden
- Forgejo
- Jellyfin
- qBittorrent

These can run in Kubernetes later, but they require stronger storage, backup, restore, secrets, and device-passthrough discipline.

## Hermes Agent

Run the Hermes agent on the Intel homelab PC.

Initial recommendation:

- run Hermes on the Intel box, not the Raspberry Pi
- treat it as an early k3s workload if it does not need privileged host access
- use explicit persistent storage under `/srv/homelab/hermes` if it stores state
- expose it through Traefik like the other Kubernetes services
- add resource limits early so it cannot starve the rest of the homelab

If Hermes needs GPU access, host-level device access, or unusual runtime permissions, start it outside k3s with Podman/Docker first and migrate it into k3s later.

## Raspberry Pi Role

Converting the Raspberry Pi 5 to NixOS is reasonable for consistency, but it is not part of phase one.

First stabilize the Intel homelab machine:

- NixOS host config
- k3s server
- Traefik ingress
- monitoring
- Wazuh agent and server stack
- backups
- a few migrated low-risk services

Only migrate the Raspberry Pi after the Intel setup is stable and recoverable.

Best uses:

- k3s worker node
- monitoring target
- Wazuh-monitored Linux host
- backup destination
- DNS or lightweight network service
- small stateless Kubernetes workloads

Do not start by making the Pi the control plane. Use the Intel box as the k3s server because it has more CPU, RAM, and storage flexibility.

## Monitoring

Use Prometheus and Grafana for health and metrics.

Recommended first Kubernetes monitoring stack:

- kube-prometheus-stack
- Prometheus
- Grafana
- Alertmanager
- kube-state-metrics
- node exporter
- blackbox exporter

Prometheus/Grafana should monitor:

- host CPU, memory, disk, and network
- k3s node health
- pod health
- service availability
- HTTP endpoints
- storage usage

This does not replace Wazuh. Prometheus is for metrics. Wazuh is for security events.

## Wazuh

Wazuh works well for Linux monitoring and host intrusion detection.

Use Wazuh for:

- file integrity monitoring
- log analysis
- SSH/auth monitoring
- rootkit checks
- vulnerability detection
- compliance checks
- suspicious behavior alerts
- host inventory

Run Wazuh agents directly on each Linux host:

- Intel NixOS host
- Raspberry Pi NixOS host
- any future Linux hosts

Do not rely on a normal containerized Wazuh agent for host visibility. The agent should run on the host so it can see host logs, files, packages, and system state.

## Wazuh on NixOS

Wazuh can monitor NixOS, but expect some NixOS-specific configuration.

Traditional Linux paths like `/var/log/auth.log` may not exist. On NixOS, many useful events are in `journald`.

Useful paths to monitor:

- `/etc/nixos`
- `/srv/homelab`
- `/var/lib`
- `/var/log`
- `/var/lib/rancher/k3s`

Useful event sources:

- systemd journal
- SSH service logs
- sudo/doas logs
- k3s logs
- container runtime logs

## Where to Run the Wazuh Server Stack

Start by running the Wazuh server stack outside k3s, using Podman or Docker.

Reason: if Kubernetes is the system being experimented with and it breaks, security monitoring should ideally remain available.

Move Wazuh into k3s later only after becoming comfortable with:

- persistent volumes
- ingress
- secrets
- certificates
- backups
- restore testing
- resource limits

Wazuh is stateful and heavier than a simple web app. It includes manager, indexer, dashboard, certificates, exposed ports, and persistent storage.

## Storage

Start simple with k3s `local-path-provisioner`.

For important service data, prefer explicit host storage:

```text
/srv/homelab/<service>
```

Backups should exist outside Kubernetes. Do not treat a PersistentVolume as a backup.

Consider more advanced storage later:

- Longhorn
- OpenEBS
- NFS provisioner
- ZFS-backed storage

Do not start there unless storage systems are the learning goal.

## Ingress

k3s includes Traefik by default.

Use Traefik as the primary ingress for the k3s homelab. This is the preferred path because the goal is to learn Kubernetes-native ingress.

Do not use Caddy as the primary reverse proxy for the new Intel k3s setup. Caddy can remain relevant for the old Compose setup during migration, but Traefik is the target ingress for Kubernetes services.

Recommended learning path:

```text
Cloudflare DNS -> router -> Traefik -> Kubernetes services
```

## Secrets

Add proper encrypted secrets before migrating sensitive services.

Recommended approach:

- sops-nix

Use it for:

- Cloudflare API token
- Wazuh passwords and certificates
- Grafana admin credentials
- Vaultwarden admin token
- database passwords
- Forgejo secrets
- Immich secrets

## Migration Order

1. Add a dedicated NixOS host/module for the Intel homelab machine.
2. Enable k3s server declaratively on the Intel host.
3. Deploy one simple test app.
4. Add ingress with Traefik.
5. Add Prometheus/Grafana with kube-prometheus-stack.
6. Add host-level Wazuh agent on the Intel machine.
7. Run the Wazuh server stack outside k3s with Podman or Docker.
8. Add Hermes agent on the Intel machine, preferably as a k3s workload if its runtime requirements are simple.
9. Move low-risk services into k3s.
10. Add sops-nix before moving secrets-heavy services.
11. Stabilize and test backups/restore on the Intel setup.
12. Convert the Raspberry Pi to NixOS only after the Intel setup is stable.
13. Join the Raspberry Pi as a k3s worker.
14. Only then consider moving stateful services like Forgejo, Vaultwarden, Immich, or Jellyfin.

## Final Target

```text
NixOS zaza host (Intel PC)
├── k3s server
│   ├── learning workloads
│   ├── Traefik ingress
│   ├── Prometheus / Grafana
│   ├── Hermes agent
│   └── low-risk homelab apps
├── Wazuh server stack
│   └── Podman/Docker first, k3s later
├── Wazuh agent
├── node exporter
└── backups

NixOS Raspberry Pi
├── k3s agent
├── Wazuh agent
├── node exporter
└── lightweight services or backup role
```

## Summary

Use k3s, not full Kubernetes. Use NixOS as the declarative host layer. Use Traefik as the Kubernetes ingress. Start with the Intel homelab machine and postpone Raspberry Pi migration until the Intel setup is stable. Run easy and low-risk services in k3s first, including Hermes if it has simple runtime requirements. Use Prometheus/Grafana for metrics and Wazuh for security monitoring. Run Wazuh agents directly on the Linux hosts. Run the Wazuh server stack outside k3s first, then move it into k3s later if Kubernetes practice is worth the added complexity.
