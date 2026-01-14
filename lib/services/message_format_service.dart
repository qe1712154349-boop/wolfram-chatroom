// lib/services/message_format_service.dart
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;

/// 消息格式检测和解析服务
/// 支持四种格式：
/// 1. XML 格式（原生）
/// 2. Markdown 格式（*旁白* "对话" 或 （动作）对话）
/// 3. 标记行格式（【旁白】/ 【对话】）
/// 4. 纯文本（降级方案）
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
    
    // ⭐ 检查是否是 Markdown 格式（包括括号格式）
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
    // 检查常见的 Markdown 标记
    final hasAsterisk = RegExp(r'\*[^*]+\*').hasMatch(content);
    final hasQuote = RegExp(r'"[^"]+"').hasMatch(content);
    final hasParenthesis = RegExp(r'[（(][^）)]+[）)]').hasMatch(content);
    final hasBracket = RegExp(r'【[^】]+】').hasMatch(content);
    
    return hasAsterisk || hasQuote || hasParenthesis || hasBracket;
  }
  
/// 解析内容，返回 (type, content) 对列表
  static List<(String type, String content)> parseContent(String content) {
    final format = detectFormat(content);
    
    // ⭐ 输出详细的调试信息
    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📊 格式检测：$format');
      debugPrint('📝 原始内容（前100字符）：');
      debugPrint(content.length > 100 
          ? '${content.substring(0, 100)}...' 
          : content);
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } // ⭐ 这里缺了这个闭合括号
    
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
  
  /// 解析 Markdown 格式（语C风格优化版）
  /// 核心规则：
  /// 1. 括号内容 → 旁白
  /// 2. 引号内容 → 对话
  /// 3. 括号后第一行（非括号开头）→ 对话
  /// 4. 连续括号 → 都是旁白
  static List<(String, String)> _parseMarkdown(String content) {
    final result = <(String, String)>[];
    final lines = content.split('\n');
    
    String? pendingNarration; // 待处理的旁白（等待下一行判断）
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // ⭐ 规则1：提取所有括号（包括圆括号、全角括号、方括号、【】）
      final parenthesisPatterns = [
        RegExp(r'[（(]([^）)]+)[）)]'),  // （...） 或 (...)
        RegExp(r'\*([^*]+)\*'),          // *...*
        RegExp(r'【([^】]+)】'),          // 【...】
      ];
      
      bool hasParenthesis = false;
      String remainingLine = line;
      
      // 提取所有括号内容作为旁白
      for (final pattern in parenthesisPatterns) {
        final matches = pattern.allMatches(line);
        for (final match in matches) {
          final narrationText = match.group(1)?.trim() ?? '';
          if (narrationText.isNotEmpty) {
            // 如果有待处理的旁白，先输出
            if (pendingNarration != null) {
              result.add(('narration', pendingNarration));
              pendingNarration = null;
            }
            
            result.add(('narration', narrationText));
            hasParenthesis = true;
          }
          
          // 移除已处理的括号内容
          remainingLine = remainingLine.replaceFirst(match.group(0)!, '').trim();
        }
      }
      
      // ⭐ 规则2：提取引号内容作为对话
      final quoteMatch = RegExp(r'"([^"]+)"').firstMatch(remainingLine);
      if (quoteMatch != null) {
        final dialogueText = quoteMatch.group(1)?.trim() ?? '';
        if (dialogueText.isNotEmpty) {
          // 清空待处理的旁白（因为已经有对话了）
          pendingNarration = null;
          result.add(('dialogue', dialogueText));
          continue;
        }
      }
      
      // ⭐ 规则3：括号后的非括号行 → 对话
      if (hasParenthesis && remainingLine.isNotEmpty) {
        // 检查下一行是否是括号开头（连续括号的情况）
        final nextLine = (i + 1 < lines.length) ? lines[i + 1].trim() : '';
        final nextLineStartsWithParenthesis = parenthesisPatterns.any((p) => 
          p.hasMatch(nextLine) && nextLine.startsWith(RegExp(r'[（(*【]'))
        );
        
        if (!nextLineStartsWithParenthesis) {
          // 不是连续括号，当作对话
          result.add(('dialogue', remainingLine));
          pendingNarration = null;
        } else {
          // 是连续括号，标记为待处理旁白
          if (remainingLine.isNotEmpty) {
            pendingNarration = remainingLine;
          }
        }
        continue;
      }
      
      // ⭐ 规则4：其他情况 → 旁白
      if (remainingLine.isNotEmpty) {
        if (pendingNarration != null) {
          result.add(('narration', pendingNarration));
        }
        pendingNarration = remainingLine;
      }
    }
    
    // 处理最后的待处理旁白
    if (pendingNarration != null) {
      result.add(('narration', pendingNarration));
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
    
    // 如果解析结果为空，整体作为旁白
    if (result.isEmpty) {
      return [('narration', content)];
    }
    
    return result;
  }
}

enum MessageFormatType {
  xml,          // XML 格式
  markdown,     // Markdown 格式（*旁白* "对话" 或 （动作）对话）
  taggedLines,  // 【旁白】/【对话】标记行
  plainText,    // 纯文本
  unknown,      // 未知
}