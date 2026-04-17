import 'dart:typed_data';
import 'dart:typed_data';

class ImageFileData {
  final String fileName;
  final Uint8List imageData;
  final String? response;
  final Uint8List? responseFileData;

  ImageFileData({
    required this.fileName,
    required this.imageData,
    this.response,
    this.responseFileData,
  });

  // ✅ copyWith method
  ImageFileData copyWith({
    String? fileName,
    Uint8List? imageData,
    String? response,
    Uint8List? responseFileData,
  }) {
    return ImageFileData(
      fileName: fileName ?? this.fileName,
      imageData: imageData ?? this.imageData,
      response: response ?? this.response,
      responseFileData:
      responseFileData ?? this.responseFileData,
    );
  }
}
// class ImageFileData {
//   final String fileName;
//   final Uint8List imageData;
//   String? response;
//   Uint8List? responseFileData;
//
//   ImageFileData({
//     required this.fileName,
//     required this.imageData,
//   });
// }