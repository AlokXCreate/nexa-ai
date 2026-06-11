import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

enum AssistantVoiceStatus { idle, listening, thinking, speaking }

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  
  bool _sttAvailable = false;
  bool _isSttInitialized = false;
  bool _useSimulator = false;

  AssistantVoiceStatus _status = AssistantVoiceStatus.idle;
  AssistantVoiceStatus get status => _status;

  final _statusController = StreamController<AssistantVoiceStatus>.broadcast();
  Stream<AssistantVoiceStatus> get statusStream => _statusController.stream;

  final _transcriptController = StreamController<String>.broadcast();
  Stream<String> get transcriptStream => _transcriptController.stream;

  final _decibelController = StreamController<double>.broadcast();
  Stream<double> get decibelStream => _decibelController.stream;

  // TTS Splicing Queue
  final List<String> _speechQueue = [];
  bool _isSpeakingQueue = false;
  StringBuffer _tokenBuffer = StringBuffer();
  
  // Audio decibel streams generator for simulated speech
  Timer? _decibelTimer;
  Timer? _simulatorTimer;
  String _simulatedTranscript = '';

  // Callbacks
  Function(String text)? onSpeechRecognized;
  Function()? onTtsQueueFinished;

  VoiceService() {
    _initPlatformStatus();
  }

  void _initPlatformStatus() {
    // Check if target platform natively supports the speech_to_text plugin
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _useSimulator = true;
      debugPrint('Voice Assistant: Unsupported platform for speech_to_text. Falling back to simulator mode.');
    }
  }

  /// Initializes both STT and TTS engines.
  Future<void> initialize() async {
    // 1. Initialize TTS
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Standard rate for flutter_tts (usually ranges from 0 to 1.0)
      
      _tts.setCompletionHandler(() {
        _speakNextInQueue();
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _speakNextInQueue();
      });
    } catch (e) {
      debugPrint('Failed to initialize TTS engine: $e');
    }

    // 2. Initialize STT (or simulator if on Windows/desktop)
    if (_useSimulator) {
      _isSttInitialized = true;
      _sttAvailable = true;
      return;
    }

    if (_isSttInitialized) return;

    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _sttAvailable = await _stt.initialize(
          onStatus: (statusVal) {
            debugPrint('STT Status: $statusVal');
            if (statusVal == 'done' || statusVal == 'notListening') {
              if (_status == AssistantVoiceStatus.listening) {
                _setStatus(AssistantVoiceStatus.idle);
              }
            }
          },
          onError: (errorVal) {
            debugPrint('STT Error: $errorVal');
            _setStatus(AssistantVoiceStatus.idle);
          },
        );
        _isSttInitialized = true;
      } else {
        _sttAvailable = false;
        _useSimulator = true; // Fallback to simulator if mic permission is denied
        debugPrint('Microphone permission denied. Falling back to simulator.');
      }
    } catch (e) {
      _sttAvailable = false;
      _useSimulator = true;
      _isSttInitialized = true;
      debugPrint('Failed to initialize speech_to_text plugin: $e. Using simulator fallback.');
    }
  }

  void _setStatus(AssistantVoiceStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  /// Starts listening to microphone input.
  Future<void> startListening() async {
    if (!_isSttInitialized) {
      await initialize();
    }

    if (_status == AssistantVoiceStatus.listening) return;

    // Interrupt any active TTS output before listening
    await stopSpeaking();
    _setStatus(AssistantVoiceStatus.listening);

    if (_useSimulator) {
      _startSimulatedListening();
      return;
    }

    try {
      _transcriptController.add('');
      await _stt.listen(
        onResult: (result) {
          _transcriptController.add(result.recognizedWords);
          if (result.finalResult) {
            _setStatus(AssistantVoiceStatus.thinking);
            if (onSpeechRecognized != null) {
              onSpeechRecognized!(result.recognizedWords);
            }
          }
        },
        soundLevelListener: (level) {
          // Normalise decibel levels (speech_to_text returns raw levels)
          final normalized = max(0.0, level * 2.0);
          _decibelController.add(normalized);
          
          // Interrupt detection: If user speaks loudly during speaking phase
          if (_status == AssistantVoiceStatus.speaking && level > 8.0) {
            stopSpeaking();
            startListening();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      _setStatus(AssistantVoiceStatus.idle);
    }
  }

  /// Stops listening to mic input.
  Future<void> stopListening() async {
    if (_status != AssistantVoiceStatus.listening) return;

    if (_useSimulator) {
      _stopSimulatedListening();
      return;
    }

    await _stt.stop();
    _setStatus(AssistantVoiceStatus.thinking);
  }

  // --- Simulated Speech recognition logic for unsupported environments (Windows) ---
  void _startSimulatedListening() {
    _simulatedTranscript = '';
    _transcriptController.add('');

    // Stream fake mic decibel readings
    _decibelTimer?.cancel();
    _decibelTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_status != AssistantVoiceStatus.listening) {
        timer.cancel();
        return;
      }
      // Generate standard conversational audio wave values
      final rand = Random();
      final level = 1.0 + rand.nextDouble() * 12.0;
      _decibelController.add(level);
    });

    // Simulated speech timeout
    final prompts = [
      'Tell me a joke about local AI models.',
      'What are the advantages of local GGUF offline execution?',
      'Summarize local knowledge base notes.',
      'Explain how neural networks capture representations.',
      'Hello assistant, are you running completely offline right now?'
    ];
    final selectedPrompt = prompts[Random().nextInt(prompts.length)];

    _simulatorTimer?.cancel();
    int wordIndex = 0;
    final words = selectedPrompt.split(' ');

    _simulatorTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_status != AssistantVoiceStatus.listening) {
        timer.cancel();
        return;
      }

      if (wordIndex < words.length) {
        _simulatedTranscript += (wordIndex == 0 ? '' : ' ') + words[wordIndex];
        _transcriptController.add(_simulatedTranscript);
        wordIndex++;
      } else {
        timer.cancel();
        _decibelTimer?.cancel();
        _decibelController.add(0.0);
        _setStatus(AssistantVoiceStatus.thinking);
        
        if (onSpeechRecognized != null) {
          onSpeechRecognized!(_simulatedTranscript);
        }
      }
    });
  }

  void _stopSimulatedListening() {
    _simulatorTimer?.cancel();
    _decibelTimer?.cancel();
    _decibelController.add(0.0);
    
    if (_simulatedTranscript.isEmpty) {
      _simulatedTranscript = 'Hello, can you hear me?';
      _transcriptController.add(_simulatedTranscript);
    }
    
    _setStatus(AssistantVoiceStatus.thinking);
    if (onSpeechRecognized != null) {
      onSpeechRecognized!(_simulatedTranscript);
    }
  }

  // --- Text to Speech & Splicing Queue ---

  /// Sets TTS configuration options.
  Future<void> configureTts({String? voiceName, double? speed}) async {
    if (speed != null) {
      // Map rate scale (0.5 to 1.5) to flutter_tts rate scale (0.0 to 1.0)
      final rateValue = (speed / 2.0).clamp(0.0, 1.0);
      await _tts.setSpeechRate(rateValue);
    }
    if (voiceName != null) {
      try {
        await _tts.setVoice({'name': voiceName, 'locale': 'en-US'});
      } catch (e) {
        debugPrint('Voice selection error: $e');
      }
    }
  }

  /// Appends streaming tokens from LLM and schedules sentences for speak queue.
  void feedStreamingToken(String token) {
    if (_status == AssistantVoiceStatus.listening) {
      return; // Ignore if user starts talking again
    }
    
    if (_status != AssistantVoiceStatus.speaking && _status != AssistantVoiceStatus.thinking) {
      _setStatus(AssistantVoiceStatus.speaking);
    }

    _tokenBuffer.write(token);
    final text = _tokenBuffer.toString();

    // Look for sentence terminators
    final int splitIndex = _findSentenceEnd(text);
    if (splitIndex != -1) {
      final sentence = text.substring(0, splitIndex + 1).trim();
      final remaining = text.substring(splitIndex + 1);
      
      _tokenBuffer = StringBuffer(remaining);
      
      if (sentence.isNotEmpty) {
        _queueSentence(sentence);
      }
    }
  }

  /// Call this when LLM finishes streaming to flush any remaining text in the buffer.
  void finalizeStreamingResponse() {
    final remaining = _tokenBuffer.toString().trim();
    if (remaining.isNotEmpty) {
      _queueSentence(remaining);
    }
    _tokenBuffer.clear();
  }

  int _findSentenceEnd(String text) {
    // Find first occurrence of punctuation that marks the end of a sentence
    int index = -1;
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '.' || char == '?' || char == '!' || char == '\n') {
        // Lookahead to check if it's a decimal number (e.g. "3.14")
        if (char == '.' && i > 0 && i < text.length - 1) {
          final isPrevDigit = _isDigit(text[i - 1]);
          final isNextDigit = _isDigit(text[i + 1]);
          if (isPrevDigit && isNextDigit) {
            continue; // Skip decimal dot
          }
        }
        index = i;
        break;
      }
    }
    return index;
  }

  bool _isDigit(String s) {
    return '0123456789'.contains(s);
  }

  void _queueSentence(String sentence) {
    _speechQueue.add(sentence);
    if (!_isSpeakingQueue) {
      _speakNextInQueue();
    }
  }

  Future<void> _speakNextInQueue() async {
    if (_speechQueue.isEmpty) {
      _isSpeakingQueue = false;
      if (_status == AssistantVoiceStatus.speaking) {
        _setStatus(AssistantVoiceStatus.idle);
      }
      if (onTtsQueueFinished != null) {
        onTtsQueueFinished!();
      }
      return;
    }

    _isSpeakingQueue = true;
    _setStatus(AssistantVoiceStatus.speaking);
    final sentence = _speechQueue.removeAt(0);

    try {
      await _tts.speak(sentence);
    } catch (e) {
      debugPrint('Error speaking sentence: $e');
      _speakNextInQueue();
    }
  }

  /// Stops any ongoing TTS output and clears speech queue.
  Future<void> stopSpeaking() async {
    _speechQueue.clear();
    _tokenBuffer.clear();
    _isSpeakingQueue = false;
    await _tts.stop();
    if (_status == AssistantVoiceStatus.speaking) {
      _setStatus(AssistantVoiceStatus.idle);
    }
  }

  /// Cancels both microphone listening and active speaker playbacks.
  Future<void> resetAll() async {
    _decibelTimer?.cancel();
    _simulatorTimer?.cancel();
    await stopSpeaking();
    if (_status == AssistantVoiceStatus.listening) {
      if (!_useSimulator) {
        await _stt.stop();
      }
    }
    _setStatus(AssistantVoiceStatus.idle);
    _decibelController.add(0.0);
  }

  /// Retrieves list of available offline TTS voices.
  Future<List<Map<String, String>>> getVoices() async {
    try {
      final List<dynamic>? voices = await _tts.getVoices;
      if (voices == null) return [];
      
      final List<Map<String, String>> enVoices = [];
      for (final v in voices) {
        if (v is Map) {
          final name = v['name']?.toString() ?? '';
          final locale = v['locale']?.toString() ?? '';
          if (locale.startsWith('en-') || locale.contains('en_')) {
            enVoices.add({
              'name': name,
              'locale': locale,
            });
          }
        }
      }
      return enVoices;
    } catch (e) {
      debugPrint('Failed to retrieve voices: $e');
      return [];
    }
  }

  /// Releases resources.
  void dispose() {
    _statusController.close();
    _transcriptController.close();
    _decibelController.close();
    _decibelTimer?.cancel();
    _simulatorTimer?.cancel();
  }
}
