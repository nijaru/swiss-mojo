#!/bin/bash
# Build swiss-table.mojopkg for distribution

set -e

echo "🔥 Building Swiss Table package for Mojo..."

# Clean previous builds
rm -f swiss-table.mojopkg
rm -f swiss_table.mojopkg

# Verify source files exist
if [ ! -d "swisstable" ]; then
    echo "❌ Error: swisstable directory not found"
    exit 1
fi

echo "📦 Creating Mojo package..."

# Build the package using pixi
if ! pixi run mojo package swisstable -o swiss-table.mojopkg; then
    echo "❌ Error: Failed to build package"
    exit 1
fi

echo "✅ Package built successfully: swiss-table.mojopkg"

# Test the package
echo "🧪 Testing package import..."
echo "from swiss_table import SwissTable; print('Package import successful!')" | pixi run mojo run -I . --stdin

echo "✅ Package import test passed"

# Show package info
echo "📊 Package information:"
ls -lh swiss-table.mojopkg
echo "Package name: swiss-table.mojopkg"
echo "Size: $(ls -lh swiss-table.mojopkg | awk '{print $5}')"

echo "🎉 Swiss Table package ready for distribution!"
echo ""
echo "Installation instructions:"
echo "1. Download swiss-table.mojopkg"
echo "2. Place in your project directory"  
echo "3. Import: from swiss_table import SwissTable"