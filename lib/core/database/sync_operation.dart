import 'dart:convert';

enum SyncActionType { save, delete }

class SyncOperation {
  final String collectionName;
  final String documentId;
  final SyncActionType actionType;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const SyncOperation({
    required this.collectionName,
    required this.documentId,
    required this.actionType,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'collectionName': collectionName,
      'documentId': documentId,
      'actionType': actionType.name,
      'data': data != null ? jsonEncode(data) : null,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SyncOperation.fromMap(Map<dynamic, dynamic> map) {
    final dataStr = map['data'] as String?;
    return SyncOperation(
      collectionName: map['collectionName'] as String,
      documentId: map['documentId'] as String,
      actionType: SyncActionType.values.byName(map['actionType'] as String),
      data: dataStr != null ? jsonDecode(dataStr) as Map<String, dynamic> : null,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
