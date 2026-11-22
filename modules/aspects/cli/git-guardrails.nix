{ lib, ... }:
let
  conventionalCommit = ''
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

  commitMsgRuntime = pkgs: [
    pkgs.gnugrep
    pkgs.gnused
  ];
in
{
  perSystem =
    { pkgs, ... }:
    let
      hook = pkgs.writeShellApplication {
        name = "git-conventional-commit";
        runtimeInputs = commitMsgRuntime pkgs;
        text = conventionalCommit;
      };
      long = "feat: " + lib.concatStrings (lib.genList (_: "x") 66);
      accepted = [
        "feat: add a thing"
        "fix(niri): keep focus"
        "refactor!: drop the old seam"
        "feat(binary-cache)!: sign with a new key"
        long
        "Merge branch 'topic'"
        "Revert \"feat: add a thing\""
        "fixup! feat: add a thing"
        "squash! feat: add a thing"
        "amend! feat: add a thing"
        "# a comment line\n\nchore: subject after comments"
      ];
      rejected = [
        "add a thing"
        "feat:no space"
        "feat: ends with a period."
        "${long}x"
        "feature: unknown type"
        "Feat: capitalised type"
        "feat(): empty scope"
        "feat:  "
        "feat: a literal \\c before a period."
      ];
      run = expected: message: ''
        printf '%s\n' ${lib.escapeShellArg message} > msg
        status=0
        ${lib.getExe hook} msg 2>/dev/null || status=$?
        if [ "$status" != ${expected} ]; then
          echo "expected exit ${expected}, got $status: "${lib.escapeShellArg message} >&2
          failed=1
        fi
      '';
    in
    {
      checks.git-conventional-commit = pkgs.runCommand "git-conventional-commit" { } ''
        failed=0
        ${lib.concatMapStrings (run "0") accepted}
        ${lib.concatMapStrings (run "1") rejected}
        [ "$failed" = 0 ] && touch $out
      '';
    };

  flake.modules.homeManager.git-guardrails =
    { pkgs, ... }:
    let

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
          text = conventionalCommit;
          args = [ ];
          runtimeInputs = commitMsgRuntime pkgs;
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
