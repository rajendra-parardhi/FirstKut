import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

void downloadFile(String filename, String content) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}

void downloadZip(Map<String, String> files, String zipName) {
  final archive = Archive();
  files.forEach((filename, content) {
    final data = utf8.encode(content);
    archive.addFile(ArchiveFile(filename, data.length, data));
  });

  final zipBytes = ZipEncoder().encode(archive)!;
  final blob = html.Blob([Uint8List.fromList(zipBytes)]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", zipName)
    ..click();

  html.Url.revokeObjectUrl(url);
}
