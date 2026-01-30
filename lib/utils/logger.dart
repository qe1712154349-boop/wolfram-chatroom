import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 90,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 推荐：时间 + 自启动 ms
    // 如果不要时间：DateTimeFormat.none
  ),
  level: kReleaseMode ? Level.warning : Level.trace,
);
