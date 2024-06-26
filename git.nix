let
  localUser = import ./user.nix;
in {
  home-manager.users.${localUser.name}.programs.git = {
    enable = true;
    userEmail = localUser.email;
    userName = localUser.description;
  };
}
