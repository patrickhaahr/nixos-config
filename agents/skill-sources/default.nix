{
  inputs,
  lib,
  pkgs,
}:
let
  providers = [
    #(import ./agent-browser.nix { inherit inputs; })
    (import ./apollo.nix { inherit inputs; })
    (import ./better-auth.nix { inherit inputs; })
    (import ./cloudflare.nix { inherit inputs; })
    (import ./diagram-design.nix { inherit inputs; })
    (import ./dmmulroy.nix { inherit inputs; })
    (import ./emilkowalski.nix { inherit inputs; })
    (import ./frontend-slides.nix { inherit inputs; })
    (import ./jakubkrehel.nix { inherit inputs; })
    (import ./juliobsz.nix { inherit inputs; })
    (import ./kitlangton.nix { inherit inputs; })
    (import ./leonxlnx.nix { inherit inputs; })
    (import ./mattpocock.nix { inherit inputs; })
    (import ./marketing.nix { inherit inputs; })
    (import ./openclaw.nix { inherit inputs; })
    (import ./openhome.nix { inherit inputs; })
    (import ./shadcn.nix { inherit inputs; })
    #(import ./typesafe-ai.nix { inherit inputs; })
    (import ./vercel.nix { inherit inputs; })
  ];
  skills = lib.foldl' lib.mergeAttrs { } providers;
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
