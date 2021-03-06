import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:binary_data/binary_data.dart';

/// Integer type constants
class IntTypes {
  static const Int8 = 0xA1;
  static const Int16 = 0xA2;
  static const Int32 = 0xA3;
  static const Int64 = 0xA4;
  static const UInt8 = 0xA5;
  static const UInt16 = 0xA6;
  static const UInt32 = 0xA7;
  static const UInt64 = 0xA8;
}

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
class BinaryData extends Object with IterableMixin<int> {
  /// Default part size
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

  /// Return current buffer size
  int get bufferSize => _buffer.length;

  /// Prepare size
  void _prepareSize(int wantedSize) {
    if (_buffer.length > _pos + wantedSize) return;

    // Increase size by INCREASE_VALUE
    var len = _buffer.length * INCREASE_VALUE;
    if (len < _buffer.length + wantedSize) len = _buffer.length + wantedSize;

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
    var len = 0;
    while (true) {
      var v = readUInt8();
      if (v & 0x80 > 0) {
        len += v & 0x7F;
      } else {
        len += v;
        break;
      }
    }

    return len;
  }

  /// Init variables
  void _init(Uint8List data) {
    _buffer = data;
    _bytes = _buffer.buffer.asByteData();
    _length = _buffer.length;
    _pos = 0;
  }

  /// Check bounds of position
  void _checkBounds(int pos) {
    if (pos < 0 && pos >= _length)
      throw BinaryDataException("Position out of bounds");
  }

  /// Current length
  int get length => _length;

  /// Remain bytes in binary data
  int get remain => _length - _pos;

  /// Position is on the end of buffer
  bool get isEnd => remain <= 0;

  BinaryData._(int capacity) {
    _init(new Uint8List(capacity));
    _length = 0;
  }

  /// Constructor
  BinaryData() : this._(PART_SIZE);

  /// Create BinaryData from List<int>
  BinaryData.withCapacity(int capacity) : this._(capacity);

  /// Create BinaryData from List<int>
  BinaryData.fromList(List<int> data) {
    var list = new Uint8List.fromList(data);
    _init(list);
  }

  /// Set position to the start
  void toStart() {
    setPos(0);
  }

  /// Set position to the end
  void toEnd() {
    setPos(length);
  }

  /// Clear position and length
  void clear() {
    _pos = 0;
    _length = 0;
  }

  /// Return iterator
  @override
  Iterator<int> get iterator => new LimitedBufferIterator(_buffer, _length);

  /// Convert data to hex string
  String toHex() {
    var sb = new List<String>();
    final buff = getList();
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
    while (value > 0) {
      final b = value & 0x7F;

      if (value > 0x7F) {
        writeUInt8(0xFF);
      } else {
        writeUInt8(b);
      }

      value = value - 0x7F;
    }
  }

  /// Add List<int>
  void writeList(List<int> value) {
    _prepareSize(value.length);
    _buffer.setAll(_pos, value);
    _incPos(value.length);
  }

