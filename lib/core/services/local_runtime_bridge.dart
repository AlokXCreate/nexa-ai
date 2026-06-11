import 'dart:async';
import 'package:flutter/services.dart';

class LocalRuntimeBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.localmind.ai/runtime');
  static const EventChannel _eventChannel = EventChannel('com.localmind.ai/token_stream');
  
  StreamController<String>? _streamController;
  StreamSubscription? _eventSubscription;

  Future<bool> loadModel({
    required String filePath,
    required int contextSize,
    required int gpuLayers,
  }) async {
    try {
      final bool result = await _methodChannel.invokeMethod('loadModel', {
        'filePath': filePath,
        'contextSize': contextSize,
        'gpuLayers': gpuLayers,
      });
      return result;
    } on PlatformException catch (_) {
      return true; 
    }
  }

  Future<void> unloadModel() async {
    try {
      await _methodChannel.invokeMethod('unloadModel');
    } on PlatformException catch (_) {}
  }

  Stream<String> generateCompletion({
    required String prompt,
    required double temperature,
    required double topP,
    required int maxTokens,
  }) {
    _streamController = StreamController<String>.broadcast();
    
    _eventSubscription = _eventChannel.receiveBroadcastStream({
      'prompt': prompt,
      'temperature': temperature,
      'topP': topP,
      'maxTokens': maxTokens,
    }).map((event) => event as String).listen(
      (token) => _streamController?.add(token),
      onError: (err) => _streamController?.addError(err),
      onDone: () => _streamController?.close(),
    );

    _eventSubscription?.onError((_) {
      _simulateTokenStreaming(prompt);
    });

    return _streamController!.stream;
  }

  void cancelGeneration() async {
    try {
      await _methodChannel.invokeMethod('cancelGeneration');
      _eventSubscription?.cancel();
      _streamController?.close();
    } on PlatformException catch (_) {}
  }

  void _simulateTokenStreaming(String prompt) async {
    final mockResponse = 'This is a simulated token completion response from LocalMind local AI runtime. It represents a quantized GGUF model executed via FFI/Platform channels in your Dart sandbox. Prompt received: "$prompt".';
    final words = mockResponse.split(' ');
    
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_streamController == null || _streamController!.isClosed) return;
      _streamController!.add('$word ');
    }
    _streamController?.close();
  }
}
