{ pkgs, ... }:
{
  home-manager.users.ivan.home.packages = with pkgs; [
                wget
                nil
                alejandra
                vim
                jq
];
}
