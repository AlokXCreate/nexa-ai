import 'package:hive_flutter/hive_flutter.dart';

class HiveClient {
  static const String modelsBoxName = 'modelsBox';
  static const String settingsBoxName = 'settingsBox';
  static const String downloadsBoxName = 'downloadsBox';
  static const String installedModelsBoxName = 'installedModelsBox';
  static const String chatSessionsBoxName = 'chatSessionsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register Adapters here (when generated)
    // Hive.registerAdapter(AiModelAdapter());

    // Open critical boxes upfront
    await Hive.openBox(modelsBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(downloadsBoxName);
    await Hive.openBox(installedModelsBoxName);
    await Hive.openBox(chatSessionsBoxName);
  }

  static Box get modelsBox => Hive.box(modelsBoxName);
  static Box get settingsBox => Hive.box(settingsBoxName);
  static Box get downloadsBox => Hive.box(downloadsBoxName);
  static Box get installedModelsBox => Hive.box(installedModelsBoxName);
  static Box get chatSessionsBox => Hive.box(chatSessionsBoxName);
}
