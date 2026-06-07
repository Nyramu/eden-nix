{
  perSystem =
    { pkgs, ... }:
    
    let
      pname = "eden";
      version = "0.2.1";
      
      src = pkgs.fetchurl {
        url = "https://stable.eden-emu.dev/v${version}/Eden-Linux-v${version}-rog-ally-clang-pgo.AppImage";
        hash = "sha256-iiH5+NVFEN2vJblCaqBYwAjytpN+ULZ/4Ik/MSDaRYk=";
        executable = true;
      };
      
      icon = pkgs.fetchurl {
        url = "https://git.eden-emu.dev/eden-emu/eden/raw/branch/master/dist/eden.icon/Assets/dev.eden_emu.eden.svg";
        hash = "sha256-XrRaJfrcYvw10SO0/hlGKw5///7X3T8Ukg5UMrOFl2k=";
      };
      
      launchScript = pkgs.writeShellScript "${pname}-launch" ''
        exec ${src} --appimage-extract-and-run "$@"
      '';
    
      desktopItem = pkgs.makeDesktopItem {
        name = pname;
        desktopName = "Eden";
        exec = pname;
        icon = pname;
        categories = [ "Game" "Emulator" ];
      };
      
      iconDrv = pkgs.runCommand "${pname}-icon" { } ''
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp ${icon} $out/share/icons/hicolor/scalable/apps/${pname}.svg
      '';
    
      eden-fhs = pkgs.buildFHSEnv {
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
        runScript = launchScript;
      };
    in
    {
      packages.zen4 = pkgs.symlinkJoin {
        name = "${pname}-${version}";
        
        paths = [
          eden-fhs
          desktopItem
          iconDrv
        ];
        
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
