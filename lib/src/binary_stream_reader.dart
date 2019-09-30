part of '../binary_data_lib.dart';

/// Reader of data
typedef Object _DataReaderFunc();

/// Task to read data
abstract class _ReadTask {
  /// Отсылает ожидающему результат ошибку
  void error(Exception e);
}

/// Task to read number data
class _ReadSizedTask<T> extends _ReadTask {
  /// Size needed
  final int size;

  /// Reader of func
  final _DataReaderFunc readerFunc;

  /// Completer of task
  final Completer<T> completer;

  /// Constructor
  _ReadSizedTask(this.size, this.readerFunc, this.completer);

  /// Отсылает ожидающему результат ошибку
  @override
  void error(Exception e) {
    completer.completeError(e);
  }
}

/// Read binary data from stream async
class BinaryStreamReader {
  /// Stream to read from
  final Stream<Object> _stream;

  /// Buffer for data
  final BinaryData _binary = BinaryData();

  /// All readers that awaits of execution
  final List<_ReadTask> _asyncReaders = List<_ReadTask>();

  /// Текущая позиция чтения
  var _currentPos = 0;

  /// Add async task to execute then size is enought
  Future<T> _addSizedTask<T>(int size, _DataReaderFunc executer) {
    final completer = Completer<T>();
    _asyncReaders.add(_ReadSizedTask<T>(size, executer, completer));
    return completer.future;
  }

  /// Check if buffer has enougth data
  bool _checkSize(int size) {
    return _currentPos + size <= _binary.length;
  }

  /// Create from stream
  BinaryStreamReader(this._stream) {
    _stream.listen((data) {
      if (data is int) {
        _binary.writeUInt8(data);
      } else if (data is List<int>) {
        _binary.writeList(data);
      } else if (data is BinaryData) {
        _binary.writeBinaryData(data);
      } else {
        return;
      }      

      if (_asyncReaders.isNotEmpty) {
        final task = _asyncReaders.first;
        if (task is _ReadSizedTask<int>) {
          if (_checkSize(task.size)) {
            final res = task.readerFunc() as int;
            task.completer.complete(res);
            _asyncReaders.removeAt(0);
          }
        } else if (task is _ReadSizedTask<List<int>>) {
          if (_checkSize(task.size)) {
            final res = task.readerFunc() as List<int>;
            task.completer.complete(res);
            _asyncReaders.removeAt(0);
          }
        }
      }
    }, onError: (Object e) {
      // Завершает все задачи с ошибкой и очищает буффер
      for (var reader in _asyncReaders) {
        reader.error(e as Exception);
        _binary.clear();
      }
      _asyncReaders.clear();
    });
  }

  /// Async read UInt8
  Future<int> readUInt8() async {
    const size = 1;

    final fnc = () {
      final res = _binary.getUInt8(_currentPos);
      _currentPos += size;
      return res;
    };

    if (_checkSize(size)) {
      return fnc();
    }

    return _addSizedTask(size, () {
      return fnc();
    });
  }

  /// Async read UInt16
  Future<int> readUInt16([Endian endian]) async {
    const size = 2;

    final fnc = () {
      final res = _binary.getUInt16(_currentPos, endian);
      _currentPos += size;
      return res;
    };

    if (_checkSize(size)) {
      return fnc();
    }

    return _addSizedTask(size, () {
      return fnc();
    });
  }

  /// Async read UInt32
  Future<int> readUInt32([Endian endian]) async {
    const size = 4;

    final fnc = () {
      final res = _binary.getUInt32(_currentPos, endian);
      _currentPos += size;
      return res;
    };

    if (_checkSize(size)) {
      return fnc();
    }

    return _addSizedTask(size, () {
      return fnc();
    });
  }

  /// Async read list from data
  Future<List<int>> readList(int size) async {
    final fnc = () {
      final res = _binary.getSlice(_currentPos, size);
      _currentPos += size;
      return res;
    };

    if (_checkSize(size)) {
      return fnc();
    }

    return _addSizedTask(size, () {
      return fnc();
    });
  }

  /// Async read string line
  Future<List<int>> readLine() async {
    if (_checkSize(2)) {
      final _resBinary = BinaryData();
      var found = false;
      for (var i = _currentPos; i < _binary.length; i++) {
        final b = _binary.getUInt8(i);
        if (b == 0x0D) {
          continue;
        }

        if (b == 0x0A) {
          found = true;
          break;
        }

        _resBinary.writeUInt8(b);
      }
      if (found) {
        return _resBinary.getList();
      }
    }

    return null;
  }
}
