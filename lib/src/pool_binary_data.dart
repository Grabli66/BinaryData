part of '../binary_data_lib.dart';

/// Pooled binary data object
class PoolBinaryData {
  /// Object pool for BinaryData
  static ObjectPool<PoolBinaryData> _pool = new ObjectPool<PoolBinaryData>(_create);

  /// Function for create object
  static Object _create() => new PoolBinaryData._internal();

  /// Factory constructor
  factory PoolBinaryData() {
    return _pool.getObject();
  }

  /// Private constructor
  PoolBinaryData._internal();

  /// For release object
  void release() {
    _pool.releaseObject(this);
  }
}