class RagChunk {
  final String id;
  final String documentId;
  final String text;
  final int index;
  final Map<String, double> termVectors;

  const RagChunk({
    required this.id,
    required this.documentId,
    required this.text,
    required this.index,
    this.termVectors = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'text': text,
      'index': index,
      'termVectors': termVectors,
    };
  }

  factory RagChunk.fromMap(Map<dynamic, dynamic> map) {
    // Hive maps dynamic keys/values. Cast safely.
    final rawVectors = map['termVectors'] as Map?;
    final Map<String, double> castedVectors = {};
    if (rawVectors != null) {
      rawVectors.forEach((k, v) {
        castedVectors[k.toString()] = (v as num).toDouble();
      });
    }

    return RagChunk(
      id: map['id'] as String,
      documentId: map['documentId'] as String,
      text: map['text'] as String,
      index: map['index'] as int,
      termVectors: castedVectors,
    );
  }
}
