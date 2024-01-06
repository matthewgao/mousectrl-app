import 'package:logger/logger.dart';

// class SimpleLogPrinter extends LogPrinter {
//   @override
//   List<String> log(LogEvent event) {
//     // 自定义输出格式，去掉方框
//     return ['${event.level.name}: ${event.message}'];
//   }
// }

final logger = Logger(
    printer: SimplePrinter(printTime: true),
);