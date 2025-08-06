#!/bin/bash

print_header() {
  echo ""
  echo "================================================="
  echo " $1"
  echo "================================================="
}

print_header "Checking for xc3sprog"

if command -v xc3sprog &> /dev/null; then
  echo "'xc3sprog' is already installed. Nothing to do."
  exit 0
fi

echo "'xc3sprog' not found. Starting installation process..."

print_header "Installing Build Dependencies"
echo "This script requires 'git' and 'base-devel' packages."
echo "Your sudo password may be required."
sudo pacman -S --needed --noconfirm git base-devel

if [ $? -ne 0 ]; then
  echo "Error: Failed to install build dependencies. Please check pacman."
  exit 1
fi

TMP_BUILD_DIR="/tmp/xc3sprog-build-$$"
echo "Cloning xc3sprog-svn from AUR into '$TMP_BUILD_DIR'..."

git clone https://aur.archlinux.org/xc3sprog-svn.git "$TMP_BUILD_DIR"

if [ $? -ne 0 ]; then
  echo "Error: Failed to clone AUR repository. Please check your internet connection."
  exit 1
fi

cd "$TMP_BUILD_DIR" || exit

print_header "Patching PKGBUILD for Modern CMake"

NEW_CMAKE_LINE="  cmake ../trunk -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_CXX_STANDARD=11 -DCMAKE_POLICY_VERSION_MINIMUM=3.5"

sed -i "s|cmake .*|$NEW_CMAKE_LINE|" PKGBUILD

echo "PKGBUILD has been patched successfully."

print_header "Building and Installing xc3sprog"
echo "This will compile the source and install it system-wide."
echo "Your sudo password may be required for the installation step."

makepkg -si --noconfirm

EXIT_CODE=$?

print_header "Cleaning Up"
echo "Removing build directory: $TMP_BUILD_DIR"
cd ~ && rm -rf "$TMP_BUILD_DIR"

if [ $EXIT_CODE -eq 0 ]; then
  print_header "Success! xc3sprog has been installed."
  echo -n "Verifying installation: "
  xc3sprog -h
else
  print_header "Error! xc3sprog installation failed."
  echo "Please review the build output above for specific errors."
fi

exit $EXIT_CODE