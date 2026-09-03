let
  localUser = import ./user.nix;
in
{
  home-manager.users.${localUser.name} =
    { config, ... }:
    {
      # Симлинк наружу от nix store: правки в ~/nixos/claude/CLAUDE.md
      # действуют сразу, без nixos-rebuild.
      home.file.".claude/CLAUDE.md".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/claude/CLAUDE.md";
    };
}
