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
    if (incLength)
      if (_pos > _length)
        _length += _pos - _length;
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

  /// Create BinaryData from UInt8List
  BinaryData.fromUInt8List(Uint8List data) {
    _init(data);
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
    final arr = UTF8.encode(value);
    writeList(arr);
  }

  /// Add string with length
  void writeStringWithLength(String value) {
    final arr = UTF8.encode(value);
    writeLength(arr.length);
    writeList(arr);
  }

  /// Add UInt8
  void writeUInt8(int value) {
    _prepareSize(1);
    _bytes.setUint8(_pos, value);
    _incPos(1);
  }

  /// Add UInt16
  void writeUInt16(int value) {
    _prepareSize(2);
    _bytes.setUint16(_pos, value);
    _incPos(2);
  }

  /// Add UInt32
  void writeUInt32(int value) {
    _prepareSize(4);
    _bytes.setUint32(_pos, value);
    _incPos(4);
  }

  /// Read array from current pos with [length]
  Uint8List readArray(int length) {
    final res = getArray(_pos, length);
    _incPos(length, false);
    return res;
  }

  /// Read string from current pos with [length]
  String readString(int length) {
    return UTF8.decode(readArray(length));
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

  /// Get array from [pos] and [length]
  Uint8List getArray(int pos, int length) {
    return _bytes.buffer.asUint8List(pos, length);
  }
}