{
  perSystem =
    { pkgs, ... }:
    let
      pname = "eden";
      version = "0.2.1";

      src = pkgs.fetchurl {
        url = "https://stable.eden-emu.dev/v${version}/Eden-Linux-v${version}-rog-ally-clang-pgo.AppImage";
        hash = "sha256-VDmBde8K5dfepQd8gGA3OqFsrUBg2xrKP42n6dJ5UQE=";
      };

      rawAppImage = pkgs.stdenv.mkDerivation {
        name = "${pname}-raw-${version}";
        inherit src;
        dontUnpack = true;
        dontStrip = true;
        dontPatchELF = true;
        installPhase = ''
          mkdir -p $out/bin
          cp $src $out/bin/${pname}-appimage
          chmod +x $out/bin/${pname}-appimage
        '';
      };

      launchScript = pkgs.writeShellScript "${pname}-launch" ''
        icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"
        if [ ! -f "$icon_dir/${pname}.png" ]; then
          tmpdir=$(mktemp -d)
          (
            cd "$tmpdir"
            ${rawAppImage}/bin/${pname}-appimage --appimage-extract '.DirIcon' 2>/dev/null \
              || ${rawAppImage}/bin/${pname}-appimage --appimage-extract '*.png' 2>/dev/null \
              || true
          )
          icon=$(find "$tmpdir/squashfs-root" \( -name '.DirIcon' -o -name '*.png' \) 2>/dev/null | sort | head -1)
          if [ -n "$icon" ]; then
            mkdir -p "$icon_dir"
            cp "$icon" "$icon_dir/${pname}.png"
          fi
          rm -rf "$tmpdir"
        fi
        exec ${rawAppImage}/bin/${pname}-appimage --appimage-extract-and-run "$@"
      '';

      eden-fhs = pkgs.buildFHSEnv {
        name = pname;
        targetPkgs =
          pkgs: with pkgs; [
            fuse3
            vulkan-loader
            wayland
            libGL
            mesa
            glibc
            glib
            libx11
            libxext
            libxrandr
            libxi
            libxkbcommon
            fontconfig
            freetype
            alsa-lib
            pipewire
            libusb1
            udev
            zstd
            lz4
          ];
        runScript = launchScript;
      };
    in
    {
      packages.zen4 = pkgs.symlinkJoin {
        name = "${pname}-${version}";
        paths = [ eden-fhs ];
        postBuild = ''
                  mkdir -p $out/share/applications
                  cat > $out/share/applications/${pname}.desktop << EOF
          [Desktop Entry]
          Name=Eden
          Exec=${pname}
          Icon=${pname}
          Type=Application
          Categories=Game;Emulator;
          EOF
        '';
        meta = {
          description = "Nintendo Switch emulator (Zen 4 + PGO)";
          homepage = "https://eden-emu.dev/";
          license = pkgs.lib.licenses.gpl3Only;
          mainProgram = pname;
          platforms = [ "x86_64-linux" ];
        };
      };
    };
}
