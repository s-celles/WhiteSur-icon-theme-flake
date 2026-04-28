# Patches

Drop `*.patch` files here ; the build applies them in alphabetic order.
See [`s-celles/WhiteSur-kde-flake/patches/README.md`](https://github.com/s-celles/WhiteSur-kde-flake/blob/main/patches/README.md) for the format and conventions.

## Pre-populating accent variants

By default we ship `WhiteSur`, `WhiteSur-light`, `WhiteSur-dark`. If you want all accent variants (`-purple`, `-pink`, `-red`, `-orange`, `-yellow`, `-green`, `-grey`, `-nord`), drop a patch on `install.sh` that turns

```bash
if [[ "${#themes[@]}" -eq 0 ]]; then
  themes=("${THEME_VARIANTS[0]}")
fi
```

into

```bash
if [[ "${#themes[@]}" -eq 0 ]]; then
  themes=("${THEME_VARIANTS[@]}")
fi
```

This nearly triples the build size (each accent variant duplicates the symbolic icon set). Worth it only if you actively cycle through accent colours.
