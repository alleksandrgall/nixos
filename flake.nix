{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    home-manager,
  }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-wsl.nixosModules.default
        ./packages.nix
        ./git.nix
        home-manager.nixosModules.home-manager
        ({
          config,
          pkgs,
          ...
        }: {
          system.stateVersion = "24.05";
          wsl.enable = true;
          nix.extraOptions = "experimental-features = nix-command flakes";
          wsl.defaultUser = "ivan";
          #users.nix
          users.users.ivan = {
            isNormalUser = true;
            home = "/home/ivan";
            description = "Ivan Iablochkin";
            extraGroups = ["wheel"];
            group = "ivan"; # Добавляем основную группу
          };

          users.groups.ivan = {}; # Создаем группу ivan

          #home.nix
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.ivan.home.stateVersion = "24.05";
          };

          ### КРИНЖ
          systemd.user.paths."vscode-remote-workaround" = {
            wantedBy = ["default.target"];
            pathConfig.PathChanged = "%h/.vscode-server/bin";
          };
          systemd.user.services."vscode-remote-workaround" = {
            script = ''
              for i in ~/.vscode-server/bin/*; do
                echo "Fixing vscode-server in $i..."
                ln -sf ${pkgs.nodejs}/bin/node $i/node
              done
            '';
          };
          ###
        })
      ];
    };
  };
}