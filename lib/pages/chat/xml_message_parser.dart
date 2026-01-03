// lib/pages/chat/xml_message_parser.dart
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import '../../app/theme.dart'; // 修复导入路径
import 'chat_components.dart'; // 导入新的旁白组件

class XmlMessageParser {
  /// 解析XML消息，返回对应的Widget列表
  static List<Widget> parseXmlMessage({
    required String xmlContent,
    required BuildContext context,
    required String? avatarPath,
    required String characterName,
    bool isAI = true,
    bool showUserAvatar = true,
  }) {
    try {
      final document = xml.XmlDocument.parse(xmlContent);
      final messageElement = document.findElements('message').first;
      final children = messageElement.children
          .whereType<xml.XmlElement>()
          .toList();

      return children.map((node) {
        final text = node.innerText.trim();
        if (node.name.local == 'narration') {
          // 使用新的旁白组件
          return NarrationMessage(
            text: text,
            isAI: isAI,
            isCentered: true, // 旁白默认居中
          );
        } else if (node.name.local == 'dialogue') {
          if (isAI) {
            // AI对话
            return ReceivedMessage(
              text: text,
              avatarPath: avatarPath,
            );
          } else {
            // 用户对话
            return SentMessage(
              text: text,
              userAvatarPath: null, // 用户旁白不显示头像
              showUserAvatar: false,
            );
          }
        } else {
          return _buildDefaultBubble(text, isAI, context);
        }
      }).toList();
    } catch (e) {
      return [_buildDefaultBubble(xmlContent, isAI, context)];
    }
  }

  /// 构建默认气泡（用于解析失败的情况）
  static Widget _buildDefaultBubble(String text, bool isAI, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isAI ? AppTheme.aiBubbleColor : AppTheme.userBubbleColor,
          borderRadius: BorderRadius.circular(AppTheme.bubbleBorderRadius),
          // 移除阴影，使用边框
          border: Border.all(
            color: isAI ? AppTheme.aiBubbleBorder : AppTheme.userBubbleBorder,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: AppTheme.dialogueStyle,
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

  /// 解析用户输入：返回处理后的文本（移除/前缀）
  static String parseUserInputOnlyContent(String input) {
    final trimmedInput = input.trim();
    if (trimmedInput.startsWith('/')) {
      // 移除/前缀，交给上层决定类型
      return trimmedInput.substring(1).trim();
    }
    return trimmedInput;
  }
}