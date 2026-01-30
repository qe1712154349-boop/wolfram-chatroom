import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final log = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // 正常日志不打印栈
    errorMethodCount: 8, // 错误时保留 8 层栈
    lineLength: 120, // 加宽一点，适合现代屏幕
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.dateAndTime, // 改成完整日期时间 + 自启动偏移，更易追溯
    // 如果你只想自启动 ms：DateTimeFormat.onlyTimeAndSinceStart
  ),
  level: kReleaseMode ? Level.warning : Level.trace, // trace 在 debug 里全开，超详细
  output: MultiOutput([ConsoleOutput()]), // 可后续加文件输出
);
