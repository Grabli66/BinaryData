import 'dart:async';

import 'package:binary_data/binary_data_lib.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  group("All tests", () {
    group('BinaryData', () {
      test('length', () {
        var binData = BinaryData.fromList([3, 4, 5, 2, 1]);
        binData.readUInt8();
        binData.readUInt8();
        expect(binData.length == 5, isTrue);
      });

      test('remain', () {
        var binData = BinaryData.fromList([3, 4, 5, 2, 1, 5, 4, 2, 1]);
        binData.readUInt8();
        binData.readUInt8();
        binData.readList();
        expect(binData.remain == 0, isTrue);
      });

      test('fromlist', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        var binData2 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        expect(binData1.toHex() == binData2.toHex(), isTrue);
      });

      test('readList with length', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        binData1.setPos(2);
        var binData2 = binData1.readList(3);
        const listEquality = const ListEquality<int>();
        final eq = listEquality.equals;

        expect(eq(binData2.toList(), [3, 4, 5]), isTrue);
      });

      test('readList to the end', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        binData1.setPos(2);
        var binData2 = binData1.readList();
        final eq = const ListEquality<int>().equals;

        expect(eq(binData2.toList(), [3, 4, 5, 6]), isTrue);
      });

      test('getSlice', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        var binData2 = binData1.getSlice(2, 3);
        final eq = const ListEquality<int>().equals;

        expect(eq(binData2.toList(), [3, 4, 5]), isTrue);
      });

      test('getList', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        var binData2 = binData1.getList();
        final eq = const ListEquality<int>().equals;

        expect(eq(binData2, [1, 2, 3, 4, 5, 6]), isTrue);
      });

      test('getUInt8', () {
        var binData1 = BinaryData.fromList([99, 34, 92]);
        expect(binData1.getUInt8(0), 99);
        expect(binData1.getUInt8(1), 34);
        expect(binData1.getUInt8(2), 92);
      });

      test("read/write varint", () {
        final binary = BinaryData();
        binary.writeVarInt(0x32);
        binary.writeVarInt(-127);
        binary.writeVarInt(0xFF32);
        binary.writeVarInt(-5426);
        binary.writeVarInt(0xFFFF65);
        binary.writeVarInt(-63213);
        binary.writeVarInt(0xFFFFFFFF84);
        binary.writeVarInt(-31237547212);

        binary.setPos(0);

        final eq = const Equality<int>().equals;
        expect(eq(binary.readVarInt(), 0x32), isTrue);
        expect(eq(binary.readVarInt(), -127), isTrue);
        expect(eq(binary.readVarInt(), 0xFF32), isTrue);
        expect(eq(binary.readVarInt(), -5426), isTrue);
        expect(eq(binary.readVarInt(), 0xFFFF65), isTrue);
        expect(eq(binary.readVarInt(), -63213), isTrue);
        expect(eq(binary.readVarInt(), 0xFFFFFFFF84), isTrue);
        expect(eq(binary.readVarInt(), -31237547212), isTrue);
      });

      test("read/write float32", () {
        final binary = BinaryData();
        binary.writeFloat32(45.3);
        binary.setPos(0);
        final eq = const Equality<bool>().equals;
        final val = binary.readFloat32();
        expect(eq(val > 45.29 && val < 45.31, true), isTrue);
      });

      test("read/write float64", () {
        final binary = BinaryData();
        binary.writeFloat32(99.99);
        binary.setPos(0);
        final eq = const Equality<bool>().equals;
        final val = binary.readFloat32();
        expect(eq(val > 99.98 && val < 99.999, true), isTrue);
      });

       test("read/write unix stamp", () {
        final binary = BinaryData();
        final date = DateTime(2019, 9, 25);        
        binary.writeUnixStampSeconds(date);
        binary.setPos(0);
        final rdate = binary.readUnixStampSeconds();
        expect(date == rdate, isTrue);
      });

      test('writeBinaryData', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        var binData2 = BinaryData();
        binData2.writeBinaryData(binData1);

        final eq = const ListEquality<int>().equals;

        expect(eq(binData2.getList(), [1, 2, 3, 4, 5, 6]), isTrue);
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

    group('BinaryStreamReader', () {
      test('read data async', () async {
        final stream = StreamController<int>();
        final reader = BinaryStreamReader(stream.stream);
        Future.delayed(Duration(milliseconds: 1), () {
          // Read UInt8
          stream.add(34);
          stream.add(44);

          // Read UInt16
          stream.add(0x33);
          stream.add(0xFA);

          // Read UInt32
          stream.add(0x12);
          stream.add(0x44);
          stream.add(0xAA);
          stream.add(0x78);

          // Read list
          stream.add(0x49);
          stream.add(0xA5);
          stream.add(0xC8);
          stream.add(0xFF);
        });

        final b1 = await reader.readUInt8();
        final b2 = await reader.readUInt8();
        final u16 = await reader.readUInt16();
        final u32 = await reader.readUInt32();

        final lst = await reader.readList(4);

        expect(b1 == 34, isTrue);
        expect(b2 == 44, isTrue);
        expect(u16 == 0x33FA, isTrue);
        expect(u32 == 0x1244AA78, isTrue);

        final eq = const ListEquality<int>().equals;
        expect(eq(lst, [0x49, 0xA5, 0xC8, 0xFF]), isTrue);
      });
    });
  });
}
