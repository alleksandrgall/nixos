{pkgs, ...}: let
  localUser = import ./user.nix;
in {
  programs.zsh.enable = true;
  users.users.${localUser.name}.shell = pkgs.zsh;
  home-manager.users.${localUser.name} = {
    programs.zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        lla = "ls -la";
        nixos-update = "sudo nixos-rebuild switch";
      };
      zplug = {
        enable = true;
        plugins = [
          {name = "zsh-users/zsh-autosuggestions";}
          {name = "zsh-users/zsh-syntax-highlighting";}
          {name = "MichaelAquilina/zsh-you-should-use";}
          {name = "fdellwing/zsh-bat";}
        ];
      };
      oh-my-zsh = {
        enable = true;
        plugins = ["git"];
        theme = "robbyrussell";
      };
    };
  };
}
