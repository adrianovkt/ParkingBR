import 'package:flutter/foundation.dart';

class LogService extends ChangeNotifier {
  LogService._internal();
  static final LogService _instance = LogService._internal();
  static LogService get I => _instance;

  final List<String> _buffer = <String>[];
  int maxLines = 500;
  late final void Function(String? message, {int? wrapWidth})
  _originalDebugPrint;

  void init() {
    _originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      _originalDebugPrint(message, wrapWidth: wrapWidth);
      if (message == null) return;
      final ts = DateTime.now().toIso8601String();
      _buffer.add('[$ts] $message');
      if (_buffer.length > maxLines) {
        _buffer.removeRange(0, _buffer.length - maxLines);
      }
      notifyListeners();
    };
  }

  List<String> get logs => List.unmodifiable(_buffer);

  String exportAsText() => _buffer.join('\n');

  void clear() {
    _buffer.clear();
    notifyListeners();
  }
}
