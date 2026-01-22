import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ChatForegroundTaskHandler extends TaskHandler {
  Timer? _heartbeatTimer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    if (kDebugMode) print('前台服務啟動：$timestamp (由 ${starter.name} 啟動)');

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      FlutterForegroundTask.sendDataToMain({
        'type': 'heartbeat',
        'time': DateTime.now().toIso8601String(),
      });
    });

    FlutterForegroundTask.sendDataToMain({
      'type': 'started',
      'time': timestamp.toIso8601String(),
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 修正：移除了 async、移除了 TaskStarter 参数，改为 void 返回类型
    if (kDebugMode) print('心跳：$timestamp');

    FlutterForegroundTask.sendDataToMain({
      'type': 'tick',
      'time': timestamp.toIso8601String(),
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool wasForceStopped) async {
    if (kDebugMode) print('服務銷毀：$timestamp (強制？ $wasForceStopped)');

    _heartbeatTimer?.cancel();

    FlutterForegroundTask.sendDataToMain({
      'type': 'stopped',
      'time': timestamp.toIso8601String(),
      'force': wasForceStopped,
    });
  }

  @override
  void onNotificationPressed() {
    if (kDebugMode) print('通知被點擊');
    FlutterForegroundTask.sendDataToMain({'type': 'notification_tapped'});
  }

  @override
  void onReceiveData(dynamic data) {
    if (kDebugMode) print('收到 UI 指令：$data');
  }
}