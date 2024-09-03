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
    nixosConfigurations.nixos = let
      localUser = import ./user.nix;
      localName = localUser.name;
    in
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
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
            environment.variables.EDITOR = "nvim";
            programs.nix-ld = {
              enable = true;
              package = pkgs.nix-ld-rs;
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

            nix.extraOptions = "experimental-features = nix-command flakes";
            nix.settings.trusted-users = ["root" "${localName}"];
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
