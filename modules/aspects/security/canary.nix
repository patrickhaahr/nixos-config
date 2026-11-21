{ inputs, ... }:
{
  flake.modules.nixos.canary =
    { config, lib, ... }:
    let
      cfg = config.canary;
      account = config.users.users.${cfg.user};
      secret = name: config.sops.placeholder."canary_aws_${name}";
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      options.canary = {
        user = lib.mkOption {
          type = lib.types.str;
          description = "User whose ~/.aws/credentials holds the canary key.";
        };
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "Host sops file with canary_aws_access_key_id and canary_aws_secret_access_key.";
        };
      };

      config = {
        sops = {
          age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
          secrets = lib.genAttrs [ "canary_aws_access_key_id" "canary_aws_secret_access_key" ] (_: {
            inherit (cfg) sopsFile;
          });
          templates."canary-aws-credentials" = {
            path = "${account.home}/.aws/credentials";
            owner = cfg.user;
            content = ''
              [default]
              aws_access_key_id = ${secret "access_key_id"}
              aws_secret_access_key = ${secret "secret_access_key"}
            '';
          };
        };

        systemd.tmpfiles.settings.canary."${account.home}/.aws".d = {
          inherit (cfg) user;
          inherit (account) group;
          mode = "0700";
        };
      };
    };
}
