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

  # Replace upstream's Apple-logo `start-here.svg` (the icon-theme
  # kicker icon used by org.kde.plasma.kickoff and friends) with the
  # NixOS snowflake from ./assets/.
  #
  # Two variants of the snowflake (mirrors WhiteSur-kde-flake) :
  #   - start-here-nixos.svg       — solid dark fill, for light themes
  #   - start-here-nixos-white.svg — solid white fill, for dark themes
  # We can't use a single `currentColor` SVG because KDE doesn't
  # inherit a sensible text colour into kicker icons across panel
  # themes.
  #
  # postPatch overwrites src/places/{16,22,24,scalable}/start-here.svg
  # plus src/places/scalable/start-here-symbolic.svg with the
  # dark-fill copy ; install.sh's install_theme then generates
  # WhiteSur, WhiteSur-light and WhiteSur-dark from the patched src/,
  # so all three initially get the dark-fill snowflake.
  #
  # postInstall then specifically overwrites WhiteSur-dark/places/*
  # with the white-fill copy, so dark-mode Dolphin / Kickoff render
  # the snowflake as white-on-dark instead of dark-on-dark.
  #
  # The NixOS SVG's viewBox (0 0 501.56 501.56) auto-scales cleanly
  # down to 16 px ; same content fits every slot without per-size
  # hand-tuning.
  postPatch = ''
    for size in 16 22 24 scalable; do
      cp ${./assets/start-here-nixos.svg} src/places/$size/start-here.svg
    done
    cp ${./assets/start-here-nixos.svg} src/places/scalable/start-here-symbolic.svg
  '';

  postInstall = ''
    if [ -d $out/share/icons/WhiteSur-dark/places ]; then
      for size in 16 22 24 scalable; do
        if [ -f $out/share/icons/WhiteSur-dark/places/$size/start-here.svg ]; then
          cp ${./assets/start-here-nixos-white.svg} \
            $out/share/icons/WhiteSur-dark/places/$size/start-here.svg
        fi
      done
      if [ -f $out/share/icons/WhiteSur-dark/places/scalable/start-here-symbolic.svg ]; then
        cp ${./assets/start-here-nixos-white.svg} \
          $out/share/icons/WhiteSur-dark/places/scalable/start-here-symbolic.svg
      fi
    fi
  '';

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
