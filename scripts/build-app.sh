#!/bin/sh
# Construye la app: `scripts/build-app.sh` deja Overink.app en build/, lista para
# abrir con `open build/Overink.app`.
#
# No hay ni habrá proyecto de Xcode: SwiftPM compila el binario con el SDK de las
# Command Line Tools y este script lo envuelve en un bundle con su Info.plist y lo
# firma ad-hoc, que es todo lo que macOS necesita para ejecutarlo en este Mac.
set -eu

cd "$(dirname "$0")/.."

# El toolchain se fija a mano: sin esto, en un Mac con Xcode instalado `swift build`
# usaría el de Xcode y dejaría de ser cierto que el proyecto se construye solo con las
# Command Line Tools.
DEVELOPER_DIR="/Library/Developer/CommandLineTools"
export DEVELOPER_DIR
if [ ! -d "$DEVELOPER_DIR" ]; then
	echo "No hay Command Line Tools en $DEVELOPER_DIR: instálalas con xcode-select --install" >&2
	exit 1
fi

BUNDLE_ID="dev.overink.Overink"
VERSION="0.1.0"
APP="build/Overink.app"

swift build -c release --product Overink
BIN="$(swift build -c release --product Overink --show-bin-path)/Overink"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Overink"

# LSUIElement es lo que mantiene a Overink fuera del Dock y de Cmd+Tab.
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>Overink</string>
	<key>CFBundleDisplayName</key>
	<string>Overink</string>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
	<key>CFBundleExecutable</key>
	<string>Overink</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>$VERSION</string>
	<key>CFBundleVersion</key>
	<string>$VERSION</string>
	<key>LSMinimumSystemVersion</key>
	<string>15.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

# Firma ad-hoc: vale para este Mac y no exige certificado de desarrollador.
codesign --force --sign - "$APP"

echo "Listo: $APP"
