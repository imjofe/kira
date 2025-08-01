import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// Define the C function signature
typedef GemmaRun_C = Int32 Function(Pointer<Utf8> prompt);

// Define the Dart function signature
typedef GemmaRun_Dart = int Function(Pointer<Utf8> prompt);

class Gemma3n {
  static final DynamicLibrary _lib = Platform.isAndroid
      ? DynamicLibrary.open('libllama_bridge.so')
      : DynamicLibrary.open('llama_bridge');

  static final GemmaRun_Dart _gemmaRun = _lib
      .lookup<NativeFunction<GemmaRun_C>>('gemma_run')
      .asFunction<GemmaRun_Dart>();

  static Future<int> run(String prompt) async {
    final promptPtr = prompt.toNativeUtf8();
    final result = _gemmaRun(promptPtr);
    malloc.free(promptPtr);
    return result;
  }
}
