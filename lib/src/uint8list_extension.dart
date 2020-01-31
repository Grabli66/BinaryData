import 'dart:typed_data';

/// Extension for Uint8List
extension Uint8ListExtension on Uint8List {
  /// Get UInt8 from list
  int getUint8(int position) {
    return this[position];
  }

  /// Get UInt16 from list
  int getUint16(int position, [Endian endian = Endian.big]) {
    if (endian == Endian.big) {
      return (this[position] << 8) + this[position + 1];
    }

    return (this[position + 1] << 8) + this[position];
  }

  /// Get UInt32 from list
  int getUint32(int position, [Endian endian = Endian.big]) {
    if (endian == Endian.big) {
      return (this[position] << 24) +
          (this[position + 1] << 16) +
          (this[position + 2] << 8) +
          (this[position + 3]);
    }

    return (this[position + 3] << 24) +
        (this[position + 2] << 16) +
        (this[position + 1] << 8) +
        (this[position]);
  }

  /// Get UInt64 from list
  int getUint64(int position, [Endian endian = Endian.big]) {
    if (endian == Endian.big) {
      return (this[position] << 56) +
          (this[position + 1] << 48) +
          (this[position + 2] << 40) +
          (this[position + 3] << 32) +
          (this[position + 4] << 24) +
          (this[position + 5] << 16) +
          (this[position + 6] << 8) +
          (this[position + 7]);
    }

    return (this[position + 7] << 56) +
        (this[position + 6] << 48) +
        (this[position + 5] << 40) +
        (this[position + 4] << 32) +
        (this[position + 3] << 24) +
        (this[position + 2] << 16) +
        (this[position + 1] << 8) +
        (this[position]);
  }

  /// Get DateTime from 4 bytes (seconds from 1970-01-01)
  DateTime getUnixTimeSeconds(int position,
      [bool isUtc = false, Endian endian = Endian.big]) {
    final seconds = this.getUint32(position, endian);
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: isUtc);
  }
}
