part of '../binary_data_lib.dart';

/// Iterates buffer
class LimitedBufferIterator extends Iterator<int> {  
  /// Some buffer
  Uint8List _buffer;

  /// Length
  int _length;

  /// Current pos
  int _pos;

  /// Constructor
  LimitedBufferIterator(this._buffer, this._length) : _pos = -1;

  /// Get current item
  @override
  int get current => _buffer[_pos];

  /// Move to next item
  @override
  bool moveNext() {
    _pos++;
    if (_pos >= _length) return false;
    return true;
  }
}

///  For working with bytes in memory
///  Functions with read/write prefix are stream like and works with current position
///  Function with set/get prefix uses position as parameter
class BinaryData extends Object with IterableMixin {
  /// Increase part size
  static const PART_SIZE = 100;

  /// Buffer increase ratio
  static const INCREASE_VALUE = 2;

  /// Utf8 codec
  static const Utf8Codec _utf8 = const Utf8Codec();

  /// Buffer
  Uint8List _buffer;

  /// Bytes
  ByteData _bytes;

  /// Length of data
  int _length;

  /// Current pos
  int _pos;

  /// Prepare size
  void _prepareSize(int wantedSize) {
    if (_buffer.length > _pos + wantedSize) 
      return;

    // Increase size by INCREASE_VALUE
    var len = _buffer.length * INCREASE_VALUE;
    if (len < _buffer.length + wantedSize) 
      len = _buffer.length + wantedSize;

    var newBuff = new Uint8List(len);
    newBuff.setAll(0, _buffer);
    _buffer = newBuff;
    _bytes = _buffer.buffer.asByteData();
  }

  /// Inc position and length
  void _incPos(int size, [bool incLength = true]) {
    _pos += size;
    if (_pos > _length) {
      if (incLength) {
        _length += _pos - _length;
      } else {
        _pos = _length;
      }
    }
  }

  /// Read length from buffer
  int _readLength() {
    // TODO: read dynamic length
    return readUInt8();
  }

  /// Init variables
  void _init(Uint8List data) {
    _buffer = data;
    _bytes = _buffer.buffer.asByteData();
    _length = _buffer.length;
    _pos = 0;
  }

  /// Current length
  int get length => _length;

  /// Remain bytes in binary data
  int get remain => _length - _pos;

  /// Constructor
  BinaryData() {
    _init(new Uint8List(PART_SIZE));
    _length = 0;
  }

  /// Clear position and length
  void clear() {
    _pos = 0;
    _length = 0;
  }

  /// Create BinaryData from List<int>
  BinaryData.fromList(List<int> data) {    
    var list = new Uint8List.fromList(data);    
    _init(list);
  }

  /// Return iterator
  @override
  Iterator<int> get iterator => new LimitedBufferIterator(_buffer, _length);

  /// Copy buffer to data
  Uint8List toData() {
    return _buffer.buffer.asUint8List(0, _length);
  }

  /// Convert data to hex string
  String toHex() {
    var sb = new List<String>();
    final buff = toData();
    for (var b in buff) {
      var val = b.toRadixString(16);
      if (val.length < 2) val = "0" + val;
      sb.add(val);
    }

    return sb.join("_");
  }

  /// Set current position
  /// If position more than length
  /// then pos = length
  void setPos(int pos) {
    if (pos > _length) {
      _pos = _length;
    } else {
      _pos = pos;
    }
  }

  /// Add length to buffer
  void writeLength(int value) {
    writeUInt8(value);
  }

  /// Add List<int>
  void writeList(List<int> value) {
    _prepareSize(value.length);
    _buffer.setAll(_pos, value);
    _incPos(value.length);
  }

  /// Add raw UTF-8 string
  void writeString(String value) {
    final arr = _utf8.encode(value);
    writeList(arr);
  }

  /// Add string with length
  void writeStringWithLength(String value) {
    final arr = _utf8.encode(value);
    writeLength(arr.length);
    writeList(arr);
  }

  /// Write UInt8
  void writeUInt8(int value) {
    _prepareSize(1);
    _bytes.setUint8(_pos, value);
    _incPos(1);
  }

  /// Write UInt16
  void writeUInt16(int value, [Endian endian = Endian.big]) {
    _prepareSize(2);
    _bytes.setUint16(_pos, value, endian);
    _incPos(2);
  }

  /// Write UInt32
  void writeUInt32(int value, [Endian endian = Endian.big]) {
    _prepareSize(4);
    _bytes.setUint32(_pos, value, endian);
    _incPos(4);
  }

  /// Write UInt64
  void writeUInt64(int value, [Endian endian = Endian.big]) {
    _prepareSize(8);
    _bytes.setUint64(_pos, value, endian);
    _incPos(8);
  }

  /// Read list from current pos with [length]
  /// If length not assigned then it reads to the end
  Uint8List readList([int length]) {
    var len = _length - _pos;
    if (length != null) {
      len = length;
    }

    final res = getArray(_pos, len);
    _incPos(len, false);
    return res;
  }

  /// Read string from current pos with [length]
  String readString(int length) {
    return utf8.decode(readList(length));
  }

  /// Read string with length
  String readStringWithLength() {
    final len = _readLength();
    if (len < 1)
      return null;
    return readString(len);
  }

  /// Read UInt8 from buffer
  int readUInt8() {
    final res = _bytes.getUint8(_pos);
    _incPos(1, false);
    return res;
  }

  /// Read UInt16 from buffer
  int readUInt16() {
    final res = _bytes.getUint16(_pos);
    _incPos(2, false);
    return res;
  }

  /// Read UInt32 from buffer
  int readUInt32() {
    final res = _bytes.getUint32(_pos);
    _incPos(4, false);
    return res;
  }

  /// Read UInt64 from buffer
  int readUInt64() {
    final res = _bytes.getUint64(_pos);
    _incPos(8, false);
    return res;
  }

  /// Get array from [pos] and [length]
  Uint8List getArray(int pos, int length) {
    return _bytes.buffer.asUint8List(pos, length);
  }
}