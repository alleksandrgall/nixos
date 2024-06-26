{pkgs, ...}: let
  localUser = import ./user.nix;
in {
  programs.zsh.enable = true;
  users.users.${localUser.name}.shell = pkgs.zsh;
  home-manager.users.${localUser.name} = {
    programs.zsh = {
      enable = true;
      shellAliases = {
        ga = "git add";
        gc = "git commit -m";
        gp = "git push";
        nixos-update = "sudo nixos-rebuild switch";
      };
      zplug = {
        enable = true;
        plugins = [
          {name = "zsh-users/zsh-autosuggestions";}
          {name = "zsh-users/zsh-syntax-highlighting";}
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
