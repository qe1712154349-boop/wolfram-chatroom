import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 新增依赖

class ChatForegroundTaskHandler extends TaskHandler {
  Timer? _heartbeatTimer;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('前台服务启动：$timestamp');

    // 初始化 local notifications（用于 HIGH 通知）
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);
    await _notifications.initialize(initSettings);

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      FlutterForegroundTask.sendDataToMain({
        'type': 'heartbeat',
        'time': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 可选：周期性检查或心跳
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool wasForceStopped) async {
    _heartbeatTimer?.cancel();
    debugPrint('服务销毁：$timestamp');
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.sendDataToMain({'type': 'notification_clicked'});
  }

  @override
  void onReceiveData(dynamic data) {
    if (data is Map<String, dynamic> && data['type'] == 'new_message') {
      final content = data['content'] as String? ?? '新消息';
      _showMessageNotification(content);
    }
  }

  Future<void> _showMessageNotification(String content) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'chat_message_channel',
      '聊天新消息',
      channelDescription: 'AI 回复时弹出通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
          'notification'), // res/raw/notification.mp3
      fullScreenIntent: true, // 锁屏全屏意图（可选）
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // 唯一 ID
      '小猫回复了你～',
      content.length > 50 ? '${content.substring(0, 50)}...' : content,
      details,
      payload: '/chat_room', // 点击跳转
    );
  }
}
