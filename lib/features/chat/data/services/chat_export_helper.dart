import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:localmind_ai/features/chat/domain/entities/chat_message.dart';

class ChatExportHelper {
  
  static Future<String> exportChat({
    required String sessionTitle,
    required List<ChatMessage> messages,
    required String format, // 'md', 'txt', 'pdf', 'docx'
  }) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String sanitizedTitle = sessionTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final String filename = 'LocalMind_Export_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.$format';
    final String filePath = '${appDocDir.path}/$filename';
    
    final File file = File(filePath);
    
    switch (format.toLowerCase()) {
      case 'md':
        final content = _generateMarkdown(sessionTitle, messages);
        await file.writeAsString(content);
        break;
      case 'txt':
        final content = _generatePlainText(sessionTitle, messages);
        await file.writeAsString(content);
        break;
      case 'pdf':
        final content = _generatePdf(sessionTitle, messages);
        await file.writeAsBytes(content);
        break;
      case 'docx':
        // Generate an RTF file (Rich Text Format) compatible with Word and name it docx/rtf
        final content = _generateRtf(sessionTitle, messages);
        await file.writeAsString(content);
        break;
      default:
        throw Exception('Unsupported export format: $format');
    }
    
    return filePath;
  }

  static String _generateMarkdown(String title, List<ChatMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('# Conversation History: $title');
    buffer.writeln('*Exported on: ${DateTime.now().toLocal()}*\n');
    buffer.writeln('---');
    
    for (final msg in messages) {
      final sender = msg.sender == MessageSender.user ? '### 👤 User' : '### 🤖 LocalMind Assistant';
      buffer.writeln('\n$sender');
      buffer.writeln('*${msg.timestamp}*\n');
      buffer.writeln(msg.content);
      buffer.writeln('\n---');
    }
    
    return buffer.toString();
  }

  static String _generatePlainText(String title, List<ChatMessage> messages) {
    final buffer = StringBuffer();
    buffer.writeln('========================================================================');
    buffer.writeln('CONVERSATION LOG: $title');
    buffer.writeln('EXPORTED: ${DateTime.now().toLocal()}');
    buffer.writeln('========================================================================\n');
    
    for (final msg in messages) {
      final sender = msg.sender == MessageSender.user ? 'USER' : 'ASSISTANT';
      buffer.writeln('[$sender - ${msg.timestamp}]');
      buffer.writeln(msg.content);
      buffer.writeln('\n------------------------------------------------------------------------\n');
    }
    
    return buffer.toString();
  }

  static List<int> _generatePdf(String title, List<ChatMessage> messages) {
    // Generate minimal pure-Dart PDF text stream
    final streamContentBuffer = StringBuffer();
    streamContentBuffer.writeln('BT');
    streamContentBuffer.writeln('/F1 10 Tf');
    streamContentBuffer.writeln('14 TL');
    streamContentBuffer.writeln('50 740 Td');
    
    // Title
    streamContentBuffer.writeln('(${_escapePdfText("CONVERSATION REPORT: $title")}) Tj T*');
    streamContentBuffer.writeln('(${_escapePdfText("Exported: ${DateTime.now().toLocal()}")}) Tj T*');
    streamContentBuffer.writeln('() Tj T*');
    
    for (final msg in messages) {
      final sender = msg.sender == MessageSender.user ? 'USER' : 'ASSISTANT';
      streamContentBuffer.writeln('(${_escapePdfText("[$sender - ${msg.timestamp}]")}) Tj T*');
      
      final lines = _wrapText(msg.content, 75);
      for (final line in lines) {
        streamContentBuffer.writeln('(${_escapePdfText(line)}) Tj T*');
      }
      streamContentBuffer.writeln('() Tj T*');
    }
    
    streamContentBuffer.writeln('ET');
    
    final streamBytes = streamContentBuffer.toString();
    final streamLength = streamBytes.length;
    
    final buffer = StringBuffer();
    buffer.write('%PDF-1.4\n');
    
    final catalog = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n';
    final pages = '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n';
    final page = '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n';
    final content = '4 0 obj\n<< /Length $streamLength >>\nstream\n$streamBytes\nendstream\nendobj\n';
    final font = '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n';
    
    final offsets = <int>[];
    offsets.add(buffer.length);
    buffer.write(catalog);
    offsets.add(buffer.length);
    buffer.write(pages);
    offsets.add(buffer.length);
    buffer.write(page);
    offsets.add(buffer.length);
    buffer.write(content);
    offsets.add(buffer.length);
    buffer.write(font);
    
    final xrefOffset = buffer.length;
    buffer.write('xref\n0 6\n0000000000 65535 f\n');
    for (final offset in offsets) {
      buffer.write('${offset.toString().padLeft(10, '0')} 00000 n\n');
    }
    
    buffer.write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF');
    
    return buffer.toString().codeUnits;
  }

  static String _generateRtf(String title, List<ChatMessage> messages) {
    final buffer = StringBuffer();
    // Start RTF document
    buffer.write(r'{\rtf1\ansi\deff0{\fonttbl{\f0\fnil\fcharset0 Arial;}}');
    buffer.write(r'{\colortbl ;\red108\green99\blue255;\red100\green100\blue100;}');
    buffer.write(r'\viewkind4\uc1\pard\lang1033\f0\fs24');
    
    // Header
    buffer.write(r'\cf1\b\fs32 CONVERSATION LOG: ' + _escapeRtfText(title) + r'\par');
    buffer.write(r'\cf2\b0\fs18 Exported: ' + _escapeRtfText(DateTime.now().toLocal().toString()) + r'\par\par');
    buffer.write(r'\cf0\fs20\par');
    
    for (final msg in messages) {
      final sender = msg.sender == MessageSender.user ? 'USER' : 'ASSISTANT';
      final isUser = msg.sender == MessageSender.user;
      
      buffer.write(r'\pard\cf' + (isUser ? '1' : '2') + r'\b ' + sender + r' - ' + msg.timestamp.toString() + r'\b0\par ');
      buffer.write(_escapeRtfText(msg.content).replaceAll('\n', r'\par ') + r'\par\par ');
    }
    
    buffer.write(r'}');
    return buffer.toString();
  }

  static String _escapePdfText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll('\r', '')
        .replaceAll('\n', ' ');
  }

  static String _escapeRtfText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}')
        .replaceAll('\r', '');
  }

  static List<String> _wrapText(String text, int width) {
    final words = text.split(RegExp(r'\s+'));
    final List<String> lines = [];
    var currentLine = StringBuffer();
    
    for (final word in words) {
      if (currentLine.length + word.length + 1 > width) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine.toString());
          currentLine = StringBuffer();
        }
      }
      if (currentLine.isNotEmpty) {
        currentLine.write(' ');
      }
      currentLine.write(word);
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine.toString());
    }
    
    return lines.isNotEmpty ? lines : [''];
  }
}
