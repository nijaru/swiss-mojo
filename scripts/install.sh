#!/bin/bash
# Swiss Table for Mojo - Installation Script
# This script downloads and installs swiss-table.mojopkg for easy usage

set -e

REPO_URL="https://github.com/nijaru/swiss-mojo"
LATEST_RELEASE_URL="$REPO_URL/releases/latest/download/swiss-table.mojopkg"
INSTALL_DIR="${INSTALL_DIR:-./deps}"
PACKAGE_NAME="swiss-table.mojopkg"

echo "🔥 Swiss Table for Mojo - Installation"
echo "======================================"
echo ""

# Create deps directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

echo "📥 Downloading latest release..."
if command -v curl >/dev/null 2>&1; then
    curl -L -o "$INSTALL_DIR/$PACKAGE_NAME" "$LATEST_RELEASE_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -O "$INSTALL_DIR/$PACKAGE_NAME" "$LATEST_RELEASE_URL"
else
    echo "❌ Error: curl or wget required for download"
    echo "Please install curl or wget and try again"
    exit 1
fi

echo "✅ Swiss Table package installed to $INSTALL_DIR/$PACKAGE_NAME"
echo ""
echo "🚀 Usage in your Mojo code:"
echo "============================="
echo ""
cat << 'EOF'
```mojo
from swisstable import SwissTable, FastStringIntTable, MojoHashFunction

var table = SwissTable[String, Int](MojoHashFunction())
_ = table.insert("hello", 42)

# Or use specialized tables for maximum performance:
var fast_table = FastStringIntTable()
_ = fast_table.insert("count", 100)
```
EOF
echo ""
echo "💡 Add to your import path:"
echo "mojo run -I $INSTALL_DIR your_app.mojo"
echo ""
echo "📚 Documentation: $REPO_URL"
echo "🎉 Ready to use! Enjoy 1.16x faster insertions and 2.38x faster lookups!"
echo "   Plus specialized tables with up to 147% additional speedup!"