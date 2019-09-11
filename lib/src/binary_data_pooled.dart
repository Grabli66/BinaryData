part of '../binary_data_lib.dart';

// Pooled binary data object
class BinaryDataPooled extends BinaryData {
  /// Object pool for BinaryData
  static ListQueue<BinaryDataPooled> _pool = new ListQueue<BinaryDataPooled>();

  /// Factory constructor
  factory BinaryDataPooled() {
    if (_pool.isEmpty) return BinaryDataPooled._internal();

    var res = _pool.removeFirst() ?? BinaryDataPooled._internal();
    res.clear();
    return res;
  }

  /// Create binary data from UInt8List
  factory BinaryDataPooled.fromUInt8List(Uint8List data) {
    if (_pool.isEmpty) return BinaryDataPooled._internalFromList(data);

    var res = _pool.removeFirst();
    if (res == null) {
      res = BinaryDataPooled._internalFromList(data);
      return res;
    }

    res._init(data);
    return res;
  }

  /// Private constructor
  BinaryDataPooled._internal() : super();

  /// Private constructor
  BinaryDataPooled._internalFromList(Uint8List data) : super.fromList(data);

  /// For release object
  void release() {
    _pool.addLast(this);
  }
}
