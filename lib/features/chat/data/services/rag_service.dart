import 'dart:math';
import 'package:localmind_ai/features/chat/domain/entities/rag_chunk.dart';

class RagService {
  List<String> chunkText(String text, {int size = 150, int overlap = 30}) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= size) return [text];
    
    final List<String> chunks = [];
    for (var i = 0; i < words.length; i += (size - overlap)) {
      final end = min(i + size, words.length);
      final chunkWords = words.sublist(i, end);
      chunks.add(chunkWords.join(' '));
      if (end == words.length) break;
    }
    return chunks;
  }

  Map<String, double> generateTermVectors(String chunkText) {
    final tokens = _tokenize(chunkText);
    if (tokens.isEmpty) return {};
    
    final Map<String, double> tf = {};
    for (final token in tokens) {
      tf[token] = (tf[token] ?? 0.0) + 1.0;
    }
    
    final double maxTf = tf.values.fold(0.0, max);
    final Map<String, double> normalized = {};
    tf.forEach((k, v) {
      normalized[k] = v / maxTf;
    });
    return normalized;
  }

  List<String> _tokenize(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty && !_stopWords.contains(token))
        .toList();
  }

  // Pure Dart Hybrid Semantic Search: Cosine Similarity on TF-IDF + Trigram Character Vectors
  List<RagChunkMatch> retrieveRelevantChunks({
    required String query,
    required List<RagChunk> allChunks,
    required Map<String, String> docNames, // docId -> docName
    int topK = 3,
  }) {
    if (allChunks.isEmpty || query.trim().isEmpty) return [];

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return [];

    // 1. Calculate Document Frequency (DF) across collection for TF-IDF
    final Map<String, int> df = {};
    for (final chunk in allChunks) {
      for (final term in chunk.termVectors.keys) {
        df[term] = (df[term] ?? 0) + 1;
      }
    }

    // 2. Calculate IDF for query terms
    final Map<String, double> idf = {};
    final totalDocs = allChunks.length.toDouble();
    for (final term in queryTokens) {
      final docsWithTerm = df[term] ?? 0;
      idf[term] = log(1.0 + (totalDocs / (1.0 + docsWithTerm)));
    }

    // 3. Vectorize Query (TF-IDF weights)
    final Map<String, double> queryWeights = {};
    for (final term in queryTokens) {
      queryWeights[term] = (queryWeights[term] ?? 0.0) + 1.0;
    }
    final maxQueryTf = queryWeights.values.fold(0.0, max);
    queryWeights.forEach((k, v) {
      queryWeights[k] = (v / maxQueryTf) * (idf[k] ?? 1.0);
    });

    final queryNorm = _vectorNorm(queryWeights);

    // 4. Trigrams of query for fuzzy character matching
    final queryTrigrams = _generateTrigrams(query);

    final List<RagChunkMatch> matches = [];

    for (final chunk in allChunks) {
      // Vector Cosine Similarity (TF-IDF)
      double tfIdfDotProduct = 0.0;
      chunk.termVectors.forEach((term, tfVal) {
        if (queryWeights.containsKey(term)) {
          final termIdf = idf[term] ?? 1.0;
          final chunkWeight = tfVal * termIdf;
          tfIdfDotProduct += queryWeights[term]! * chunkWeight;
        }
      });
      
      final chunkNorm = _vectorNorm(chunk.termVectors.map((k, v) => MapEntry(k, v * (idf[k] ?? 1.0))));
      final tfIdfSimilarity = (queryNorm > 0 && chunkNorm > 0) ? (tfIdfDotProduct / (queryNorm * chunkNorm)) : 0.0;

      // Trigram Character Cosine Similarity (Vector Cosine approximation)
      final chunkTrigrams = _generateTrigrams(chunk.text);
      final trigramOverlap = queryTrigrams.intersection(chunkTrigrams).length.toDouble();
      final trigramSimilarity = (queryTrigrams.isEmpty || chunkTrigrams.isEmpty) 
          ? 0.0 
          : trigramOverlap / (sqrt(queryTrigrams.length) * sqrt(chunkTrigrams.length));

      // Hybrid combination weight (70% keyword TF-IDF, 30% trigram vector cosine)
      final finalScore = (tfIdfSimilarity * 0.7) + (trigramSimilarity * 0.3);

      if (finalScore > 0.05) { // Similarity threshold
        matches.add(
          RagChunkMatch(
            chunk: chunk,
            documentName: docNames[chunk.documentId] ?? 'Document',
            score: finalScore,
          ),
        );
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches.take(topK).toList();
  }

  double _vectorNorm(Map<String, double> vector) {
    double sumOfSquares = 0.0;
    vector.values.forEach((v) => sumOfSquares += v * v);
    return sqrt(sumOfSquares);
  }

  Set<String> _generateTrigrams(String text) {
    final clean = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 3) return {clean};
    final Set<String> trigrams = {};
    for (var i = 0; i < clean.length - 2; i++) {
      trigrams.add(clean.substring(i, i + 3));
    }
    return trigrams;
  }

  String buildRagPrompt({
    required String systemPrompt,
    required List<RagChunkMatch> matches,
    required String userQuery,
  }) {
    if (matches.isEmpty) return userQuery;

    final contextBuffer = StringBuffer();
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      contextBuffer.writeln('---');
      contextBuffer.writeln('Source: ${match.documentName} (Paragraph ${match.chunk.index + 1})');
      contextBuffer.writeln(match.chunk.text);
    }
    contextBuffer.writeln('---');

    return '$systemPrompt\n\n'
        'Use the following pieces of context from imported documents to answer the user\'s question. '
        'If the context does not contain the answer, answer using your general knowledge, prioritizing details in the context.\n\n'
        'Context:\n$contextBuffer\n'
        'User Question: $userQuery';
  }

  static const Set<String> _stopWords = {
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your', 'yours', 
    'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 
    'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom', 
    'this', 'that', 'these', 'those', 'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 
    'have', 'has', 'had', 'having', 'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 
    'but', 'if', 'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for', 'with', 
    'about', 'against', 'between', 'into', 'through', 'during', 'before', 'after', 
    'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out', 'on', 'off', 'over', 'under', 
    'again', 'further', 'then', 'once', 'here', 'there', 'when', 'where', 'why', 'how', 
    'all', 'any', 'both', 'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 
    'nor', 'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't', 'can', 
    'will', 'just', 'don', 'should', 'now'
  };
}

class RagChunkMatch {
  final RagChunk chunk;
  final String documentName;
  final double score;

  const RagChunkMatch({
    required this.chunk,
    required this.documentName,
    required this.score,
  });
}
