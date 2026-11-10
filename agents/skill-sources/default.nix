{
  inputs,
  lib,
  pkgs,
}:
let
  # Skills are sparse-fetched from pinned commits instead of flake inputs:
  # a flake input downloads the whole repo on every `nix flake update`.
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
        # The hash comes from nix-prefetch-git, so never fall back to fetchzip.
        forceFetchGit = true;
        sparseCheckout = sparse;
      };
    in
    # The hash covers exactly the locked paths; fail early instead of on a hash mismatch.
    assert lib.assertMsg (
      pin.paths or null == sparse
    ) "skill-sources: lock for ${slug} is stale; run `just update-skills ${slug}`";
    lib.mapAttrs (_: path: if path == "" then src else src + "/${path}") skills;

  skills = lib.foldl' lib.mergeAttrs { } (lib.mapAttrsToList fetchSkills (import ./sources.nix)) // {
    openhome = inputs.openhome + "/skills/openhome";
  };
  overrides = import ./overrides.nix;
  unknown = lib.subtractLists (builtins.attrNames skills) (builtins.attrNames overrides);

  patchFrontmatter =
    pkgs.writers.writePython3 "skill-patch-frontmatter"
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
        dumped = yaml.safe_dump(
            meta, sort_keys=False, allow_unicode=True, width=1000
        )
        path.write_text("---\n" + dumped + "---\n" + body)
      '';

  patch =
    name: src: fields:
    pkgs.runCommand "skill-${name}" { } ''
      cp -rL --no-preserve=mode ${src} $out
      ${patchFrontmatter} $out/SKILL.md ${lib.escapeShellArg (builtins.toJSON fields)}
    '';
in
assert lib.assertMsg (unknown == [ ]) "skill overrides name missing skills: ${toString unknown}";
lib.mapAttrs (
  name: src: if overrides ? ${name} then patch name src overrides.${name} else src
) skills
