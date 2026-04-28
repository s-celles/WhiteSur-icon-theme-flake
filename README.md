# WhiteSur-icon-theme-flake

Nix flake packaging of [vinceliuice/WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme) — the macOS-like icon theme (default, light, dark).

Sibling of [`s-celles/WhiteSur-kde-flake`](https://github.com/s-celles/WhiteSur-kde-flake) and [`s-celles/WhiteSur-cursors-flake`](https://github.com/s-celles/WhiteSur-cursors-flake) ; same scaffolding pattern.

## Variants installed by default

The build runs upstream's `install.sh` without flags. That ships :

- `WhiteSur` (default blue accent)
- `WhiteSur-light`
- `WhiteSur-dark`

Other accent variants (`-purple`, `-pink`, `-red`, `-orange`, `-yellow`, `-green`, `-grey`, `-nord`) are NOT shipped by default — upstream gates them behind `--theme` flags. If you want them, drop a patch in `./patches/` that pre-populates `themes=("${THEME_VARIANTS[@]}")` before the `install_theme` call.

## Usage

```nix
{
  inputs.whitesur-icon-theme.url = "github:s-celles/WhiteSur-icon-theme-flake";

  outputs = { self, nixpkgs, whitesur-icon-theme, ... }: {
    nixosConfigurations.WULFENIX = nixpkgs.lib.nixosSystem {
      modules = [
        whitesur-icon-theme.nixosModules.default
        # …rest of your config
      ];
    };
  };
}
```

After `nixos-rebuild switch`, files land under `/run/current-system/sw/share/icons/WhiteSur{,-light,-dark}/`. Activate via System Settings → Icons, or :

```bash
plasma-apply-iconscheme WhiteSur-dark
```

## Adding a patch

Drop `*.patch` files in `./patches/` ; the build picks them up alphabetically. See [`s-celles/WhiteSur-kde-flake`](https://github.com/s-celles/WhiteSur-kde-flake/blob/main/patches/README.md) for the format.

## License

Theme content : GPL-3.0-or-later (upstream).
