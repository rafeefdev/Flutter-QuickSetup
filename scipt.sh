#!/bin/bash
#
# Flutter Development Environment Setup Script
#
# This script automates the setup of a Flutter development environment on Linux.
# It detects the Linux distribution, installs necessary dependencies,
# installs Flutter SDK, and sets up Android development tools.
#
# Supported Distributions: Debian/Ubuntu, Arch Linux, Fedora/RHEL
#

# -----------------------------------------------------------------------------
# Script Configuration
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------

readonly RED='[0;31m'
readonly GREEN='[0;32m'
readonly YELLOW='[1;33m'
readonly NC='[0m' # No Color

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

log_info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

# -----------------------------------------------------------------------------
# Cleanup Function
# -----------------------------------------------------------------------------

cleanup() {
  log_info "Cleaning up..."
  # Add cleanup tasks here if needed
}

trap cleanup EXIT ERR

# -----------------------------------------------------------------------------
# Main Function
# -----------------------------------------------------------------------------

main() {
  log_info "Starting Flutter development environment setup..."

  # Detect Linux distribution
  if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
  elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    VER=$(cat /etc/debian_version)
  elif [ -f /etc/SuSe-release ]; then
    # Older SuSE/etc.
    ...
  elif [ -f /etc/redhat-release ]; then
    # Older Red Hat, CentOS, etc.
    ...
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    VER=$(uname -r)
  fi

  log_info "Detected OS: $OS $VER"

  # Install dependencies based on the detected distribution
  case "$OS" in
    "Ubuntu" | "Debian")
      install_dependencies_debian
      ;;
    "Arch Linux")
      install_dependencies_arch
      ;;
    "Fedora")
      install_dependencies_fedora
      ;;
    *)
      log_error "Unsupported operating system: $OS"
      exit 1
      ;;
  esac

  # Install Flutter SDK
  install_flutter

  # Install Android SDK
  install_android_sdk

  # Install Waydroid
  install_waydroid

  # Set up environment variables
  setup_environment

  # Run flutter doctor
  flutter doctor

  log_info "Flutter development environment setup complete!"
  log_info "Please restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to apply the changes."
}

# -----------------------------------------------------------------------------
# Distribution-specific Dependency Installation
# -----------------------------------------------------------------------------

install_dependencies_debian() {
  log_info "Installing dependencies for Debian/Ubuntu..."
  sudo apt-get update
  packages="curl git unzip xz-utils zip libglu1-mesa lib32stdc++6 openjdk-11-jdk"
  for package in $packages; do
    if dpkg -s $package >/dev/null 2>&1; then
      log_warn "$package is already installed. Skipping."
    else
      sudo apt-get install -y $package
    fi
  done
}

install_dependencies_arch() {
  log_info "Installing dependencies for Arch Linux..."
  sudo pacman -Syu --noconfirm
  packages="curl git unzip xz zip libglu jdk11-openjdk"
  for package in $packages; do
    if pacman -Q $package >/dev/null 2>&1; then
      log_warn "$package is already installed. Skipping."
    else
      sudo pacman -S --noconfirm $package
    fi
  done
}

install_dependencies_fedora() {
  log_info "Installing dependencies for Fedora..."
  sudo dnf update
  packages="curl git unzip xz-utils zip mesa-libGLU java-11-openjdk-devel"
  for package in $packages; do
    if rpm -q $package >/dev/null 2>&1; then
      log_warn "$package is already installed. Skipping."
    else
      sudo dnf install -y $package
    fi
  done
}

# -----------------------------------------------------------------------------
# Flutter SDK Installation
# -----------------------------------------------------------------------------

install_flutter() {
  log_info "Installing Flutter SDK..."
  if [ -d "$HOME/flutter" ]; then
    log_warn "Flutter SDK already exists. Skipping installation."
    return
  fi

  git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter

  log_info "Flutter SDK installed successfully."
}

# -----------------------------------------------------------------------------
# Android SDK Installation
# -----------------------------------------------------------------------------

