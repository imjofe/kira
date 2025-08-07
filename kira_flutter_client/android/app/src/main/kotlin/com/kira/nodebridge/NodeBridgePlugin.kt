package com.kira.nodebridge

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

// Placeholder for Node.js thread communication
object NodeThread {
    private val nodeIsReady = AtomicBoolean(false)

    fun postMessage(json: String) {
        Log.d("NodeBridge", "NodeThread.postMessage: $json")
        // In a real implementation, this would send the message to the Node.js thread.
        // For now, we'll simulate a response for testing purposes.
        if (json.contains("ping")) {
            // Simulate a pong response after a delay
            Thread { 
                Thread.sleep(1000) // Simulate network delay
                // This would typically come from the Node.js side
                // channel.invokeMethod("onFrameReceived", "{\"type\":\"server_sends_response\",\"payload\":{\"id\":1,\"role\":\"assistant\",\"content\":\"pong\",\"ts\":\"${System.currentTimeMillis()}\"}}")
                Log.d("NodeBridge", "Simulating pong response")
            }.start()
        }
    }

    fun setNodeReady(ready: Boolean) {
        nodeIsReady.set(ready)
    }

    fun isNodeReady(): Boolean = nodeIsReady.get()
}

class NodeBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kira/node")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                // Llama a tu código JNI: startNodeNative(...)
                NodeThread.setNodeReady(true)
                result.success(null)
            }
            "sendFrame" -> {
                val json = call.arguments as? String ?: "{}"
                if (NodeThread.isNodeReady()) {
                    // Forward to Node.js via nodejs-mobile or your existing bridge
                    NodeThread.postMessage(json)
                    result.success(true)
                } else {
                    Log.w("NodeBridge", "Node engine not ready; dropping frame")
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}