import 'dart:typed_data';

class ImageFileData {
  final String fileName;
  final Uint8List imageData;
  String? response;
  Uint8List? responseFileData;

  ImageFileData({
    required this.fileName,
    required this.imageData,
  });
}