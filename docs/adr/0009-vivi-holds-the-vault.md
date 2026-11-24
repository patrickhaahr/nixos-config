# vivi holds the vault

vivi, the Raspberry Pi 4, runs Vaultwarden and the DNS-over-HTTPS front for AdGuard, and nothing that runs agents. The password vault stays reachable while the larger hosts reboot, sleep or migrate, and no agent account can reach it.

- vivi trusts only ph's key; the Hermes host key is not authorized there and Hermes has no `Host vivi` entry, because passwordless sudo on vivi would hand an agent the vault.
- Both services sit under `*.vivi.haahr.me` like any homelab host (ADR 0003) while the old Raspberry Pi OS box still answers on `vault.haahr.me` and `dns.haahr.me`. Vaultwarden's domain is where passkeys and WebAuthn are bound, so the vault data moves to vivi together with the domain it was enrolled under.
- The DoH front logs nothing, because GET requests carry the DNS query in the URL, and accepts only private and tailnet addresses.
- vivi runs from an SD card, so Vaultwarden writes its consistent SQLite copy to `/var/backup/vaultwarden` and that directory, not the live database, is what gets backed up off the host.
