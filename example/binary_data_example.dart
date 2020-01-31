import 'package:binary_data/binary_data.dart';

void main() {
  var binaryData = BinaryData();
  binaryData.writeInt16(44);
  binaryData.writeFloat32(189.3);
  binaryData.setPos(0);

  print(binaryData.readInt16());
  print(binaryData.readFloat32());
}
