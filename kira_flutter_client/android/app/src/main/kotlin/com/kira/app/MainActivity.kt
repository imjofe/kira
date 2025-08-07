package com.kira.app

import com.kira.nodebridge.NodeBridgePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Environment
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.kira.app/llama"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NodeBridgePlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "extractAsset" -> {
                    val assetName = call.argument<String>("name")
                    if (assetName != null) {
                        val path = extractAsset(assetName)
                        result.success(path)
                    } else {
                        result.error("INVALID_ARGUMENT", "Asset name is null", null)
                    }
                }
                "getModelPath" -> {
                    val modelName = call.argument<String>("name")
                    if (modelName != null) {
                        val path = getModelPath(modelName)
                        result.success(path)
                    } else {
                        result.error("INVALID_ARGUMENT", "Model name is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun extractAsset(name: String): String {
        val file = File(filesDir, name)
        if (file.exists()) {
            return file.absolutePath
        }
        // Look for the model in the models/ subdirectory
        val assetPath = "models/$name"
        assets.open(assetPath).use { input ->
            FileOutputStream(file).use { output ->
                input.copyTo(output)
            }
        }
        return file.absolutePath
    }

    private fun getModelPath(modelName: String): String {
        // For large models, we expect them to be in the app's external files directory
        val externalFilesDir = getExternalFilesDir(null)
        val modelFile = File(externalFilesDir, "models/$modelName")
        
        // Create the directory if it doesn't exist
        modelFile.parentFile?.mkdirs()
        
        android.util.Log.d("MainActivity", "getModelPath called for: $modelName")
        android.util.Log.d("MainActivity", "External files dir: $externalFilesDir")
        android.util.Log.d("MainActivity", "Model file path: ${modelFile.absolutePath}")
        android.util.Log.d("MainActivity", "Model directory exists: ${modelFile.parentFile?.exists()}")
        android.util.Log.d("MainActivity", "Model directory readable: ${modelFile.parentFile?.canRead()}")
        android.util.Log.d("MainActivity", "Model directory writable: ${modelFile.parentFile?.canWrite()}")
        android.util.Log.d("MainActivity", "Model file exists: ${modelFile.exists()}")
        
        // List files in the models directory
        val modelsDir = File(externalFilesDir, "models")
        if (modelsDir.exists()) {
            android.util.Log.d("MainActivity", "Files in models directory:")
            modelsDir.listFiles()?.forEach { file ->
                android.util.Log.d("MainActivity", "  - ${file.name} (${file.length()} bytes, readable: ${file.canRead()})")
            }
        }
        
        // Try different approaches to access the file
        val alternativePaths = listOf(
            "/storage/emulated/0/Android/data/${packageName}/files/models/$modelName",
            "${externalFilesDir}/models/$modelName",
            File(filesDir, modelName).absolutePath  // Internal storage
        )
        
        for (path in alternativePaths) {
            val testFile = File(path)
            android.util.Log.d("MainActivity", "Testing path: $path, exists: ${testFile.exists()}")
            if (testFile.exists()) {
                android.util.Log.d("MainActivity", "Found model at: $path")
                return path
            }
        }
        
        // If the model doesn't exist, try to copy it from Download folder
        if (!modelFile.exists()) {
            android.util.Log.d("MainActivity", "Model not found, attempting to copy from Download...")
            val downloadFile = File("/sdcard/Download/$modelName")
            if (downloadFile.exists()) {
                try {
                    android.util.Log.d("MainActivity", "Copying model from Download folder...")
                    downloadFile.copyTo(modelFile, overwrite = true)
                    android.util.Log.d("MainActivity", "Model copied successfully!")
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "Failed to copy model: ${e.message}")
                }
            } else {
                android.util.Log.e("MainActivity", "Model not found in Download folder either")
            }
        }
        
        if (modelFile.exists()) {
            android.util.Log.d("MainActivity", "Model file size: ${modelFile.length()} bytes")
        }
        
        return modelFile.absolutePath
    }
}
