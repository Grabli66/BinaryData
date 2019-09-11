part of '../binary_data_lib.dart';

/// Reader of data
typedef Object _DataReaderFunc();

/// Task to read data
class _ReadTask {
  /// Size needed
  final int size;

  /// Reader of func
  final _DataReaderFunc readerFunc;

  /// Completer of task
  final Completer<Object> completer;

  /// Constructor
  _ReadTask(this.size, this.readerFunc, this.completer);
}

/// Read binary data from stream async
class BinaryStreamReader {
  /// Stream to read from
  final Stream<int> _stream;

  /// Buffer for data
  final BinaryData _binary = BinaryData();

  /// All readers that awaits of execution
  final List<_ReadTask> _asyncReaders = List<_ReadTask>();

  /// Текущая позиция чтения
  var _currentPos = 0;

  /// Add async task to execute then size is enought
  Future<Object> _addTask(int size, _DataReaderFunc executer) {
    final completer = Completer<Object>();
    _asyncReaders.add(_ReadTask(size, executer, completer));
    return completer.future;
  }

  /// Check if buffer has enougth data
  bool _checkSize(int size) {
    return _currentPos + size <= _binary.length;
  }

  /// Create from stream
  BinaryStreamReader.fromStream(this._stream) {
    _stream.listen((data) {
      _binary.writeUInt8(data);

      if (_asyncReaders.isNotEmpty) {
        final task = _asyncReaders.first;
        if (_checkSize(task.size)) {
          final res = task.readerFunc();
          task.completer.complete(res);
          _asyncReaders.removeAt(0);
        }
      }
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

    return _addTask(size, () {
      return fnc();
    }).then((dynamic x) {
      return x as int;
    });
  }

  /// Async read UInt16
  Future<int> readUInt16() async {
    const size = 2;

    final fnc = () {
      final res = _binary.getUInt16(_currentPos);
      _currentPos += size;
      return res;
    };

    if (_checkSize(size)) {
      return fnc();
    }

    return _addTask(size, () {
      return fnc();
    }).then((dynamic x) {
      return x as int;
    });
  }

  /// Async read UInt32
  Future<int> readUInt32() async {
    const size = 4;

    final fnc = () {
      final res = _binary.getUInt32(_currentPos);
      _currentPos += size;
      return res;
    };

    if (_checkSize(size)) {
      return fnc();
    }

    return _addTask(size, () {
      return fnc();
    }).then((dynamic x) {
      return x as int;
    });
  }
}
