import '../lib/binary_data_lib.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryData', () {
    test('fromlist', () {
      var binData1 = new BinaryData.fromList([1,2,3,4,5,6]);
      var binData2 = new BinaryData.fromList([1,2,3,4,5,6]);
      expect(binData1.toHex() == binData2.toHex(), isTrue);
    });

    test('readList with length', () {
      var binData1 = new BinaryData.fromList([1,2,3,4,5,6]);
      binData1.setPos(2);
      var binData2 = binData1.readList(3);
      final eq = const ListEquality().equals;

      expect(eq(binData2.toList(), [3,4,5]), isTrue);
    });

    test('readList to the end', () {
      var binData1 = new BinaryData.fromList([1,2,3,4,5,6]);
      binData1.setPos(2);
      var binData2 = binData1.readList();
      final eq = const ListEquality().equals;

      expect(eq(binData2.toList(), [3,4,5,6]), isTrue);
    });

    test('getArray', () {
      var binData1 = new BinaryData.fromList([1,2,3,4,5,6]);
      var binData2 = binData1.getArray(2, 3);
      final eq = const ListEquality().equals;

      expect(eq(binData2.toList(), [3,4,5]), isTrue);
    });
  });

  group('BinaryDataPooled', () {
    test('equals', () {
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
