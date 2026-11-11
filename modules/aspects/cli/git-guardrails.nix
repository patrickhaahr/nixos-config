_: {
  flake.modules.homeManager.git-guardrails =
    { pkgs, ... }:
    let
      # Plain bash with no store paths, so the Windows mirror can run the same text under Git Bash.
      hooks = {
        file-size-guard = {
          event = "pre-commit";
          text = builtins.readFile ../../../agents/skills/setup-repo/templates/common/tools/git-file-size-guard;
          args = [ "--global" ];
          runtimeInputs = [
            pkgs.git
            pkgs.gnugrep
            pkgs.coreutils
          ];
        };
        conventional-commit = {
          event = "commit-msg";
          text = ''
            subject=$(grep -v '^#' "$1" | sed -n '/[^[:space:]]/{p;q}')
            case $subject in
              "Merge "* | "Revert "* | "fixup! "* | "squash! "* | "amend! "*) exit 0 ;;
            esac

            types='build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test'
            if [[ $subject =~ ^($types)(\([^()]+\))?!?:\ [^[:space:]] && ''${#subject} -le 72 && $subject != *. ]]; then
              exit 0
            fi

            cat >&2 <<EOF
            Commit blocked: the subject is not a Conventional Commit.
              got:  $subject
              want: <type>[(scope)][!]: <description>   (at most 72 characters, no trailing period)
              type: ''${types//|/, }
            Prefer a one-line message that says what changed for the user;
            add a body only when the why is not obvious from the subject.
            EOF
            exit 1
          '';
          args = [ ];
          runtimeInputs = [
            pkgs.gnugrep
            pkgs.gnused
          ];
        };
      };

      wrap =
        name: hook:
        pkgs.writeShellApplication {
          name = "git-${name}";
          inherit (hook) runtimeInputs text;
        };
    in
    {
      lib.git.guardrailHooks = hooks;

      programs.git.ignores = [
        ".env"
        ".env.*"
        "!.env.example"
        "!.env.sample"
        "!.env.template"
        ".dev.vars"
        ".dev.vars.*"
        ".local_secrets"
        "settings.local.json"
        "local.settings.json"
        "secrets.json"
      ];

      programs.git.settings.hook = builtins.mapAttrs (name: hook: {
        inherit (hook) event;
        command = toString ([ "${wrap name hook}/bin/git-${name}" ] ++ hook.args);
      }) hooks;
    };
}
