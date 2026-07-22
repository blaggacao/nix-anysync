{
  config,
  lib,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.services.anytype-cli;
  user = "anytype";
  group = "anytype";

  common = import ./common.nix {
    inherit pkgs;
    inherit lib;
  };

  # anytype-cli uses hardcoded ports: 31010 (GRPC), 31011 (GRPC-Web), 31012 (API)

  networkConfigPath =
    if cfg.networkConfigPath != null then
      cfg.networkConfigPath
    else if cfg.networkConfig != null then
      pkgs.writeText "anytype-network.yml" (lib.generators.toYAML cfg.networkConfig)
    else
      null;

in
{
  options.services.anytype-cli =
    with types;
    {
      enable = mkEnableOption "anytype-cli";

      accountName = mkOption {
        type = str;
        default = "anytype-bot";
        description = "Account name for the anytype-cli bot account";
      };

      networkConfig = mkOption {
        type = nullOr attrs;
        default = null;
        description = ''
          anytype-cli network configuration.
          Reference: https://github.com/anyproto/any-sync-dockercompose
        '';
      };

      networkConfigPath = mkOption {
        type = nullOr path;
        default = null;
        description = ''
          Path to anytype-cli network config file (network.yml).
          Reference: https://github.com/anyproto/any-sync-dockercompose
        '';
      };

      bootstrapOnFirstRun = mkOption {
        type = bool;
        default = true;
        description = "Create bot account on first run if it doesn't exist";
      };
    }
    // (common.userGroupOptions user group);

  config = mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.networkConfigPath != null || cfg.networkConfig != null;
          message = "Either networkConfig or networkConfigPath must be set for anytype-cli";
        }
      ];

      users.users.${user} = {
        isSystemUser = true;
        group = group;
        createHome = false;
        home = "/var/lib/any-sync/anytype";
      };

      users.groups.${group} = { };

      systemd.services.anytype-cli-bootstrap = mkIf cfg.bootstrapOnFirstRun {
        description = "Anytype CLI bootstrap - create bot account on first run";
        after = [ "network.target" "any-sync-coordinator.service" ];
        wants = [ "any-sync-coordinator.service" ];
        wantedBy = [ "multi-user.target" ];

        path = [ pkgs.anytype-cli ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = user;
          Group = group;
          WorkingDirectory = "/var/lib/any-sync/anytype";
          StateDirectory = "any-sync/anytype";
        };

        script = ''
          if [ ! -f config.json ]; then
            echo 'Creating bot account...';
            ${pkgs.anytype-cli}/bin/anytype-cli serve &
            SERVER_PID=$!;
            sleep 2;
            ${pkgs.anytype-cli}/bin/anytype-cli auth create ${cfg.accountName} --network-config ${networkConfigPath} || true;
            echo 'Waiting for account initialization...';
            sleep 2;
            kill $SERVER_PID 2>/dev/null || true;
            wait $SERVER_PID 2>/dev/null || true;
          else
            echo 'Bot account already exists, skipping bootstrap';
          fi;
        '';
      };

      systemd.services.anytype-cli = {
        after = [ "network.target" "anytype-cli-bootstrap.service" ];
        wants = [ "any-sync-coordinator.service" ];
        wantedBy = [ "multi-user.target" ];

        path = [ pkgs.anytype-cli ];

        unitConfig = {
          StartLimitBurst = 3;
        };

        serviceConfig = {
          ExecStart = "${pkgs.anytype-cli}/bin/anytype-cli serve";
          User = user;
          Group = group;
          Restart = "on-failure";
          RestartSec = "5s";
          StateDirectory = "any-sync/anytype";
          WorkingDirectory = "/var/lib/any-sync/anytype";
          PrivateTmp = true;
          ProtectSystem = "full";
          NoNewPrivileges = true;
          LimitNOFILE = 65536;
        };
      };
    })

    (common.addUserAndGroup cfg user group)
  ];
}
