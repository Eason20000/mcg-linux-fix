{
  description = "MCG Minecraft幻想乡 1.12.2 Linux 修复";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: (pkg.name or "") == "mcg-source.zip";
      };

      sourceZip = pkgs.requireFile {
        name = "mcg-source.zip";
        hash = "sha256-XjVX/pI0E609R3Mjq8cHRneokqyQGVhCybtgud16UbM=";
        message = ''
          MinecraftGensoukyo1.12.2（密码mcg）.zip 需从 QQ 群获取。
          请下载后执行：
            nix store add --mode flat --hash-algo sha256 --name mcg-source.zip 'MinecraftGensoukyo1.12.2（密码mcg）.zip'
        '';
      };

      fix4log4j = pkgs.fetchurl {
        name = "Fix4Log4J-1.0.2.jar";
        url = "https://github.com/Linux-MCG/fix4log4j/releases/download/linux-fix-01/Fix4Log4J-1.0.2.jar";
        hash = "sha256-kEW8l/OBRypGaYxCl9fP5b7zy8V2PtfTF9DF7UeFtNg=";
      };

      fantasticLib = pkgs.fetchurl {
        name = "FantasticLib-1.12.2.047.jar";
        url = "https://github.com/Linux-MCG/Fantastic-Lib/releases/download/linux-fix-01/FantasticLib-1.12.2.047.jar";
        hash = "sha256-GXy20MkyCz5weO+IgcSBMPokeph8NDxjrW42lh8Vot0=";
      };

      nyaSamaRailway = pkgs.fetchurl {
        name = "NyaSamaRailway-2.0.jar";
        url = "https://github.com/Linux-MCG/NyaSamaRailway/releases/download/linux-fix-01/NyaSamaRailway-2.0.jar";
        hash = "sha256-7wz+27eZCiTqUoK8LXNLYZYKCDVHgNcNnqwXPMPPU4s=";
      };

      gensouMusicFix = pkgs.fetchurl {
        name = "GensouMusic-Fix-1.0.0.jar";
        url = "https://github.com/Linux-MCG/GensouMusic-Fix/releases/download/1.0.0/GensouMusic-Fix-1.0.0.jar";
        hash = "sha256-f6FInlzb21FsoQoXRFLCio7iM0EdCBQRcdDPn9y2SEg=";
      };

      patchScript = pkgs.fetchgit {
        url = "https://github.com/Linux-MCG/NyaSamaRailway";
        rev = "33a222ad1082b04b63713700c134d177bd7cfbbc";
        sparseCheckout = [ "scripts" ];
        hash = "sha256-pn0koiSczIEkBjbJQH9s2cX+UiP4nWU7EyURiMwKssE=";
      };

      mcg-prism-pack = pkgs.stdenvNoCC.mkDerivation {
        pname = "mcg-prism-pack";
        version = "1.12.2-linux1";
        src = sourceZip;
        nativeBuildInputs = [
          pkgs.p7zip
          pkgs.zip
          pkgs.jq
          pkgs.glibc.bin
          pkgs.temurin-bin-8
        ];
        dontUnpack = true;
        dontConfigure = true;
        dontBuild = true;
        installPhase = ''
          set -euo pipefail
          export LC_ALL=C.UTF-8

          password=mcg
          pack_prefix='MinecraftGensoukyo1.12.2（密码mcg）/.minecraft/versions/MinecraftGensoukyo'
          b_jar_rel='mods/NyaSamaCompletePack-v2-mcg-201001-b.jar'
          railway_class='club/nsdn/nyasamarailway/renderer/tileentity/deco/PlatformHeadRenderer.class'
          views_rel='config/ChatTweaks/views.json'

          fail() {
              printf 'error: %s\n' "$*" >&2
              exit 1
          }

          check_sha() {
              local expected=$1 file=$2 actual
              actual=$(sha256sum "$file" | cut -d' ' -f1)
              [ "$actual" = "$expected" ] || fail "unexpected sha256 for $file: $actual"
          }

          work=$(mktemp -d)
          trap 'rm -rf "$work"' EXIT

          instance=$work/MCG-Prime
          game=$instance/minecraft
          mkdir -p "$instance"

          printf 'extracting game files...\n'
          7z x -y -bd -p"$password" -o"$work/raw" ${sourceZip} "-ir!*versions/MinecraftGensoukyo/*" >/dev/null
          mv "$work/raw/$pack_prefix" "$game"
          rm -rf "$game/PCL" \
                 "$game/\$natives" \
                 "$game/MinecraftGensoukyo-natives" \
                 "$game/natives-windows-x86_64" \
                 "$game/MinecraftGensoukyo.json" \
                 "$game/hmclversion.cfg"
          [ -f "$game/resourcepacks/mcgproject资源包.zip" ] || fail 'UTF-8 file name was mangled during extraction'
          [ -d "$game/mods" ] || fail 'mods directory is missing'
          [ ! -e "$game/versions" ] || fail 'version-isolated layout is still present'

          cat > "$instance/instance.cfg" <<'EOF'
          InstanceType=OneSix
          iconKey=default
          name=MinecraftGensoukyo
          OverrideMemory=true
          MinMemAlloc=4096
          MaxMemAlloc=10240
          EOF

          cat > "$instance/mmc-pack.json" <<'EOF'
          {
            "formatVersion": 1,
            "components": [
              { "uid": "net.minecraft", "version": "1.12.2", "important": true },
              { "uid": "net.minecraftforge", "version": "14.23.5.2847" }
            ]
          }
          EOF

          check_sha 9045bc97f381472a46698c4297d7cfe5bef3cbc5763ed7d317d0c5ed4785b4d8 ${fix4log4j}
          check_sha 197cb6d0c9320b3e7078ef8881c48130fa247a987c343c63ad6e36961f15a2dd ${fantasticLib}
          check_sha ef0cfedbb7990a24ea5282bc2d734b61960a08354780d70d9eac173cc3cf538b ${nyaSamaRailway}
          check_sha 7fa1489e5cdbdb516ca10a174452c28a8ee233411d08141171d0cf9fdcb64848 ${gensouMusicFix}

          install -m 0644 ${fix4log4j} "$game/mods/Fix4Log4J-1.0.2.jar"
          install -m 0644 ${fantasticLib} "$game/mods/FantasticLib-1.12.2.047.jar"
          install -m 0644 ${gensouMusicFix} "$game/mods/GensouMusic-Fix-1.0.0.jar"

          b_jar=$game/$b_jar_rel
          check_sha 694d22e75f0ddebb187f0b885010e67d52ee3d19492db1cf4b104302ef7e5999 "$b_jar"

          printf 'patching CompletePack B...\n'
          patched=$work/NyaSamaCompletePack-v2-mcg-201001-b-patched.jar
          JAVA_HOME=${pkgs.temurin-bin-8} bash ${patchScript}/scripts/patch-completepack-b.sh "$b_jar" ${nyaSamaRailway} "$patched"

          listing=$(7z l -ba "$patched")
          if [ "$(printf '%s\n' "$listing" | grep -ciE 'META-INF/[^ ]*\.(SF|RSA|DSA)$')" -ne 0 ]; then
              fail 'signature files remain in patched CompletePack B'
          fi
          class_sha=$(7z x -so -bd "$patched" "$railway_class" 2>/dev/null | sha256sum | cut -d' ' -f1)
          [ "$class_sha" = 5799260bfbce1db236cd6b8099556d09c83d3b88dfbe8f304b0f5f8f54f9ce79 ] ||
              fail "unexpected PlatformHeadRenderer sha256: $class_sha"
          manifest=$(7z x -so -bd "$patched" 'META-INF/MANIFEST.MF' 2>/dev/null)
          case "$manifest" in
              *NyaSama-Font-Fix*) ;;
              *) fail 'patched CompletePack B manifest lacks NyaSama-Font-Fix' ;;
          esac
          mv -f "$patched" "$b_jar"

          printf 'converting views.json...\n'
          views=$game/$views_rel
          iconv -f GBK -t UTF-8 "$views" > "$work/views.json"
          mv "$work/views.json" "$views"
          jq -e . "$views" >/dev/null

          printf 'packaging...\n'
          mkdir -p "$out"
          out_zip=$out/MCG-Prime.zip
          rm -f "$out_zip" "$out_zip.sha256"
          (
              cd "$instance"
              zip -q -r -X "$out_zip" instance.cfg mmc-pack.json minecraft
          )
          7z t -bd "$out_zip" >/dev/null

          ( cd "$out" && sha256sum MCG-Prime.zip > MCG-Prime.zip.sha256 )

          printf 'extracted files: %s\n' "$(find "$game" -type f | wc -l)"
          printf 'output: %s\n' "$out_zip"
          cat "$out_zip.sha256"
        '';
      };
    in
    {
      packages.${system}.default = mcg-prism-pack;
    };
}
