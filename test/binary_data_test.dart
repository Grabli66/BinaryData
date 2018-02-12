import '../lib/binary_data_lib.dart';
import 'package:test/test.dart';

void main() {
  group('Pooled test', () {
    test('Object equals', () {
      var binData1 = new BinaryDataPooled();
      var binData2 = new BinaryDataPooled();

      expect(binData1 == binData2, isFalse);

      var binData3 = new BinaryDataPooled();
      binData3.release();
      var binData4 = new BinaryDataPooled();

      expect(binData3 == binData4, isTrue);
    });
  });
}
