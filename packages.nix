let
  localUser = import ./user.nix;
  localName = localUser.name;
in
{ pkgs, ... }:
{
  home-manager.users.${localName} = {
    programs.starship = {
      enable = true;
      enableTransience = true;
    };
    programs.fzf.enable = true;
    home.packages = with pkgs; [
      wget
      nil
      nix-output-monitor
      nvd
      nixfmt
      sops
      jq
      postgresql_16
      direnv
      htop
      claude-code
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
