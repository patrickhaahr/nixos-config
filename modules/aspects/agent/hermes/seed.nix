# A checkpoint of Hermes state written by hand or by the agents themselves:
# skills, their scripts, and the Echo's role (memories/WORKING.md). Seeded, not
# owned: a file is copied only where ~/.hermes lacks it, because the curator and
# skill_manage keep rewriting these. A fresh host gets them back; a live edit
# survives every switch. Refresh the checkpoint by copying the files back here.
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
