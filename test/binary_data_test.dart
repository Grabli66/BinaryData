import 'dart:async';
import 'dart:typed_data';

import 'package:binary_data/binary_data.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  group("All tests", () {
    group('BinaryData', () {
      test('create with capacity', () {
        var binData = BinaryData.withCapacity(1000);
        expect(binData.bufferSize, 1000);
      });

      test('length', () {
        var binData = BinaryData.fromList([3, 4, 5, 2, 1]);
        binData.readUInt8();
        binData.readUInt8();
        expect(binData.length, 5);
      });

      test('remain', () {
        var binData = BinaryData.fromList([3, 4, 5, 2, 1, 5, 4, 2, 1]);
        binData.readUInt8();
        binData.readUInt8();
        binData.readList();
        expect(binData.remain, 0);
      });

      test('fromlist', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        var binData2 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        expect(binData1.toHex(), binData2.toHex());
      });

      test('readList with length', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        binData1.setPos(2);
        var binData2 = binData1.readList(3);
        const listEquality = const ListEquality<int>();
        final eq = listEquality.equals;

        expect(eq(binData2.toList(), [3, 4, 5]), isTrue);
      });

      test('readStringWithLength', () {
        final binary = BinaryData();
        final str1 = """help - Print help
exit - Disconnect from console server
cc - Create new class
ci - Create new instance of class
cca - Create new attribute for class
cia - Create new attribute for instance""";
        binary.writeStringWithLength(str1);
        binary.toStart();        
        final str2 = binary.readStringWithLength();
        expect(str1, str2);
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

      test("IsEnd", () {
        final binary = BinaryData();
        binary.writeUInt32(146);
        binary.setPos(0);
        binary.readUInt32();

        expect(binary.isEnd, isTrue);
      });

      test('writeBinaryData', () {
        var binData1 = BinaryData.fromList([1, 2, 3, 4, 5, 6]);
        var binData2 = BinaryData();
        binData2.writeBinaryData(binData1);

        final eq = const ListEquality<int>().equals;

        expect(eq(binData2.getList(), [1, 2, 3, 4, 5, 6]), isTrue);
      });
    });

    group('BinaryStreamReader', () {
      test('read data async', () async {
        final stream = StreamController<Object>();
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

          // Add list and by bytes
          stream.add([1, 2, 3]);
        });

        final b1 = await reader.readUInt8();
        final b2 = await reader.readUInt8();
        final u16 = await reader.readUInt16();
        final u32 = await reader.readUInt32();

        final lst1 = await reader.readList(4);

        final bb1 = await reader.readUInt8();
        final bb2 = await reader.readUInt8();
        final bb3 = await reader.readUInt8();

        expect(b1 == 34, isTrue);
        expect(b2 == 44, isTrue);
        expect(u16 == 0x33FA, isTrue);
        expect(u32 == 0x1244AA78, isTrue);

        expect(bb1 == 1, isTrue);
        expect(bb2 == 2, isTrue);
        expect(bb3 == 3, isTrue);

        final eq = const ListEquality<int>().equals;
        expect(eq(lst1, [0x49, 0xA5, 0xC8, 0xFF]), isTrue);
      });
    });

    group('Uint8ListExtension', () {
      test('getUint8', () async {
        final binary = Uint8List.fromList([3, 8, 2]);
        expect(binary.getUint8(0), 3);
        expect(binary.getUint8(1), 8);
        expect(binary.getUint8(2), 2);
      });

      test('getUint16', () async {
        final binary = Uint8List.fromList([0, 2, 0, 5, 9, 0, 20, 40]);
        var bd = BinaryData.fromList(binary);
        expect(binary.getUint16(0), bd.getUInt16(0));
        expect(binary.getUint16(2), bd.getUInt16(2));
        expect(binary.getUint16(4), bd.getUInt16(4));
        expect(binary.getUint16(6), bd.getUInt16(6));

        expect(
            binary.getUint16(0, Endian.little), bd.getUInt16(0, Endian.little));
        expect(
            binary.getUint16(2, Endian.little), bd.getUInt16(2, Endian.little));
        expect(
            binary.getUint16(4, Endian.little), bd.getUInt16(4, Endian.little));
        expect(
            binary.getUint16(6, Endian.little), bd.getUInt16(6, Endian.little));
      });

      test('getUint32', () async {
        final binary = Uint8List.fromList([0, 2, 0, 5, 9, 0, 20, 40]);
        var bd = BinaryData.fromList(binary);
        expect(binary.getUint32(0), bd.getUInt32(0));
        expect(binary.getUint32(4), bd.getUInt32(4));

        expect(
            binary.getUint32(0, Endian.little), bd.getUInt32(0, Endian.little));
        expect(
            binary.getUint32(4, Endian.little), bd.getUInt32(4, Endian.little));
      });

      test('getUint64', () async {
        final binary = Uint8List.fromList([0, 2, 0, 5, 9, 0, 20, 40]);
        var bd = BinaryData.fromList(binary);
        expect(binary.getUint64(0), bd.getUInt64(0));

        expect(
            binary.getUint64(0, Endian.little), bd.getUInt64(0, Endian.little));
      });
    });
  });
}
