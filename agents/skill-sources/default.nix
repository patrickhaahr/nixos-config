{
  inputs,
  lib,
  pkgs,
}:
let

  lock = lib.importJSON ./sources.lock.json;

  fetchSkills =
    slug: skills:
    let
      parts = lib.splitString "/" slug;
      paths = builtins.attrValues skills;
      sparse = lib.optionals (!lib.elem "" paths) paths;
      pin = lock.${slug} or { };
      src = pkgs.fetchFromGitHub {
        owner = lib.elemAt parts 0;
        repo = lib.elemAt parts 1;
        inherit (pin) rev hash;

        forceFetchGit = true;
        sparseCheckout = sparse;
      };
    in

    assert lib.assertMsg (
      pin.paths or null == sparse
    ) "skill-sources: lock for ${slug} is stale; run `just update-skills ${slug}`";
    lib.mapAttrs (_: path: if path == "" then src else src + "/${path}") skills;

  fetchAll = sources: lib.foldl' lib.mergeAttrs { } (lib.mapAttrsToList fetchSkills sources);

  skills = fetchAll (import ./sources.nix) // {
    openhome = inputs.openhome + "/skills/openhome";
  };
  overrides = import ./overrides.nix;
  unknown = lib.subtractLists (builtins.attrNames skills) (builtins.attrNames overrides);

  patchSkill =
    pkgs.writers.writePython3 "skill-patch"
      {
        libraries = [ pkgs.python3Packages.pyyaml ];
      }
      ''
        import json
        import pathlib
        import sys

        import yaml

        path = pathlib.Path(sys.argv[1])
        _, front, body = path.read_text().split("---\n", 2)
        meta = yaml.safe_load(front)
        meta.update(json.loads(sys.argv[2]))
        for old, new in json.loads(sys.argv[3]).items():
            if body.count(old) != 1:
                sys.exit(f"{path}: replace target must occur once: {old!r}")
            body = body.replace(old, new)
        dumped = yaml.safe_dump(
            meta, sort_keys=False, allow_unicode=True, width=1000
        )
        path.write_text("---\n" + dumped + "---\n" + body)
      '';

  patch =
    name: src: override:
    pkgs.runCommand "skill-${name}" { } ''
      cp -rL --no-preserve=mode ${src} $out
      ${patchSkill} $out/SKILL.md \
        ${lib.escapeShellArg (builtins.toJSON (removeAttrs override [ "replace" ]))} \
        ${lib.escapeShellArg (builtins.toJSON (override.replace or { }))}
    '';
in
assert lib.assertMsg (unknown == [ ]) "skill overrides name missing skills: ${toString unknown}";
{
  skills = lib.mapAttrs (
    name: src: if overrides ? ${name} then patch name src overrides.${name} else src
  ) skills;
  bundles = lib.mapAttrs (
    name: src:
    pkgs.runCommand "skill-bundle-${name}" { } ''
      cp -rL --no-preserve=mode ${src} $out
      for skill in $out/*/SKILL.md; do
        ${patchSkill} "$skill" '{}' '{}'
      done
    ''
  ) (fetchAll (import ./bundles.nix));
}
