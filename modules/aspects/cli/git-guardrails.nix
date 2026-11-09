_: {
  flake.modules.homeManager.git-guardrails =
    { pkgs, ... }:
    let
      fileSizeGuard = pkgs.writeShellApplication {
        name = "git-file-size-guard";
        runtimeInputs = [
          pkgs.git
          pkgs.gnugrep
          pkgs.coreutils
        ];
        text = ''
          exec ${pkgs.bash}/bin/bash ${../../../agents/skills/setup-repo/templates/common/tools/git-file-size-guard} "$@"
        '';
      };

      conventionalCommit = pkgs.writeShellApplication {
        name = "git-conventional-commit";
        runtimeInputs = [
          pkgs.gnugrep
          pkgs.gnused
        ];
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
      };
    in
    {
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
      ];

      programs.git.settings.hook = {
        file-size-guard = {
          command = "${fileSizeGuard}/bin/git-file-size-guard --global";
          event = "pre-commit";
        };
        conventional-commit = {
          command = "${conventionalCommit}/bin/git-conventional-commit";
          event = "commit-msg";
        };
      };
    };
}
