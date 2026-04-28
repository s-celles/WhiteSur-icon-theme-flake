{ stdenvNoCC, lib, bash, coreutils, gnused, gtk3, src, patchesDir }:

let
  patchFiles = builtins.attrNames (
    lib.filterAttrs
      (name: type: type == "regular" && lib.hasSuffix ".patch" name)
      (builtins.readDir patchesDir)
  );
in
stdenvNoCC.mkDerivation {
  pname = "whitesur-icon-theme";
  version = "bab5833";

  inherit src;
  patches = map (name: patchesDir + "/${name}") patchFiles;

  nativeBuildInputs = [
    bash
    coreutils
    gnused
    # install.sh runs `gtk-update-icon-cache` at the end of each
    # variant install to bake the icon-theme.cache file ; without it
    # GTK apps fall back to slow disk lookups. Provided by gtk3.
    gtk3
  ];

  dontConfigure = true;
  dontBuild = true;
  # Upstream's links/*.sh scripts wire up cross-references between icon
  # variants (default ↔ light ↔ dark, plus the per-app symlinks for
  # apps that share a glyph). Some of those links point at variants we
  # don't install by default (e.g. -purple, -nord, the bold/alternative
  # icon sets), which makes nix's `noBrokenSymlinks` fixup-phase check
  # fail with ~72 dangling targets. Skip the check : KDE / GTK lookups
  # for the variants we ship still resolve fine ; only the unused
  # cross-variant links are dangling, which is harmless.
  dontCheckForBrokenSymlinks = true;

  installPhase = ''
    runHook preInstall

    # Run upstream's install.sh in the sandbox with HOME pointing at
    # $PWD/fake-home so its non-root branch puts the generated icon
    # tree under $HOME/.local/share/icons/. Default behaviour
    # (without flags) installs three variants : WhiteSur (default
    # blue), WhiteSur-light, WhiteSur-dark — see the COLOR_VARIANTS
    # array in install.sh.
    #
    # Why we run the script rather than copy by hand : install_theme
    # composes the icon tree from src/ + (optionally) bold/, alternative/,
    # plasma/ subdirs, plus sed-substitutes the theme name in
    # index.theme files. Reproducing the composition + substitution
    # logic in shell would drift every time upstream tweaks it.
    export HOME=$PWD/fake-home
    mkdir -p "$HOME"
    # `name` is set by stdenv to "$pname-$version" in the build env ;
    # install.sh reads ''${name:-''${THEME_NAME}} and would use the
    # derivation name as the theme name. Unset so the script falls
    # back to its hardcoded THEME_NAME=WhiteSur.
    unset name
    bash install.sh

    # Relocate to system path under $out/share/icons.
    mkdir -p $out/share
    if [ -d "$HOME/.local/share/icons" ]; then
      mv "$HOME/.local/share/icons" $out/share/icons
    fi

    runHook postInstall
  '';

  meta = with lib; {
    description = "WhiteSur (macOS-like) icon theme — default + light + dark variants";
    homepage = "https://github.com/vinceliuice/WhiteSur-icon-theme";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
