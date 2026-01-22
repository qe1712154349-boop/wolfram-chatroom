import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ChatForegroundTaskHandler extends TaskHandler {
  Timer? _heartbeatTimer;

  @override
  Future onStart(DateTime timestamp, TaskStarter starter) async {
    if (kDebugMode) {
      print('前台服務 onStart 被呼叫 - $timestamp (啟動方式: ${starter.name})');
    }

    // 啟動一個簡單的心跳計時器（每 30 秒發一次資料給主 isolate）
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      FlutterForegroundTask.sendDataToMain({
        'type': 'heartbeat',
        'time': DateTime.now().toIso8601String(),
        'status': 'running',
      });
    });

    // 馬上發一條啟動成功的訊息
    FlutterForegroundTask.sendDataToMain({
      'type': 'service_started',
      'time': timestamp.toIso8601String(),
    });
  }

  @override
  Future onRepeatEvent(DateTime timestamp, TaskStarter starter) async {
    // 這是 9.x 版本的心跳主方法（取代舊的 onEvent）
    // 預設每 foregroundTaskOptions.interval 毫秒執行一次（你設 5000ms = 5秒）

    if (kDebugMode) {
      print('心跳 onRepeatEvent @ $timestamp');
    }

    FlutterForegroundTask.sendDataToMain({
      'type': 'repeat_event',
      'time': timestamp.toIso8601String(),
      'interval_ms': 5000,
    });
  }

  @override
  Future onDestroy(DateTime timestamp, bool wasForceStopped) async {
    if (kDebugMode) {
      print('前台服務 onDestroy - $timestamp （是否被系統強制殺掉？ $wasForceStopped）');
    }

    _heartbeatTimer?.cancel();

    FlutterForegroundTask.sendDataToMain({
      'type': 'service_stopped',
      'time': timestamp.toIso8601String(),
      'force_stopped': wasForceStopped,
    });
  }

  @override
  void onNotificationPressed() {
    if (kDebugMode) {
      print('使用者點擊了前台通知');
    }
    // 可以這裡發訊息通知 UI 去打開聊天頁面
    FlutterForegroundTask.sendDataToMain({'type': 'notification_clicked'});
  }

  @override
  void onReceiveData(dynamic data) {
    if (kDebugMode) {
      print('從主程式收到資料：$data');
    }
    // 如果 UI 發指令過來，這裡可以處理（例如 'stop'、'update_title' 等）
  }
}