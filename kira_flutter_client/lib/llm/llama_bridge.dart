import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

// Define the C function signatures
typedef LlamaInitNative = Int32 Function(Pointer<Utf8> modelPath);
typedef LlamaInitDart = int Function(Pointer<Utf8> modelPath);

typedef GemmaRunNative = Int32 Function(Pointer<Utf8> prompt);
typedef GemmaRunDart = int Function(Pointer<Utf8> prompt);

class LlamaBridge {
  LlamaBridge({this.testMode = false}) {
    print('[LlamaBridge] ===== CONSTRUCTOR CALLED =====');
    print('[LlamaBridge] testMode: $testMode');
    print('[LlamaBridge] Instance created at: ${DateTime.now()}');
  }

  final bool testMode;
  static const MethodChannel _channel = MethodChannel('com.kira.app/llama');

  static final _lib = () {
    try {
      if (Platform.isAndroid) {
        return DynamicLibrary.open('libllama.so');
      }
      if (Platform.isMacOS) {
        return DynamicLibrary.open('libllama.dylib');
      }
      throw UnsupportedError('Unsupported platform');
    } catch (e) {
      print('[LlamaBridge] CRITICAL: Failed to load llama library: $e');
      rethrow;
    }
  }();

  late final LlamaInitDart _init = _lib
      .lookup<NativeFunction<LlamaInitNative>>('llama_init')
      .asFunction();

  late final GemmaRunDart _run = _lib
      .lookup<NativeFunction<GemmaRunNative>>('gemma_run')
      .asFunction();

  late final Pointer<Utf8> Function() _getLastResponse = _lib
      .lookup<NativeFunction<Pointer<Utf8> Function()>>('get_last_response')
      .asFunction();

  bool _isReady = false;

  Future<void> load(String assetName) async {
    if (testMode) {
      print('[LlamaBridge] Test mode - skipping model load');
      _isReady = true;
      return;
    }

    print('[LlamaBridge] Loading model: $assetName');

    try {
      // For the large wellness model, use external storage path instead of assets
      String modelPath;
      if (assetName == "gemma-wellness-f16.gguf") {
        print('[LlamaBridge] Using external storage for large model');
        modelPath = await _channel.invokeMethod('getModelPath', {'name': assetName});
        print('[LlamaBridge] Model path: $modelPath');

        // Check if the model file exists
        final file = File(modelPath);
        if (!file.existsSync()) {
          print('[LlamaBridge] ERROR: Model file not found at $modelPath');
          throw Exception('Model file not found at $modelPath. Please place the model file in the app\'s external storage.');
        }
        print('[LlamaBridge] Model file found, size: ${file.lengthSync()} bytes');
      } else {
        // For smaller models, use the asset extraction method
        print('[LlamaBridge] Using asset extraction for smaller model');
        modelPath = await _channel.invokeMethod('extractAsset', {'name': assetName});
        print('[LlamaBridge] Extracted to: $modelPath');
      }

      print('[LlamaBridge] Initializing model at: $modelPath');
      final code = _init(modelPath.toNativeUtf8());
      print('[LlamaBridge] Initialization result: $code');
      if (code != 0) throw Exception('llama_init failed ($code)');
      _isReady = true;
      print('[LlamaBridge] Model loaded successfully!');
    } catch (e) {
      print('[LlamaBridge] DETAILED ERROR: $e');
      throw e;
    }
  }

