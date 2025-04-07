https://discourse.nixos.org/t/using-git-to-handle-and-manage-configuration-nix/38337/4

сделать симлинку с /etc/nixos/flake.nix на директорию с конфигом. после этого sudo nixos-rebuild --flake switch

либо просто sudo nixos-rebuild --flake /nixos switch
