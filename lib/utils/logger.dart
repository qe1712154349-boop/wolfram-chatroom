// lib/utils/logger.dart  新建这个文件
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart'; // 包含 kReleaseMode、kDebugMode

final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 8,
    lineLength: 90,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
  level: kReleaseMode ? Level.warning : Level.verbose, // release只输出warning以上
);
