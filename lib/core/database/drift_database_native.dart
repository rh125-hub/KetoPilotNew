import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Create database executor for native platforms (mobile/desktop)
Future<QueryExecutor> createExecutor() async {
  try {
    // Minimal logging for faster startup
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ketopilot.db'));
    final executor = NativeDatabase(file);
    debugPrint('[DRIFT NATIVE] ✅ SQLite executor created');
    return executor;
  } catch (e) {
    debugPrint('[DRIFT NATIVE] ❌ Error: $e');
    rethrow;
  }
}



