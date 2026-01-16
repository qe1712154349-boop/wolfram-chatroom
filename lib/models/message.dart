// lib/models/message.dart
import 'dart:convert';

enum MessageType {
  user_narration,    // 用户旁白
  user_dialogue,     // 用户对话
  ai_narration,      // AI旁白
  ai_dialogue,       // AI对话
  system_time,       // 系统时间
  system_state,      // 系统状态
}

class Message {
  final String id;
  final String role; // 'user' 或 'assistant'
  final String timestamp;
  final MessageType messageType;
  
  // 核心：双内容字段
  final String rawContent;     // 原始完整字符串，带XML标签，用于发送给AI
  final String displayContent; // 纯文本，用于UI显示和搜索
  
  Message({
    required this.id,
    required this.role,
    required this.rawContent,
    String? displayContent, // 可选，自动生成
    required this.timestamp,
    required this.messageType,
  }) : displayContent = displayContent ?? _extractDisplayContent(rawContent);

  // 从rawContent提取纯文本显示内容
  static String _extractDisplayContent(String raw) {
    // 尝试解析XML格式
    final startResponse = raw.indexOf('<response>');
    final endResponse = raw.lastIndexOf('</response>');
    
    if (startResponse != -1 && endResponse != -1 && endResponse > startResponse) {
      final responseInner = raw.substring(
        startResponse + '<response>'.length,
        endResponse,
      ).trim();
      
      String extractedText = '';
      
      // 提取environment文本
      final envStart = responseInner.indexOf('<environment>');
      final envEnd = responseInner.indexOf('</environment>');
      if (envStart != -1 && envEnd != -1 && envEnd > envStart) {
        extractedText += responseInner
            .substring(envStart + '<environment>'.length, envEnd)
            .trim();
      }
      
      // 提取dialogue文本
      final diaStart = responseInner.indexOf('<dialogue>');
      final diaEnd = responseInner.indexOf('</dialogue>');
      if (diaStart != -1 && diaEnd != -1 && diaEnd > diaStart) {
        if (extractedText.isNotEmpty) extractedText += ' ';
        extractedText += responseInner
            .substring(diaStart + '<dialogue>'.length, diaEnd)
            .trim();
      }
      
      if (extractedText.isNotEmpty) return extractedText;
    }
    
    // 如果没有XML标签或解析失败，简单清理标签
    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'raw_content': rawContent,      // 存原始XML
      'display_content': displayContent, // 存纯文本
      'timestamp': timestamp,
      'message_type': messageType.name,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    // 兼容旧数据：如果没有raw_content，用content字段
    final rawContent = map['raw_content'] ?? map['content'] ?? '';
    final displayContent = map['display_content'] ?? '';
    
    return Message(
      id: map['id'] as String,
      role: map['role'] as String,
      rawContent: rawContent,
      displayContent: displayContent,
      timestamp: map['timestamp'] as String,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == (map['message_type'] as String?),
        orElse: () => map['role'] == 'user' 
            ? MessageType.user_dialogue 
            : MessageType.ai_dialogue,
      ),
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, role: $role, type: $messageType, raw: ${rawContent.length} chars, display: $displayContent)';
  }
}