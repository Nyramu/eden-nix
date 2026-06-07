{ self, ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.qt6Packages)
        qtbase
        qtmultimedia
        qtwayland
        wrapQtAppsHook
        qttools
        qtwebengine
        qt5compat
        qtcharts
        quazip
        ;

      mcl = pkgs.stdenv.mkDerivation {
        pname = "mcl";
        version = "7b08d83";
        src = pkgs.fetchFromGitHub {
          owner = "azahar-emu";
          repo = "mcl";
          rev = "7b08d83418f628b800dfac1c9a16c3f59036fbad";
          hash = "sha256-uTOiOlMzKbZSjKjtVSqFU+9m8v8horoCq3wL0O2E8sI=";
        };
        nativeBuildInputs = [ pkgs.cmake ];
        buildInputs = [ pkgs.fmt_11 ];
      };

      nx_tzdb =
        let
          tzdbVersion = "121125";
        in
        pkgs.fetchzip {
          url = "https://git.crueter.xyz/misc/tzdb_to_nx/releases/download/${tzdbVersion}/${tzdbVersion}.tar.gz";
          hash = "sha256-6+qt4yzisNx8cAOrWVS+g/GCeTD37iejQN06Ij6OMxU=";
        };

      frozen =
        let
          rev = "61dce5ae18ca59931e27675c468e64118aba8744";
        in
        pkgs.stdenv.mkDerivation {
          pname = "frozen";
          version = builtins.substring 0 7 rev;
          src = pkgs.fetchFromGitHub {
            owner = "serge-sans-paille";
            repo = "frozen";
            inherit rev;
            hash = "sha256-zIczBSRDWjX9hcmYWYkbWY3NAAQwQtKhMTeHlYp4BKk=";
          };

          dontBuild = true;
          installPhase = ''
            mkdir -p $out/include
            cp -r include/* $out/include/

            mkdir -p $out/share/cmake/frozen
            cat > $out/share/cmake/frozen/frozenConfig.cmake <<'EOF'
            add_library(frozen::frozen-headers INTERFACE IMPORTED)
            set_target_properties(frozen::frozen-headers PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "''${CMAKE_CURRENT_LIST_DIR}/../../../include")

            add_library(frozen::frozen INTERFACE IMPORTED)
            set_target_properties(frozen::frozen PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "''${CMAKE_CURRENT_LIST_DIR}/../../../include")

            add_library(frozen INTERFACE IMPORTED)
            set_target_properties(frozen PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "''${CMAKE_CURRENT_LIST_DIR}/../../../include")

            set(frozen_FOUND TRUE)
            EOF
          '';
        };

      version = "0.2.1";
    in
    {
      packages.default = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "eden";
        inherit version;
        src = fetchTree {
          type = "git";
          url = "https://git.eden-emu.dev/eden-emu/eden.git";
          ref = "v${version}";
          rev = "58c1e20ee58efa3900ba616207d460886214480b";
          submodules = true;
        };

        patches = [ (self.outPath + "/modules/patches/discord-rpc-compat.patch") ];

        nativeBuildInputs = [
          pkgs.cmake
          pkgs.glslang
          pkgs.pkg-config
          pkgs.python3
          qttools
          wrapQtAppsHook
        ];

        buildInputs = [
          qtbase
          qtmultimedia
          qtwayland
          qtwebengine
          qt5compat
          qtcharts
          quazip
          pkgs.vulkan-headers
          pkgs.vulkan-memory-allocator
          pkgs.vulkan-utility-libraries
          pkgs.spirv-tools
          pkgs.spirv-headers
          pkgs.sirit
          pkgs.cubeb
          pkgs.enet
          pkgs.libopus
          pkgs.SDL2
          pkgs.openssl
          pkgs.httplib
          pkgs.cpp-jwt
          pkgs.ffmpeg-headless
          pkgs.boost
          pkgs.fmt_11
          pkgs.nlohmann_json
          pkgs.unordered_dense
          pkgs.lz4
          pkgs.zlib
          pkgs.zstd
          pkgs.zydis
          pkgs.stb
          pkgs.simpleini
          pkgs.libusb1
          pkgs.discord-rpc
          pkgs.gamemode
          pkgs.xbyak
          mcl
          frozen
        ];

        __structuredAttrs = true;
        cmakeFlags = [
          (lib.cmakeBool "ENABLE_LTO" true)
          (lib.cmakeBool "YUZU_TESTS" false)
          (lib.cmakeBool "DYNARMIC_TESTS" false)

          (lib.cmakeBool "ENABLE_QT6" true)
          (lib.cmakeBool "ENABLE_QT_TRANSLATION" true)

          (lib.cmakeBool "YUZU_USE_EXTERNAL_SDL2" false)
          (lib.cmakeBool "YUZU_USE_EXTERNAL_VULKAN_HEADERS" false)
          (lib.cmakeBool "YUZU_USE_EXTERNAL_VULKAN_UTILITY_LIBRARIES" false)
          (lib.cmakeBool "YUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS" false)
          (lib.cmakeBool "CPMUTIL_FORCE_SYSTEM" true)

          (lib.cmakeFeature "YUZU_TZDB_PATH" "${nx_tzdb}")
          (lib.cmakeBool "YUZU_CHECK_SUBMODULES" false)

          (lib.cmakeBool "YUZU_USE_QT_WEB_ENGINE" true)
          (lib.cmakeBool "YUZU_USE_QT_MULTIMEDIA" true)
          (lib.cmakeBool "USE_DISCORD_PRESENCE" true)

          (lib.cmakeBool "YUZU_ENABLE_COMPATIBILITY_REPORTING" false)
          (lib.cmakeBool "ENABLE_COMPATIBILITY_LIST_DOWNLOAD" true)

          (lib.cmakeFeature "TITLE_BAR_FORMAT_IDLE" "eden | {} (nix)")
          (lib.cmakeFeature "TITLE_BAR_FORMAT_RUNNING" "eden | {} (nix)")

          (lib.cmakeBool "SIRIT_USE_SYSTEM_SPIRV_HEADERS" true)
          (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-Wno-error -Wno-array-parameter -Wno-stringop-overflow")
        ];

        env.NIX_CFLAGS_COMPILE = "-msse4.2";

        qtWrapperArgs = [
          "--prefix LD_LIBRARY_PATH : ${
            lib.makeLibraryPath [
              pkgs.vulkan-loader
              pkgs.pipewire
            ]
          }"
        ];

        preConfigure = ''
          export SOURCE_DATE_EPOCH=${toString finalAttrs.src.lastModified}
          echo "${finalAttrs.version}" > GIT-REFSPEC
          echo "${finalAttrs.src.rev}" > GIT-COMMIT
          echo "${finalAttrs.version}" > GIT-TAG
        '';

        postInstall = ''
          install -Dm644 $src/dist/72-yuzu-input.rules $out/lib/udev/rules.d/72-yuzu-input.rules
        '';

        meta = {
          description = "Nintendo Switch video game console emulator";
          homepage = "https://eden-emu.dev/";
          downloadPage = "https://eden-emu.dev/download";
          changelog = "https://github.com/eden-emulator/Releases/releases";
          mainProgram = "eden";
          desktopFileName = "dist/dev.eden_emu.eden.desktop";
        };
      });
    };
}
