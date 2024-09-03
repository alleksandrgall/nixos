let
  localUser = import ./user.nix;
  localName = localUser.name;
in
  {pkgs, ...}: {
    home-manager.users.${localName} = {
      home.packages = with pkgs; [
        wget
        nil
        alejandra
        neovim
        sops
        jq
        postgresql_16
        direnv
        htop
      ];
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      programs.neovim = {
        enable = true;
      };
    };
  }
