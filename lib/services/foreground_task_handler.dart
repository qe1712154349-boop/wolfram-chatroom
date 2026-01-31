import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 这个顶层函数必须放在文件最外层（非类内），并且必须有 @pragma
// 这是 FlutterForegroundTask 启动后台 isolate 时会调用的入口
@pragma('vm:entry-point')
void startForegroundTask() {
  FlutterForegroundTask.setTaskHandler(ChatForegroundTaskHandler());
}

// 下面是你的 TaskHandler 实现类，完全不变
class ChatForegroundTaskHandler extends TaskHandler {
  Timer? _heartbeatTimer;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('前台服务启动：$timestamp');

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
      sound: RawResourceAndroidNotificationSound('notification'),
      fullScreenIntent: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '小猫回复了你～',
      content.length > 50 ? '${content.substring(0, 50)}...' : content,
      details,
      payload: '/chat_room',
    );
  }
}
