#!/bin/sh
# Copyright 2015-2020 The Khronos Group Inc.
# SPDX-License-Identifier: Apache-2.0

# exit if any command fails
set -e

gem install xcpretty

# git lfs is installed by the Brew add-on. See .travis.yml.
git lfs install
git lfs version

# Using vcpkg for various reasons:
#
# 1. It supports having versions for multiple architectures installed
# 2. It installs static libraries removing the need for installing and finding dylibs.
# 3. Brew is not intended for this kind of use. It's designed for running
#    the packages locally. It also does not support universal binaries or multiple
#    architecture installations.
# 4. MacPorts has similar issues to Brew though it does support universal binaries.
#    Unfortunately universal builds of some of our key packages do not succeed.

echo "**** Clone and install vcpkg."
pushd $MY_BUILD_ROOT
git clone https://github.com/microsoft/vcpkg
./vcpkg/bootstrap-vcpkg.sh

echo "**** Install OpenImageIO, OpenColorIO, assimp, SDL2 and their dependencies."
# Calling install then upgrade is less fragile when packages are added than
# if X; install; else upgrade; fi. Install just prints out a line that the
# package is already installed, when that is the case.
cd $VCPKG_ROOT
vcpkg="./vcpkg --x-install-root=$VCPKG_INSTALL_ROOT"

$vcpkg install --triplet x64-osx openimageio opencolorio
$vcpkg install --triplet x64-osx assimp
$vcpkg install --triplet arm64-osx assimp
# assimp does not yet build for arm64-ios
#$vcpkg install --triplet arm64-ios assimp
$vcpkg install --triplet x64-osx SDL2
$vcpkg install --triplet arm64-osx SDL2
$vcpkg install --triplet arm64-ios SDL2
# openimageio does not yet build for arm64-osx
#./vcpkg install --x-install-root=$VCPKG_INSTALL_ROOT --triplet arm64-osx openimageio opencolorio assimp SDL2
# For the simulator. Not yet tried.
#./vcpkg install --x-install-root=$VCPKG_INSTALL_ROOT --triplet x86-ios assimp SDL2
$vcpkg upgrade --no-dry-run
popd

echo "**** Install Vulkan SDK."
pushd /tmp
wget -O vulkansdk-macos-$VULKAN_SDK_VER.dmg https://sdk.lunarg.com/sdk/download/$VULKAN_SDK_VER/mac/vulkansdk-macos-$VULKAN_SDK_VER.dmg?Human=true
hdiutil attach vulkansdk-macos-$VULKAN_SDK_VER.dmg
sudo /Volumes/vulkansdk-macos-$VULKAN_SDK_VER/InstallVulkan.app/Contents/macOS/InstallVulkan --root "$VULKAN_INSTALL_DIR" --accept-licenses --default-answer --confirm-command install
hdiutil detach /Volumes/vulkansdk-macos-$VULKAN_SDK_VER
rm vulkansdk-macos-$VULKAN_SDK_VER.dmg
popd
