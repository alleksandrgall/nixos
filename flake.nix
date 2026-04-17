{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    # Более быстрые патчи никса
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    home-manager,
    determinate,
    ...
  }: {
    nixosConfigurations.nixos = let
      localUser = import ./user.nix;
      localName = localUser.name;
    in
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          determinate.nixosModules.default
          nixos-wsl.nixosModules.default
          ./packages.nix
          ./git.nix
          # ./zsh.nix
          ./fish.nix
          home-manager.nixosModules.home-manager
          ({
            config,
            pkgs,
            ...
          }: {
            system.stateVersion = "24.05";
            wsl.enable = true;
            environment.sessionVariables = {
              NH_FLAKE = "/home/ivan/nixos";
              FLAKE = "/home/ivan/nixos";
            };
            # environment.etc."nix/nix.conf".target = "nix/nix.custom.conf";
            environment.variables = {
              EDITOR = "nvim";
              FLAKE = "/home/ivan/nixos";
              NH_FLAKE = "/home/ivan/nixos";
            };
            # Автоматически делает свитч, удаляет всё что старше 30 дней не трогалось, сохраняет 5 последних свитчей
            programs.nh = {
              enable = true;
              clean = {
                enable = true;
                extraArgs = "--keep-since 30d --keep 5";
              };
            };
            programs.nix-ld = {
              enable = true;
              package = pkgs.nix-ld;
              # https://github.com/Mic92/dotfiles/blob/main/nixos/modules/nix-ld.nix
              libraries = with pkgs;
                [
                  # Mic92's list
                  alsa-lib
                  at-spi2-atk
                  at-spi2-core
                  atk
                  cairo
                  cups
                  curl
                  dbus
                  expat
                  fontconfig
                  freetype
                  fuse3
                  gdk-pixbuf
                  glib
                  gtk3
                  icu
                  libGL
                  libappindicator-gtk3
                  libdrm
                  libglvnd
                  libnotify
                  libpulseaudio
                  libunwind
                  libusb1
                  libuuid
                  libxkbcommon
                  mesa #non-noveau NVidia doesn't use mesa (???)
                  nspr
                  nss
                  openssl
                  pango
                  pipewire
                  stdenv.cc.cc
                  systemd
                  vulkan-loader
                  xorg.libX11
                  xorg.libXScrnSaver
                  xorg.libXcomposite
                  xorg.libXcursor
                  xorg.libXdamage
                  xorg.libXext
                  xorg.libXfixes
                  xorg.libXi
                  xorg.libXrandr
                  xorg.libXrender
                  xorg.libXtst
                  xorg.libxcb
                  xorg.libxkbfile
                  xorg.libxshmfence
                  zlib
                ]
                ++ [
                  # Diamondy4's list
                  gsettings-desktop-schemas
                ];
            };

            # nix.extraOptions = "experimental-features = nix-command flakes";
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
              "cgroups"
              "parallel-eval"
            ];
            nix.settings.use-xdg-base-directories = true;
            nix.settings.trusted-users = ["root" "@wheel" "@sudo" "${localName}"];
            nix.settings.lazy-trees = true;
            nix.settings.eval-cores = 0;
            nix.settings = {
              extra-substituters = [
                "https://cache.nixos.org/"
                "https://nix-community.cachix.org"
                "https://cache.getshop.tv"
                "https://numtide.cachix.org"
                "https://cuda-maintainers.cachix.org"
              ];
              extra-trusted-substituters = [
                "https://cache.nixos.org/"
                "https://cache.getshop.tv"
                "https://nix-community.cachix.org"
                "https://numtide.cachix.org"
                "https://cuda-maintainers.cachix.org"
              ];
              extra-trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
                "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
                "cache.getshop.tv:GxVoHz2YFD0MOlisz0URi0qytu21TP88cnYkZ/3dfyA="
              ];
            };
            wsl.defaultUser = localName;
            wsl.wslConf.network.generateResolvConf = false;
            networking.nameservers = ["1.1.1.1"];
            users.defaultUserShell = pkgs.fish;
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
