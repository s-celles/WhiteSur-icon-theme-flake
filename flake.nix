{
  description = "WhiteSur icon theme, packaged as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pinned upstream commit ; locally-applied patches in ./patches/
    # rebase on top.
    whitesur-icon-theme-src = {
      url = "github:vinceliuice/WhiteSur-icon-theme/bab5833b5cae200bccb786a2d3d6afa2201e7806";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, whitesur-icon-theme-src }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f system (import nixpkgs { inherit system; }));
    in
    {
      packages = forAllSystems (system: pkgs: {
        whitesur-icon-theme = pkgs.callPackage ./package.nix {
          src = whitesur-icon-theme-src;
          patchesDir = ./patches;
        };
        default = self.packages.${system}.whitesur-icon-theme;
      });

      # Convenience NixOS module : drops the icon theme into
      # environment.systemPackages so files land under
      # /run/current-system/sw/share/icons/{WhiteSur,WhiteSur-light,
      # WhiteSur-dark}/. Users still pick the variant via System
      # Settings → Icons or :
      #   plasma-apply-iconscheme WhiteSur-dark
      # The module installs every default variant ; it does not
      # enforce one.
      nixosModules.default = { pkgs, ... }: {
        environment.systemPackages = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.whitesur-icon-theme
        ];
      };
    };
}
