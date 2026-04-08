#!/bin/bash

# build_admin.sh
# This script builds the FireCMS project and integrates it into the Flutter web directory.

echo "🚀 Starting FireCMS Build..."

cd firecms

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing npm dependencies..."
    npm install
fi

echo "🏗 Building React application..."
npm run build

echo "📂 Integrating with Flutter Web..."
# Clean old admin directory
rm -rf ../web/admin
mkdir -p ../web/admin

# Copy build output to flutter project
cp -r dist/* ../web/admin/

echo "✅ FireCMS successfully integrated into /admin"
echo "💡 To view, run 'flutter run -d chrome' and navigate to /admin"
