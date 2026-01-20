// lib/models/message.dart

// 1. 使用 lowerCamelCase（Dart 官方推荐，解决所有 constant_identifier_names 警告）
enum MessageType {
  userNarration,     // 用户旁白
  userDialogue,      // 用户对话
  aiNarration,       // AI旁白
  aiDialogue,        // AI对话
  systemTime,        // 系统时间
  systemState,       // 系统状态
}

// 2. 桥接 extension：处理 snake_case <-> camelCase 的兼容
extension MessageTypeX on MessageType {
  // 用于保存：新数据直接用 name（camelCase）
  // 但我们不额外存 legacyName，因为我们想让新数据彻底现代化

  // 用于读取：兼容旧的 snake_case 字符串
  static MessageType fromStoredString(String? stored) {
    if (stored == null) {
      return MessageType.aiDialogue; // 默认 fallback
    }

    // 先尝试直接匹配 camelCase（新数据）
    try {
      return MessageType.values.byName(stored);
    } on ArgumentError {
      // 匹配失败 → 尝试 snake_case 兼容映射
      switch (stored) {
        case 'user_narration':
          return MessageType.userNarration;
        case 'user_dialogue':
          return MessageType.userDialogue;
        case 'ai_narration':
          return MessageType.aiNarration;
        case 'ai_dialogue':
          return MessageType.aiDialogue;
        case 'system_time':
          return MessageType.systemTime;
        case 'system_state':
          return MessageType.systemState;
        default:
          // 未知格式 → fallback（可加日志）
          return MessageType.aiDialogue;
      }
    }
  }
}

class Message {
  final String id;
  final String role; // 'user' 或 'assistant'
  final String timestamp;
  final MessageType messageType;

  final String rawContent;     // 原始完整字符串，带XML标签，用于发送给AI
  final String displayContent; // 纯文本，用于UI显示和搜索

  Message({
    required this.id,
    required this.role,
    required this.timestamp,
    required this.messageType,
    required this.rawContent,
    String? displayContent,
  }) : displayContent = displayContent ?? _extractDisplayContent(rawContent);

  static String _extractDisplayContent(String raw) {
    // ... 原有提取逻辑不变 ...
    final startResponse = raw.indexOf('<response>');
    final endResponse = raw.lastIndexOf('</response>');
    
    if (startResponse != -1 && endResponse != -1 && endResponse > startResponse) {
      final responseInner = raw.substring(
        startResponse + '<response>'.length,
        endResponse,
      ).trim();
      
      String extractedText = '';
      
      final envStart = responseInner.indexOf('<environment>');
      final envEnd = responseInner.indexOf('</environment>');
      if (envStart != -1 && envEnd != -1 && envEnd > envStart) {
        extractedText += responseInner
            .substring(envStart + '<environment>'.length, envEnd)
            .trim();
      }
      
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
    
    return raw.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'raw_content': rawContent,
      'display_content': displayContent,
      'timestamp': timestamp,
      // 关键：新数据统一存 camelCase name
      'message_type': messageType.name,
    };
  }

factory Message.fromMap(Map<String, dynamic> map) {
  final rawContent = map['raw_content'] ?? map['content'] ?? '';
  final displayContent = map['display_content'] ?? '';

  // 核心兼容逻辑：使用 fromStoredString 处理 snake_case 和 camelCase
  final storedType = map['message_type'] as String?;
  final messageType = MessageTypeX.fromStoredString(storedType); // 直接调用，移除 ??

  return Message(
    id: map['id'] as String,
    role: map['role'] as String,
    timestamp: map['timestamp'] as String,
    messageType: messageType,
    rawContent: rawContent,
    displayContent: displayContent,
  );
}

  @override
  String toString() {
    return 'Message(id: $id, role: $role, type: $messageType, raw: ${rawContent.length} chars, display: $displayContent)';
  }
}