  Stream<String> run({required String prompt}) {
    print('[LlamaBridge] ===== RUN METHOD CALLED =====');
    print('[LlamaBridge] prompt: "$prompt"');
    print('[LlamaBridge] testMode: $testMode');
    print('[LlamaBridge] _isReady: $_isReady');
    
    if (!_isReady && !testMode) {
      print('[LlamaBridge] ERROR: Model not loaded');
      throw StateError('Model not loaded. Call load() first.');
    }

    if (testMode) {
      print('[LlamaBridge] Test mode - returning test response');
      return Stream.value('Test response from LlamaBridge');
    }

    print('[LlamaBridge] Running inference with prompt: "$prompt"');
    
    try {
      // Extract user input from JSON prompt
      String userInput = prompt;
      try {
        final jsonData = jsonDecode(prompt);
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('messages')) {
          final messages = jsonData['messages'] as List;
          // Find the last user message
          for (int i = messages.length - 1; i >= 0; i--) {
            final message = messages[i] as Map<String, dynamic>;
            if (message['role'] == 'user') {
              userInput = message['content'] as String;
              break;
            }
          }
          print('[LlamaBridge] Extracted user input from JSON: "$userInput"');
        }
      } catch (e) {
        print('[LlamaBridge] Failed to parse JSON, using prompt as-is: $e');
        // If JSON parsing fails, use the prompt as-is
        userInput = prompt;
      }
      
      // OFFLINE-FIRST: Use native llama.cpp for wellness responses
      print('[LlamaBridge] OFFLINE-FIRST: Using native Gemma model');
      
      try {
        final promptPtr = userInput.toNativeUtf8();
        print('[LlamaBridge] Calling native gemma_run with: "$userInput"');
        final result = _run(promptPtr);
        print('[LlamaBridge] Native gemma_run result: $result');
        
        if (result > 0) {
          // Get the actual response text from native code
          final responsePtr = _getLastResponse();
          final response = responsePtr.toDartString();
          print('[LlamaBridge] Native response: "$response"');
          return Stream.value(response);
        } else {
          print('[LlamaBridge] Native call failed, using fallback');
          String response = _generateContextualResponse(userInput);
          print('[LlamaBridge] Fallback response: "$response"');
          return Stream.value(response);
        }
      } catch (e) {
        print('[LlamaBridge] Error calling native code: $e');
        // Fallback to contextual responses
        String response = _generateContextualResponse(userInput);
        print('[LlamaBridge] Emergency fallback response: "$response"');
        return Stream.value(response);
      }
      
    } catch (e) {
      print('[LlamaBridge] Error during inference: $e');
      return Stream.error(e);
    }
  }

  String _generateContextualResponse(String prompt) {
    prompt = prompt.toLowerCase();
    
    // Greetings
    if (prompt.contains('hello') || prompt.contains('hi') || prompt.contains('hey')) {
      return 'Hello! I\'m Kira, your AI wellness assistant. I can help with fitness, nutrition, mental health, sleep, stress management, and goal setting. What would you like to work on today?';
    } 
    
    // Questions about me
    else if (prompt.contains('how are you') || prompt.contains('what are you') || prompt.contains('who are you')) {
      return 'I\'m Kira, your AI wellness companion! I\'m here to support your health and wellness journey. I can help you set goals, track progress, and provide guidance on fitness, nutrition, mental health, and more. How can I assist you today?';
    } 
    
    // Learning/Education
    else if (prompt.contains('learn') || prompt.contains('study') || prompt.contains('education') || prompt.contains('programming') || prompt.contains('python') || prompt.contains('coding')) {
      return 'Learning new skills is fantastic for mental wellness! While I specialize in health and wellness coaching, I believe continuous learning contributes to overall well-being. Are you looking to learn something wellness-related, or would you like tips on maintaining healthy study habits?';
    }
    
    // Goals and targets
    else if (prompt.contains('goal') || prompt.contains('target') || prompt.contains('objective') || prompt.contains('plan')) {
      return 'Goal setting is powerful for wellness! I can help you create SMART wellness goals. What area interests you most: fitness milestones, nutrition habits, mental health practices, sleep improvement, or stress management?';
    } 
    
    // Fitness and exercise
    else if (prompt.contains('fitness') || prompt.contains('exercise') || prompt.contains('workout') || prompt.contains('gym') || prompt.contains('running') || prompt.contains('strength')) {
      return 'Fitness is amazing for both physical and mental health! I can help you design workout routines, set fitness goals, or troubleshoot motivation issues. What\'s your current fitness level and what would you like to achieve?';
    } 
    
    // Nutrition and diet
    else if (prompt.contains('nutrition') || prompt.contains('diet') || prompt.contains('food') || prompt.contains('eating') || prompt.contains('meal') || prompt.contains('healthy eating')) {
      return 'Nutrition is fundamental to wellness! I can help with meal planning, healthy eating habits, understanding macros, or addressing specific dietary goals. What nutrition challenge are you facing?';
    } 
    
    // Mental health and stress
    else if (prompt.contains('stress') || prompt.contains('anxiety') || prompt.contains('mental') || prompt.contains('depression') || prompt.contains('mood') || prompt.contains('overwhelmed')) {
      return 'Mental health is just as important as physical health. I can guide you through stress management techniques, mindfulness practices, breathing exercises, and healthy coping strategies. What\'s been weighing on your mind lately?';
    } 
    
    // Sleep
    else if (prompt.contains('sleep') || prompt.contains('tired') || prompt.contains('insomnia') || prompt.contains('rest')) {
      return 'Quality sleep is the foundation of good health! I can help with sleep hygiene tips, bedtime routines, and addressing common sleep issues. Are you having trouble falling asleep, staying asleep, or feeling rested?';
    } 
    
    // Gratitude
    else if (prompt.contains('thank') || prompt.contains('appreciate')) {
      return 'You\'re so welcome! I\'m happy to support your wellness journey. Remember, small consistent steps lead to big changes. What would you like to focus on next?';
    }
    
    // Work and productivity
    else if (prompt.contains('work') || prompt.contains('productivity') || prompt.contains('busy') || prompt.contains('time management')) {
      return 'Work-life balance is crucial for wellness! I can help you manage stress from work, create healthy boundaries, build energizing routines, and maintain wellness habits even with a busy schedule. What work-related wellness challenge are you facing?';
    }
    
    // General wellness inquiry
    else {
      return 'I\'m Kira, your AI wellness coach! I\'m here to help you thrive in all areas of health and wellness. I can assist with fitness planning, nutrition guidance, stress management, sleep optimization, goal setting, and building healthy habits. What wellness area would you like to explore today?';
    }
  }
} 