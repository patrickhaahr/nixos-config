# Hermes Gadget: voice devices (the OnePlus 8T robot head) connect to the
# gateway's gadget platform over a WebSocket on port 8765.
# https://github.com/Adolanium/hermes-gadget-sdk
#
# The Android Live implementation is on patrickhaahr/hermes-gadget-sdk,
# branch android/client. The gateway loads a plain copy at ~/.hermes/plugins/gadget;
# deploy plugin/*.py there and restart hermes-agent after host-code changes.
# The Nix-packaged `hermes plugins install` currently fails. Deployment details
# are in AGENTS.md; approved devices and credentials stay in HERMES_HOME.
{ self, ... }:
let
  port = 8765;
in
{
  flake.modules = {
    homeManager.agent-hermes-gadget =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        # Only the shared default profile serves gadgets: the adapter binds its
        # own port, so a named profile enabling it would collide.
        services.hermes-agent.settings.platforms.gadget = {
          enabled = true;
          extra = {
            host = "0.0.0.0";
            inherit port;
            path = "/gadget";
            speak_replies = true;
            auto_home = true;
            unauthorized_dm_behavior = "pair";
            # Paired phones may start subscription GPT-Live calls (Start call or
            # a local wake in the Android client's selected Live voice mode). The gateway runs the talk-desktop plugin's
            # call broker itself, on this host's Codex login.
            live_calls = true;
          };
        };

        # plugins.enabled is not managed (a managed list would replace the
        # runtime-enabled plugins), so add gadget to the shared config only,
        # the same way talk-desktop is enabled.
        home.activation.hermes-gadget-plugin = lib.hm.dag.entryAfter [ "hermesAgentSetup" ] ''
          route_config="${config.home.homeDirectory}/.hermes/config.yaml"
          if [ -f "$route_config" ] && ! ${pkgs.gnugrep}/bin/grep -q '^  - gadget$' "$route_config"; then
            ${pkgs.gnugrep}/bin/grep -q '^plugins:' "$route_config" ||
              printf '\nplugins:\n  enabled:\n  - gadget\n' >> "$route_config"
            ${pkgs.perl}/bin/perl -0pi -e 's#^(plugins:\n  enabled:)\n(  - (?!gadget))#$1\n  - gadget\n$2#m; s#(plugins:\n  enabled:) \[\]$#$1\n  - gadget#m' "$route_config"
          fi
        '';
      };

    # Devices reach the gateway from the home LAN (the phone has no Tailscale)
    # and over Tailscale. Pairing and per-device HMAC keys gate access.
    nixos.agent-hermes-gadget = {
      networking.firewall.interfaces = {
        "enp2s0".allowedTCPPorts = [ port ];
        "tailscale0".allowedTCPPorts = [ port ];
      };
    };

    nixos.agent-hermes-host.imports = [ self.modules.nixos.agent-hermes-gadget ];
  };
}