  /// Add a binary data to this
  void writeBinaryData(BinaryData binary) {
    writeList(binary.getList());
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

  /// Add CR LF to buffer
  void writeCRLF() {
    writeUInt16(0x0D0A);
  }

  /// Write Int8
  void writeInt8(int value) {
    _prepareSize(1);
    _bytes.setInt8(_pos, value);
    _incPos(1);
  }

  /// Write UInt8
  void writeUInt8(int value) {
    _prepareSize(1);
    _bytes.setUint8(_pos, value);
    _incPos(1);
  }

  /// Write Int16
  void writeInt16(int value, [Endian endian = Endian.big]) {
    _prepareSize(2);
    _bytes.setInt16(_pos, value, endian);
    _incPos(2);
  }

  /// Write UInt16
  void writeUInt16(int value, [Endian endian = Endian.big]) {
    _prepareSize(2);
    _bytes.setInt16(_pos, value, endian);
    _incPos(2);
  }

  /// Write Int32
  void writeInt32(int value, [Endian endian = Endian.big]) {
    _prepareSize(4);
    _bytes.setInt32(_pos, value, endian);
    _incPos(4);
  }

  /// Write UInt32
  void writeUInt32(int value, [Endian endian = Endian.big]) {
    _prepareSize(4);
    _bytes.setUint32(_pos, value, endian);
    _incPos(4);
  }

  /// Write Int64
  void writeInt64(int value, [Endian endian = Endian.big]) {
    _prepareSize(8);
    _bytes.setInt64(_pos, value, endian);
    _incPos(8);
  }

  /// Write UInt64
  void writeUInt64(int value, [Endian endian = Endian.big]) {
    _prepareSize(8);
    _bytes.setUint64(_pos, value, endian);
    _incPos(8);
  }

  /// Write Float32
  void writeFloat32(double value, [Endian endian = Endian.big]) {
    _prepareSize(4);
    _bytes.setFloat32(_pos, value, endian);
    _incPos(4);
  }

  /// Write Float64
  void writeFloat64(double value, [Endian endian = Endian.big]) {
    _prepareSize(8);
    _bytes.setFloat64(_pos, value, endian);
    _incPos(8);
  }

  /// Write date as unix stamp seconds
  void writeUnixStampSeconds(DateTime dateTime) {
    final stamp = (dateTime.millisecondsSinceEpoch / 1000).round();
    writeUInt32(stamp);
  }

  /// Write variant size integer
  void writeVarInt(int value, [Endian endian = Endian.big]) {
    /// unsigned int
    if (value >= 0) {
      if (value <= 0xFF) {
        writeUInt8(IntTypes.UInt8);
        writeUInt8(value);
      } else if (value <= 0xFFFF) {
        writeUInt8(IntTypes.UInt16);
        writeUInt16(value);
      } else if (value <= 0xFFFFFFFF) {
        writeUInt8(IntTypes.UInt32);
        writeUInt32(value);
      } else {
        writeUInt8(IntTypes.UInt64);
        writeUInt64(value);
      }
    } else {
      if (value >= -128) {
        writeUInt8(IntTypes.Int8);
        writeInt8(value);
      } else if (value >= -32768) {
        writeUInt8(IntTypes.Int16);
        writeInt16(value);
      } else if (value >= -2147483648) {
        writeUInt8(IntTypes.Int32);
        writeInt32(value);
      } else {
        writeUInt8(IntTypes.Int64);
        writeInt64(value);
      }
    }
  }

  /// Read list from current pos with [length]
  /// If length not assigned then it reads to the end
  Uint8List readList([int length]) {
    var len = _length - _pos;
    if (length != null) {
      len = length;
    }

    final res = getSlice(_pos, len);
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
    if (len < 1) return null;
    return readString(len);
  }

  /// Read Int8 from buffer
  int readInt8() {
    final res = _bytes.getInt8(_pos);
    _incPos(1, false);
    return res;
  }

  /// Read UInt8 from buffer
  int readUInt8() {
    final res = _bytes.getUint8(_pos);
    _incPos(1, false);
    return res;
  }

  /// Read Int16 from buffer
  int readInt16([Endian endian = Endian.big]) {
    final res = _bytes.getInt16(_pos, endian);
    _incPos(2, false);
    return res;
  }

  /// Read UInt16 from buffer
  int readUInt16([Endian endian = Endian.big]) {
    final res = _bytes.getUint16(_pos, endian);
    _incPos(2, false);
    return res;
  }

  /// Read Int32 from buffer
  int readInt32([Endian endian = Endian.big]) {
    final res = _bytes.getInt32(_pos, endian);
    _incPos(4, false);
    return res;
  }

  /// Read UInt32 from buffer
  int readUInt32([Endian endian = Endian.big]) {
    final res = _bytes.getUint32(_pos, endian);
    _incPos(4, false);
    return res;
  }

  /// Read Int64 from buffer
  int readInt64([Endian endian = Endian.big]) {
    final res = _bytes.getInt64(_pos, endian);
    _incPos(8, false);
    return res;
  }

  /// Read UInt64 from buffer
  int readUInt64([Endian endian = Endian.big]) {
    final res = _bytes.getUint64(_pos, endian);
    _incPos(8, false);
    return res;
  }

  /// Read Float32 from buffer
  double readFloat32([Endian endian = Endian.big]) {
    final res = _bytes.getFloat32(_pos, endian);
    _incPos(4);
    return res;
  }

  /// Read Float64 from buffer
  double readFloat64([Endian endian = Endian.big]) {
    final res = _bytes.getFloat64(_pos, endian);
    _incPos(8);
    return res;
  }

  /// Read unix time as 4 byte seconds to DateTime
  DateTime readUnixStampSeconds(
      [bool isUtc = false, Endian endian = Endian.big]) {
    final stamp = readUInt32(endian);
    return DateTime.fromMillisecondsSinceEpoch(stamp * 1000, isUtc: isUtc);
  }

  /// Read variant integer
  int readVarInt([Endian endian = Endian.big]) {
    int intType = readUInt8();
    switch (intType) {
      case IntTypes.Int8:
        return readInt8();
      case IntTypes.Int16:
        return readInt16(endian);
      case IntTypes.Int32:
        return readInt32(endian);
      case IntTypes.Int64:
        return readInt64(endian);
      case IntTypes.UInt8:
        return readUInt8();
      case IntTypes.UInt16:
        return readUInt16(endian);
      case IntTypes.UInt32:
        return readUInt32(endian);
      case IntTypes.UInt64:
        return readUInt64(endian);
    }

    throw new BinaryDataException("Unknown int type");
  }

  /// Get UInt8 from buffer
  int getUInt8(int pos, [Endian endian = Endian.big]) {
    _checkBounds(pos);
    return _bytes.getUint8(pos);
  }

  /// Get UInt16 from buffer
  int getUInt16(int pos, [Endian endian = Endian.big]) {
    _checkBounds(pos + 1);
    return _bytes.getUint16(pos, endian);
  }

  /// Get UInt32 from buffer
  int getUInt32(int pos, [Endian endian = Endian.big]) {
    _checkBounds(pos + 3);
    return _bytes.getUint32(pos, endian);
  }

  /// Get UInt32 from buffer
  int getUInt64(int pos, [Endian endian = Endian.big]) {
    _checkBounds(pos + 7);
    return _bytes.getUint64(pos, endian);
  }

  /// Get all data as copy of list
  Uint8List getList() {
    return _buffer.buffer.asUint8List(0, _length);
  }

  /// Get list from [pos] and [length]
  /// Does not remove data from buffer
  Uint8List getSlice(int pos, int length) {
    return _bytes.buffer.asUint8List(pos, length);
  }

  /// Get UTF-8 string from [pos] of [len]
  String getString(int pos, int len) {
    return utf8.decode(getSlice(pos, len));
  }

  /// Return as string
  @override
  String toString() {
    return utf8.decode(getList());
  }
}
