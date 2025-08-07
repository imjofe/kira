# 🤖 Kira Flutter App - Model Setup Guide

This app uses a large fine-tuned Gemma model (8.4GB) that needs to be manually placed on the device due to Android build size limitations.

## 🚀 Quick Setup (Recommended)

1. **Build the app:**
   ```bash
   flutter build apk --debug
   ```

2. **Run the setup script:**
   ```bash
   ./setup_model.sh
   ```

The script will:
- ✅ Install the APK on your connected device
- ✅ Copy the model file to the correct location
- ✅ Set up all necessary directories

## 📱 Manual Setup

If the automatic script doesn't work, follow these steps:

### 1. Install the App
```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 2. Copy the Model File
The model needs to be placed at this exact location on your Android device:
```
/sdcard/Android/data/com.kira.app/files/models/gemma-wellness-f16.gguf
```

**Using ADB:**
```bash
# Create the directory
adb shell "mkdir -p /sdcard/Android/data/com.kira.app/files/models/"

# Copy the model (this takes a while - 8.4GB file)
adb push models/gemma-wellness-f16.gguf /sdcard/Android/data/com.kira.app/files/models/
```

**Using File Manager:**
1. Connect your device to your computer
2. Navigate to: `Android/data/com.kira.app/files/`
3. Create a `models` folder if it doesn't exist
4. Copy `gemma-wellness-f16.gguf` into the `models` folder

## 🔧 Troubleshooting

### Model Not Found Error
If you see: `Model file not found at /path/to/model`

**Solution:** Ensure the model file is exactly at:
```
/sdcard/Android/data/com.kira.app/files/models/gemma-wellness-f16.gguf
```

### Permission Issues
If you can't access the app's data folder:

1. **Enable USB Debugging** on your Android device
2. **Grant file access permissions** to the Kira app
3. Try copying to `/sdcard/Download/` first, then move using a file manager

### Large File Transfer
The 8.4GB model file may take 10-30 minutes to transfer depending on your connection speed.

## 🏗️ Architecture Details

**Why external storage?**
- Android has build size limitations that prevent including 8.4GB files in APKs
- The `getModelPath` method in `MainActivity.kt` points to external app storage
- `LlamaBridge.dart` checks for the model file before attempting to load it

**File locations:**
- **Project:** `models/gemma-wellness-f16.gguf` (for development)
- **Device:** `/sdcard/Android/data/com.kira.app/files/models/gemma-wellness-f16.gguf` (runtime)

## ✅ Verification

After setup, the app should:
1. ✅ Build successfully (no "array size too large" errors)
2. ✅ Start without crashes
3. ✅ Load the model on first chat interaction
4. ✅ Respond with your fine-tuned wellness assistant

## 🎉 Success!

Once set up correctly, you'll see your fine-tuned Gemma model responding in the chat instead of the generic "Sorry, an error occurred" message.