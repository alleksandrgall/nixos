{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    vscode-server,
    home-manager,
  }: {
    nixosConfigurations.nixos = let
      localUser = import ./user.nix;
      localName = localUser.name;
    in
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          vscode-server.nixosModules.default
          ./packages.nix
          ./git.nix
          ./zsh.nix
          home-manager.nixosModules.home-manager
          ({
            config,
            pkgs,
            ...
          }: {
            system.stateVersion = "24.05";
            wsl.enable = true;
            environment.variables.EDITOR = "neovim";
            programs.nix-ld.enable = true;
            services.vscode-server.enable = true;
            nix.extraOptions = "experimental-features = nix-command flakes";
            nix.trustedUsers = ["root" "${localName}"];
            wsl.defaultUser = localName;
            wsl.nativeSystemd = true;
            users.defaultUserShell = pkgs.zsh;
            users.users.${localName} = {
              inherit (localUser) home description;
              isNormalUser = true;
              extraGroups = ["wheel" "docker"];
              group = localName;
            };

            users.groups.${localName} = {};

            #home.nix
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${localName}.home.stateVersion = "24.05";
            };
          })
        ];
      };
  };
}
