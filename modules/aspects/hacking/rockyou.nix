_: {
  flake.modules.homeManager."hacking-rockyou" =
    { pkgs, ... }:
    let
      seclistsRoot = "${pkgs.seclists}/share/wordlists/seclists";
      rockyou =
        pkgs.runCommandLocal "rockyou.txt"
          {
            nativeBuildInputs = [
              pkgs.gnutar
              pkgs.gzip
            ];
          }
          ''
            tar -xOzf ${seclistsRoot}/Passwords/Leaked-Databases/rockyou.txt.tar.gz > "$out"
          '';
    in
    {
      home.file."hacking/wordlists/rockyou.txt".source = rockyou;
      home.file."hacking/wordlists/seclists".source = seclistsRoot;
    };
}
