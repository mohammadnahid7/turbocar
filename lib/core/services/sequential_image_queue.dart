import 'dart:async';
import 'dart:collection';

class StrictSequentialImageQueue {
  static final StrictSequentialImageQueue _instance =
      StrictSequentialImageQueue._internal();
  factory StrictSequentialImageQueue() => _instance;
  StrictSequentialImageQueue._internal();

  final Queue<Completer<void>> _queue = Queue<Completer<void>>();
  bool _isLoading = false;

  Future<void> waitForTurn() async {
    if (!_isLoading && _queue.isEmpty) {
      _isLoading = true;
      return;
    }

    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  void taskCompleted() {
    if (_queue.isNotEmpty) {
      final nextCompleter = _queue.removeFirst();
      nextCompleter.complete();
      _isLoading = true;
    } else {
      _isLoading = false;
    }
  }
}
