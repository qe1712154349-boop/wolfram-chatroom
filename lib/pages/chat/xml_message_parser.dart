// lib/pages/chat/xml_message_parser.dart
import 'dart:io';  // 添加这行导入
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;

class XmlMessageParser {
  /// 解析XML消息，返回对应的Widget列表
  static List<Widget> parseXmlMessage({
    required String xmlContent,
    required String timestamp,
    required String? avatarPath,
    required String characterName,
    bool isAI = true,
  }) {
    try {
      final document = xml.XmlDocument.parse(xmlContent);
      final messageElement = document.findElements('message').first;
      final children = messageElement.children
          .whereType<xml.XmlElement>()  // 使用 whereType 替代 where
          .toList();

      return children.map((node) {
        final text = node.innerText.trim();  // 使用 innerText 替代 text
        if (node.name.local == 'narration') {
          return _buildNarrationBubble(text);
        } else if (node.name.local == 'dialogue') {
          return _buildDialogueBubble(
            text: text,
            timestamp: timestamp,
            avatarPath: avatarPath,
            characterName: characterName,
            isAI: isAI,
          );
        } else {
          return _buildDefaultBubble(text, isAI);
        }
      }).toList();
    } catch (e) {
      // 如果解析失败，返回默认的消息显示
      return [_buildDefaultBubble(xmlContent, isAI)];
    }
  }

  /// 构建旁白气泡
  static Widget _buildNarrationBubble(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(26),  // 使用 withAlpha 替代 withOpacity
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// 构建对话气泡
  static Widget _buildDialogueBubble({
    required String text,
    required String timestamp,
    required String? avatarPath,
    required String characterName,
    required bool isAI,
  }) {
    if (isAI) {
      // AI的对话气泡（保留头像）
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI头像
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFFD1DC),
              backgroundImage: avatarPath != null
                  ? FileImage(File(avatarPath))  // File 现在可用
                  : null,
              child: avatarPath == null
                  ? const Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            // AI消息气泡
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    characterName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD1DC)),
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 用户的对话气泡（移除头像）
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 用户消息气泡（移除头像后的版本）
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBDEFB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), // 保持一些右边距，让气泡不贴边
          ],
        ),
      );
    }
  }

  /// 构建默认气泡（用于解析失败的情况）
  static Widget _buildDefaultBubble(String text, bool isAI) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAI ? const Color(0xFFFFF0F5) : const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAI ? const Color(0xFFFFD1DC) : const Color(0xFFBBDEFB),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// 判断是否为有效的XML格式
  static bool isValidXml(String content) {
    try {
      xml.XmlDocument.parse(content);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 解析用户输入：如果以/开头则是旁白
  static Map<String, dynamic> parseUserInput(String input) {
    final trimmedInput = input.trim();
    if (trimmedInput.startsWith('/')) {
      // 旁白
      return {
        'type': 'narration',
        'content': trimmedInput.substring(1).trim(),
        'displayText': trimmedInput.substring(1).trim(),
      };
    } else {
      // 普通对话
      return {
        'type': 'dialogue',
        'content': trimmedInput,
        'displayText': trimmedInput,
      };
    }
  }

  /// 创建用户旁白XML
  static String createUserNarrationXml(String text) {
    return '<message><narration>$text</narration></message>';
  }

  /// 创建用户对话XML
  static String createUserDialogueXml(String text) {
    return '<message><dialogue>$text</dialogue></message>';
  }
}