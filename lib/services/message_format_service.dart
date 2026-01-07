// lib/services/message_format_service.dart
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;

/// 消息格式检测和解析服务
/// 支持三种格式：
/// 1. XML 格式（原生）
/// 2. 标记行格式（【旁白】/ 【对话】）
/// 3. 纯文本（降级方案）
class MessageFormatService {
  
  /// 检测内容的格式类型
  static MessageFormatType detectFormat(String content) {
    if (content.isEmpty) return MessageFormatType.unknown;
    
    // 检查是否是 XML
    if (content.contains('<message>') && content.contains('</message>')) {
      try {
        xml.XmlDocument.parse(content);
        return MessageFormatType.xml;
      } catch (e) {
        // XML 不合法，继续检查其他格式
      }
    }
    
    // ⭐ 检查是否是 Markdown 格式
    if (_hasMarkdownFormat(content)) {
      return MessageFormatType.markdown;
    }
    
    // 检查是否是标记行格式
    if (content.contains('【旁白】') || content.contains('【对话】')) {
      return MessageFormatType.taggedLines;
    }
    
    // 否则当作纯文本
    return MessageFormatType.plainText;
  }
  
  /// 检测是否包含 Markdown 格式标记
  static bool _hasMarkdownFormat(String content) {
    // 检查是否包含 *...* 或 "..."
    final hasAsterisk = RegExp(r'\*[^*]+\*').hasMatch(content);
    final hasQuote = RegExp(r'"[^"]+"').hasMatch(content);
    
    return hasAsterisk || hasQuote;
  }
  
  /// 解析内容，返回 (narration, dialogue) 对列表
  static List<(String type, String content)> parseContent(String content) {
    final format = detectFormat(content);
    
    if (kDebugMode) {
      debugPrint('📊 检测到格式: $format');
    }
    
    switch (format) {
      case MessageFormatType.xml:
        return _parseXml(content);
      case MessageFormatType.markdown:
        return _parseMarkdown(content);
      case MessageFormatType.taggedLines:
        return _parseTaggedLines(content);
      case MessageFormatType.plainText:
        return _parsePlainText(content);
      case MessageFormatType.unknown:
        return [];
    }
  }
  
  /// 解析 XML 格式
  static List<(String, String)> _parseXml(String content) {
    final result = <(String, String)>[];
    
    try {
      final document = xml.XmlDocument.parse(content);
      final messageElement = document.findElements('message').first;
      
      for (final child in messageElement.children.whereType<xml.XmlElement>()) {
        final text = child.innerText.trim();
        if (text.isEmpty) continue;
        
        if (child.name.local == 'narration') {
          result.add(('narration', text));
        } else if (child.name.local == 'dialogue') {
          result.add(('dialogue', text));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ XML 解析失败: $e');
      }
    }
    
    return result;
  }
  
/// 解析 Markdown 格式（优化版：引号=对话，其余=旁白）
static List<(String, String)> _parseMarkdown(String content) {
  final result = <(String, String)>[];
  final lines = content.split('\n');
  
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    
    // ⭐ 核心逻辑：只要包含引号，就提取对话
    final dialogueMatch = RegExp(r'"([^"]+)"').firstMatch(trimmed);
    if (dialogueMatch != null) {
      final text = dialogueMatch.group(1)?.trim() ?? '';
      if (text.isNotEmpty) {
        result.add(('dialogue', text));
        continue;
      }
    }
    
    // ⭐ 其余情况：全部当作旁白（包括 *...* 也是旁白）
    result.add(('narration', trimmed));
  }
  
  return result;
}

  /// 解析标记行格式
  static List<(String, String)> _parseTaggedLines(String content) {
    final result = <(String, String)>[];
    final lines = content.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      if (trimmed.startsWith('【旁白】')) {
        final text = trimmed.substring('【旁白】'.length).trim();
        if (text.isNotEmpty) {
          result.add(('narration', text));
        }
      } else if (trimmed.startsWith('【对话】')) {
        final text = trimmed.substring('【对话】'.length).trim();
        if (text.isNotEmpty) {
          result.add(('dialogue', text));
        }
      }
    }
    
    return result;
  }
  
  /// 降级方案：超级宽容的纯文本解析
static List<(String, String)> _parsePlainText(String content) {
  final result = <(String, String)>[];
  final lines = content.split('\n');
  
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    
    // ⭐ 规则1：包含引号 → 对话
    if (trimmed.contains('"') || trimmed.contains('"') || trimmed.contains('"')) {
      // 提取引号内容
      final match = RegExp(r'[""""]([^""""]*)[""""""]').firstMatch(trimmed);
      if (match != null) {
        final text = match.group(1)?.trim() ?? trimmed;
        result.add(('dialogue', text));
        continue;
      }
    }
    
    // ⭐ 规则2：以冒号/说开头 → 对话
    if (trimmed.contains('：') || trimmed.contains(':') || 
        trimmed.endsWith('说') || trimmed.startsWith('说')) {
      result.add(('dialogue', trimmed));
      continue;
    }
    
    // ⭐ 默认：全部旁白
    result.add(('narration', trimmed));
  }
  
  // 如果解析结果为空，整体作为旁白（不是对话）
  if (result.isEmpty) {
    return [('narration', content)];
  }
  
  return result;
}
}

enum MessageFormatType {
  xml,          // XML 格式
  markdown,     // Markdown 格式（*旁白* "对话"）
  taggedLines,  // 【旁白】/【对话】标记行
  plainText,    // 纯文本
  unknown,      // 未知
}