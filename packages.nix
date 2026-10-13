let
  localUser = import ./user.nix;
  localName = localUser.name;
in
{ pkgs, inputs, ... }:
{
  home-manager.users.${localName} = {
    xdg.configFile."opencode/opencode.json".source =
      ./opencode/opencode.json;

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
      inputs.opencode-flake.packages.${pkgs.system}.default
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
