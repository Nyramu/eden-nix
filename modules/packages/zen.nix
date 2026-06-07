{
  perSystem =
    { pkgs, ... }:
    let
      pname = "eden";
      version = "0.2.1";

      icon = pkgs.fetchurl {
        url = "https://git.eden-emu.dev/eden-emu/eden/raw/branch/master/dist/eden.icon/Assets/dev.eden_emu.eden.svg";
        hash = "sha256-XrRaJfrcYvw10SO0/hlGKw5///7X3T8Ukg5UMrOFl2k=";
      };

      desktopItem = pkgs.makeDesktopItem {
        name = pname;
        desktopName = "Eden";
        exec = pname;
        icon = pname;
        categories = [
          "Game"
          "Emulator"
        ];
      };

      iconDrv = pkgs.runCommand "${pname}-icon" { } ''
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp ${icon} $out/share/icons/hicolor/scalable/apps/${pname}.svg
      '';

      mkEden =
        { src, description }:
        pkgs.symlinkJoin {
          name = "${pname}-${version}";
          paths = [
            (pkgs.buildFHSEnv {
              name = pname;
              targetPkgs =
                pkgs: with pkgs; [
                  vulkan-loader
                  wayland
                  libGL
                  mesa
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
              runScript = pkgs.writeShellScript "${pname}-launch" ''
                exec ${src} --appimage-extract-and-run "$@"
              '';
            })
            desktopItem
            iconDrv
          ];
          meta = {
            inherit description;
            homepage = "https://eden-emu.dev/";
            license = pkgs.lib.licenses.gpl3Only;
            mainProgram = pname;
            platforms = [ "x86_64-linux" ];
          };
        };

      variants = {
        zen2 = {
          src = pkgs.fetchurl {
            url = "https://stable.eden-emu.dev/v${version}/Eden-Linux-v${version}-steamdeck-clang-pgo.AppImage";
            hash = "sha256-XMWzWKxkSbQAIbILokMLTRIwJzfbFcjL5bRs6aq4XOU=";
            executable = true;
          };
          description = "Nintendo Switch emulator (Zen 2 + PGO)";
        };
        zen4 = {
          src = pkgs.fetchurl {
            url = "https://stable.eden-emu.dev/v${version}/Eden-Linux-v${version}-rog-ally-clang-pgo.AppImage";
            hash = "sha256-iiH5+NVFEN2vJblCaqBYwAjytpN+ULZ/4Ik/MSDaRYk=";
            executable = true;
          };
          description = "Nintendo Switch emulator (Zen 4 + PGO)";
        };
      };
    in
    {
      packages = builtins.mapAttrs (_: mkEden) variants;
    };
}