install_android_sdk() {
  log_info "Installing Android SDK..."

  export ANDROID_HOME=$HOME/Android/Sdk
  mkdir -p $ANDROID_HOME

  # Get the latest command line tools URL
  STUDIO_DOWNLOAD_PAGE="https://developer.android.com/studio"
  LATEST_CMDLINE_TOOLS_URL=$(curl -s "$STUDIO_DOWNLOAD_PAGE" | grep -o "https:\/\/dl.google.com\/android\/repository\/commandlinetools\-linux\-[0-9]*_latest\.zip" | head -n 1)

  if [ -z "$LATEST_CMDLINE_TOOLS_URL" ]; then
    log_error "Failed to get the latest Android command line tools URL."
    exit 1
  fi

  # Download and install Android command line tools
  wget "$LATEST_CMDLINE_TOOLS_URL" -P /tmp
  unzip /tmp/commandlinetools-linux-*_latest.zip -d /tmp
  mkdir -p $ANDROID_HOME/cmdline-tools/latest
  mv /tmp/cmdline-tools/* $ANDROID_HOME/cmdline-tools/latest/

  # Accept licenses
  yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses

  # Install platform-tools, build-tools, and system images
  $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.1"

  log_info "Android SDK installed successfully."
}

# -----------------------------------------------------------------------------
# Waydroid Installation
# -----------------------------------------------------------------------------

install_waydroid() {
    log_info "Installing Waydroid..."
    if command -v waydroid >/dev/null 2>&1; then
        log_warn "Waydroid is already installed. Skipping."
        return
    fi

    case "$OS" in
        "Ubuntu" | "Debian")
            sudo apt install -y curl
            curl -sS https://raw.githubusercontent.com/waydroid/waydroid/main/tools/install.sh | sudo bash
            ;;
        "Arch Linux")
            yay -S waydroid
            ;;
        "Fedora")
            sudo dnf install -y waydroid
            ;;
    esac
    log_info "Waydroid installed successfully."
}

# -----------------------------------------------------------------------------
# Environment Setup
# -----------------------------------------------------------------------------

detect_java_home() {
    local detected_java_home=""

    # 1. Check common installation paths
    local common_paths=(
        "/usr/lib/jvm/java-11-openjdk-amd64"
        "/usr/lib/jvm/java-11-openjdk"
        "/usr/lib/jvm/jdk-11"
    )

    for path in "${common_paths[@]}"; do
        if [ -d "$path" ]; then
            detected_java_home=$path
            break
        fi
    done

    if [ -z "$detected_java_home" ]; then
        log_error "Failed to detect JAVA_HOME."
        exit 1
    fi

    echo $detected_java_home
}

setup_environment() {
  log_info "Setting up environment variables..."

  # Detect shell
  if [ -n "$ZSH_VERSION" ]; then
    PROFILE_FILE="$HOME/.zshrc"
  else
    PROFILE_FILE="$HOME/.bashrc"
  fi

  # Set JAVA_HOME
  JAVA_HOME=$(detect_java_home)

  # Add environment variables to profile file
  echo '' >> $PROFILE_FILE
  echo '# Flutter and Android SDK' >> $PROFILE_FILE
  echo "export FLUTTER_HOME=$HOME/flutter" >> $PROFILE_FILE
  echo 'export PATH=$FLUTTER_HOME/bin:$PATH' >> $PROFILE_FILE
  echo "export ANDROID_HOME=$HOME/Android/Sdk" >> $PROFILE_FILE
  echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> $PROFILE_FILE
  echo 'export PATH=$ANDROID_HOME/platform-tools:$PATH' >> $PROFILE_FILE
  echo "export JAVA_HOME=$JAVA_HOME" >> $PROFILE_FILE
  echo 'export PATH=$JAVA_HOME/bin:$PATH' >> $PROFILE_FILE

  log_info "Environment variables set in $PROFILE_FILE"
}


# -----------------------------------------------------------------------------
# Script Execution
# -----------------------------------------------------------------------------

main