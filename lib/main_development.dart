import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmind_ai/app.dart';
import 'package:localmind_ai/core/config/env_config.dart';
import 'package:localmind_ai/core/database/hive_client.dart';
import 'package:localmind_ai/core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Environment
  EnvConfig.initialize(Environment.development);
  
  // 2. Initialize Firebase
  await FirebaseService().init();
  
  // 3. Initialize Database
  await HiveClient.init();

  runApp(
    const ProviderScope(
      child: LocalMindApp(),
    ),
  );
}
