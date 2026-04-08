#!/bin/bash

# build_production.sh
# Master orchestration script for UniTask Production Builds

set -e # Exit on error

echo "🌟 Starting UniTask PRODUCTION Build Cycle"

# Load environment variables from .env
if [ -f ".env" ]; then
    echo "🔐 Loading secrets from .env..."
    export $(grep -v '^#' .env | xargs)
else
    echo "⚠️ Warning: .env not found. Build may fail if secrets are required."
fi

# 1. FireCMS Admin Consolidation
if [ -f "./build_admin.sh" ]; then
    echo "🛠 Step 1: Building FireCMS Admin Console..."
    # Use subshell to maintain root directory context
    (
        cd firecms
        echo "📦 Updating npm dependencies..."
        npm install
        echo "🏗 Building React application..."
        npm run build
    )
    ./build_admin.sh
else
    echo "❌ Error: build_admin.sh not found."
    exit 1
fi

# 2. Flutter Web Production Build
echo "🌐 Step 2: Building Flutter Web App..."
flutter build web --release \
    --dart-define=FLUTTER_FIREBASE_API_KEY_WEB=$FLUTTER_FIREBASE_API_KEY_WEB \
    --dart-define=FLUTTER_FIREBASE_APP_ID_WEB=$FLUTTER_FIREBASE_APP_ID_WEB \
    --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
    --dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET

# 3. Flutter Android Build (APK)
echo "🤖 Step 3: Building Flutter Android APK (Release)..."
# Pass signing variables explicitly for Gradle
export keyAlias=$ANDROID_KEY_ALIAS
export keyPassword=$ANDROID_KEY_PASSWORD
export storeFile=$ANDROID_STORE_FILE
export storePassword=$ANDROID_STORE_PASSWORD

flutter build apk --release \
    --dart-define=FLUTTER_FIREBASE_API_KEY_ANDROID=$FLUTTER_FIREBASE_API_KEY_ANDROID \
    --dart-define=FLUTTER_FIREBASE_APP_ID_ANDROID=$FLUTTER_FIREBASE_APP_ID_ANDROID \
    --dart-define=FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=$FIREBASE_MESSAGING_SENDER_ID \
    --dart-define=FIREBASE_STORAGE_BUCKET=$FIREBASE_STORAGE_BUCKET

echo "✨ Production Build Cycle COMPLETE!"
echo "📁 Web Artifacts: build/web"
echo "📁 Android APK: build/app/outputs/flutter-apk/app-release.apk"
