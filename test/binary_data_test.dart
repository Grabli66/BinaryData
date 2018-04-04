import '../lib/binary_data_lib.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryData', () {
    test('length', () {
      var binData = new BinaryData.fromList([3,4,5,2,1]);
      binData.readUInt8();
      binData.readUInt8();
      expect(binData.length == 5, isTrue);
    });

    test('remain', () {
      var binData = new BinaryData.fromList([3,4,5,2,1,5,4,2,1]);
      binData.readUInt8();
      binData.readUInt8();
      binData.readList();
      expect(binData.remain == 0, isTrue);
    });

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

    test("read/write varint", () {
      final binary = new BinaryData();
      binary.writeVarInt(0x32);
      binary.writeVarInt(-127);
      binary.writeVarInt(0xFF32);
      binary.writeVarInt(-5426);
      binary.writeVarInt(0xFFFF65);
      binary.writeVarInt(-63213);
      binary.writeVarInt(0xFFFFFFFF84);
      binary.writeVarInt(-31237547212);

      binary.setPos(0);

      final eq = const Equality().equals;
      expect(eq(binary.readVarInt(), 0x32), isTrue);
      expect(eq(binary.readVarInt(), -127), isTrue);
      expect(eq(binary.readVarInt(), 0xFF32), isTrue);
      expect(eq(binary.readVarInt(), -5426), isTrue);
      expect(eq(binary.readVarInt(), 0xFFFF65), isTrue);
      expect(eq(binary.readVarInt(), -63213), isTrue);
      expect(eq(binary.readVarInt(), 0xFFFFFFFF84), isTrue);
      expect(eq(binary.readVarInt(), -31237547212), isTrue);
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
