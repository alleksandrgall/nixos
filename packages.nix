let
  localUser = import ./user.nix;
  localName = localUser.name;
in
{ pkgs, ... }:
{
  home-manager.users.${localName} = {
    xdg.configFile = 
      { "opencode/opencode.json".source = ./opencode/opencode.json;
        "opencode/AGENTS.md".source = ./opencode/AGENTS.md;
      };
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
      nodejs
      sops
      jq
      postgresql_16
      sox
      dig
      rclone
      elinks
      age
      grpcurl
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
