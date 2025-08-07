#!/bin/bash

# Setup script for Kira Flutter App model
echo "🤖 Kira Flutter App - Model Setup"
echo "================================="

MODEL_FILE="models/gemma-wellness-f16.gguf"
PACKAGE_NAME="com.kira.app"

# Check if model file exists
if [ ! -f "$MODEL_FILE" ]; then
    echo "❌ Error: Model file not found at $MODEL_FILE"
    echo "Please ensure the gemma-wellness-f16.gguf file is in the models/ directory"
    exit 1
fi

echo "✅ Found model file: $MODEL_FILE"
echo "📱 Setting up model for Android device..."

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ Error: No Android device connected"
    echo "Please connect your Android device and enable USB debugging"
    exit 1
fi

echo "✅ Android device detected"

# Install the APK first
APK_FILE="build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK_FILE" ]; then
    echo "📦 Installing APK..."
    adb install "$APK_FILE"
else
    echo "⚠️  APK not found. Please run: flutter build apk --debug"
fi

# Create the directory on device
echo "📁 Creating app directory on device..."
adb shell "mkdir -p /sdcard/Android/data/$PACKAGE_NAME/files/models/"

# Copy the model file
echo "📤 Copying model file to device (this may take a while - 8.4GB file)..."
adb push "$MODEL_FILE" "/sdcard/Android/data/$PACKAGE_NAME/files/models/"

if [ $? -eq 0 ]; then
    echo "✅ Model setup complete!"
    echo "🚀 You can now run the app and the model should load correctly"
else
    echo "❌ Error copying model file to device"
    exit 1
fi

echo ""
echo "📝 Manual setup instructions:"
echo "If the script fails, you can manually copy the file to:"
echo "   /sdcard/Android/data/$PACKAGE_NAME/files/models/gemma-wellness-f16.gguf"
echo ""
echo "🎉 Setup complete! The app should now be able to load the model."