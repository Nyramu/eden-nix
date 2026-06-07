{
  perSystem =
    { pkgs, ... }:

    let
      pname = "eden";
      version = "0.2.1";
      
      src = pkgs.fetchurl {
        url = "https://stable.eden-emu.dev/v${version}/Eden-Linux-v${version}-rog-ally-clang-pgo.AppImage";
        hash = "sha256-Ak3+MH9+W1ObNUm9kkX2txybqpzHRPMdWNMYGFfYX/w=";
      };
      
      icon = pkgs.fetchurl {
        url = "https://git.eden-emu.dev/eden-emu/eden/raw/branch/master/dist/eden.icon/Assets/dev.eden_emu.eden.svg";
        hash = "sha256-XrRaJfrcYvw10SO0/hlGKw5///7X3T8Ukg5UMrOFl2k=";
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
                  mkdir -p $out/share/icons/hicolor/scalable/apps
                  cp ${icon} $out/share/icons/hicolor/scalable/apps/${pname}.svg
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
