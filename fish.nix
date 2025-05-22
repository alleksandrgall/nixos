{pkgs, ...}: let
  localUser = import ./user.nix;
in {
  programs.fish = {
    enable = true;
    useBabelfish = true;
  };
  users.users.${localUser.name}.shell = pkgs.fish;
  home-manager.users.${localUser.name} = {
    programs.fish = {
      enable = true;
      shellAbbrs = {
        #s = "kitty +kitten ssh";
        #sr = "kitty +kitten ssh root@";
        ll = "ls -l";
        lla = "ls -la";
        nixos-update = "sudo nixos-rebuild switch";
      };
    };
  };
}
