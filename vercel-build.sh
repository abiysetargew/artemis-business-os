#!/bin/bash
# Install Flutter SDK on Vercel
set -e

FLUTTER_VERSION="3.24.5"
FLUTTER_HOME="$HOME/flutter"
MOBILE_DIR="$(pwd)/mobile"

if [ ! -d "$FLUTTER_HOME" ]; then
  echo "Installing Flutter $FLUTTER_VERSION..."
  cd /tmp
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o flutter.tar.xz
  tar xf flutter.tar.xz -C "$HOME"
  rm flutter.tar.xz
fi

export PATH="$FLUTTER_HOME/bin:$PATH"
git config --global --add safe.directory "$FLUTTER_HOME"

# Suppress root warning
export FLUTTER_SUPPRESS_ANALYTICS=true
export BOT=true

cd "$MOBILE_DIR"

flutter --version
flutter config --no-analytics --no-cli-animations
flutter precache --no-android --no-ios --no-windows --no-macos --no-linux --web
flutter pub get
flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:4040/api/v1}" \
  --no-tree-shake-icons
