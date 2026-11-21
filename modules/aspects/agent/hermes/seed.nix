_: {
  flake.modules.homeManager.agent-hermes =
    { config, lib, ... }:
    {
      home.activation.hermes-seed-files = lib.hm.dag.entryAfter [ "hermesAgentSetup" ] ''
        seed=${./seed}
        hermes_home="${config.home.homeDirectory}/.hermes"
        (cd "$seed" && find . -type f) | while read -r f; do
          [ -e "$hermes_home/$f" ] && continue
          mode=0644
          [ -x "$seed/$f" ] && mode=0755
          run install -D -m "$mode" "$seed/$f" "$hermes_home/$f"
        done
      '';
    };
}
