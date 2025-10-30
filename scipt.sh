#!/usr/bin/env bash
#
# Automatic setup Android Development Environment for Flutter (Arch Linux)
# Tested on: Arch / Manjaro / EndeavourOS
# ------------------------------------------------------------

echo "=== [1/6] Updating System ==="
sudo pacman -Syu --noconfirm

echo "=== [2/6] Installing packages ==="
sudo pacman -S --noconfirm \
  git wget curl base-devel \
  flutter \
  jdk17-openjdk \
  android-sdk android-sdk-platform-tools android-sdk-build-tools \
  android-udev \
  clang cmake ninja pkgconf gtk3 libsecret

# Optional Waydroid (emulator)
read -p "Install Waydroid (Android emulator)? (y/n): " install_waydroid
if [[ "$install_waydroid" == "y" ]]; then
  sudo pacman -S --noconfirm waydroid
fi

echo "=== [3/6] Configuring environment variables ==="

ANDROID_HOME="$HOME/Android/Sdk"

mkdir -p "$ANDROID_HOME"

# Append env to .bashrc
cat <<EOF >> ~/.bashrc

# >>> ANDROID & FLUTTER ENV SETUP >>>
export ANDROID_HOME=\$HOME/Android/Sdk
export ANDROID_SDK_ROOT=\$ANDROID_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=\$PATH:\$ANDROID_HOME/emulator:\$ANDROID_HOME/platform-tools
export PATH=\$PATH:/opt/flutter/bin
# <<< ANDROID & FLUTTER ENV SETUP <<<
EOF

source ~/.bashrc

echo "=== [4/6] Setting permissions (adb udev rules) ==="
sudo usermod -aG adbusers $USER
sudo udevadm control --reload-rules
sudo systemctl restart systemd-udevd

echo "=== [5/6] Installing Android Platforms via sdkmanager ==="
yes | sdkmanager --sdk_root=$ANDROID_HOME "platform-tools"
yes | sdkmanager --sdk_root=$ANDROID_HOME "build-tools;34.0.0"
yes | sdkmanager --sdk_root=$ANDROID_HOME "platforms;android-34"
yes | sdkmanager --sdk_root=$ANDROID_HOME "cmdline-tools;latest"

echo "=== [6/6] Flutter Doctor ==="
flutter doctor

echo "✅ DONE — Restart terminal untuk apply environment"
echo "ℹ️  Cek instalasi dengan: flutter doctor -v"
