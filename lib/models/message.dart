// lib/models/message.dart
import 'package:flutter/foundation.dart';

/// 消息类型枚举 - 严格按照架构约束定义
// 注意：使用下划线命名法以满足架构约束要求
// ignore: constant_identifier_names
enum MessageType {
  // ignore: constant_identifier_names
  user_dialogue,    // 用户对话
  // ignore: constant_identifier_names
  user_narration,   // 用户旁白
  // ignore: constant_identifier_names
  ai_dialogue,      // AI对话
  // ignore: constant_identifier_names
  ai_narration,     // AI旁白
  // ignore: constant_identifier_names
  system_time,      // 系统时间
  // ignore: constant_identifier_names
  system_state,     // 系统状态（仅瞬时UI）
}

/// 聊天消息模型
@immutable
class Message {
  final String id;
  final String role;           // 'user' 或 'assistant'
  final String content;
  final String timestamp;
  final MessageType messageType;  // 核心：显式类型字段
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    required this.messageType,
    this.metadata,
  });

  /// 转换为Map（用于存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp,
      'messageType': messageType.name,
      'metadata': metadata,
    };
  }

  /// 从Map创建
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      role: map['role'] as String? ?? '',
      content: map['content'] as String? ?? '',
      timestamp: map['timestamp'] as String? ?? '',
      messageType: _parseMessageType(map['messageType'] as String?),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 解析消息类型
  static MessageType _parseMessageType(String? typeStr) {
    if (typeStr == null) return MessageType.user_dialogue;
    
    for (final type in MessageType.values) {
      if (type.name == typeStr) return type;
    }
    
    return MessageType.user_dialogue;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, role: $role, type: $messageType, content: ${content.length > 20 ? '${content.substring(0, 20)}...' : content})';
  }
}