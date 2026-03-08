#!/usr/bin/env bash

set -e

echo "========================================"
echo " RetroShare Optimized Build & Patch Tool "
echo "========================================"

Config

BUILD_ROOT="$HOME/retroshare-optimized"
SRC_DIR="$BUILD_ROOT/RetroShare"
LOG_DIR="$BUILD_ROOT/logs"
CPU_CORES=$(nproc)

mkdir -p "$BUILD_ROOT" "$LOG_DIR"

-------------------------------

1️⃣ Dépendances

-------------------------------

sudo apt update
sudo apt install -y git build-essential cmake make 
clang lld llvm gcc-aarch64-linux-gnu g++-aarch64-linux-gnu 
ccache checkinstall ninja-build 
qt6-base-dev qt6-base-dev-tools qt6-tools-dev 
qt6-multimedia-dev qt6-5compat-dev 
libssl-dev libsqlcipher-dev libbz2-dev libjson-c-dev 
libupnp-dev libxss-dev rapidjson-dev libasio-dev libbotan-2-dev 
libxml2-dev libxslt1-dev libcurl4-openssl-dev libsecret-1-dev

-------------------------------

2️⃣ Clone sources

-------------------------------

if [ ! -d "$SRC_DIR" ]; then
git clone https://github.com/RetroShare/RetroShare.git "$SRC_DIR"
fi

cd "$SRC_DIR"
git checkout develop || git checkout -b develop
git pull
git submodule update --init --recursive

-------------------------------

3️⃣ Apply WebUI / JSONAPI patches

-------------------------------

PATCH_DIR="$BUILD_ROOT/patches"
if [ -d "$PATCH_DIR" ]; then
for patch in $PATCH_DIR/*.patch; do
git apply "$patch"
done
fi

-------------------------------

4️⃣ Compilation optimisée

-------------------------------

export CC="ccache clang"
export CXX="ccache clang++"
export CFLAGS="-O3 -march=native -mtune=native -flto -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-flto"

qmake6 CONFIG+=release CONFIG+=rs_jsonapi CONFIG+=rs_webui
ninja -j$CPU_CORES | tee "$LOG_DIR/build.log"

-------------------------------

5️⃣ Création paquet .deb

-------------------------------

sudo checkinstall --pkgname=retroshare --pkgversion="$(git describe --tags --always)" 
--backup=no --deldoc=yes --fstrans=no --default

-------------------------------

6️⃣ Création AppImage portable

-------------------------------

APPDIR="$BUILD_ROOT/AppDir"
mkdir -p "$APPDIR/usr/bin"
cp RetroShare "$APPDIR/usr/bin"

wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage
./appimagetool-x86_64.AppImage "$APPDIR"

echo "========================================"
echo "Build & patch finished!"
echo "Artifacts in $BUILD_ROOT"
echo "Run RetroShare with: RetroShare"
