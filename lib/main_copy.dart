import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'gemini_service.dart'; // Assume this is your API handler

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FirstKut',
      theme: ThemeData.light(),
      home: const ImageToTextScreen(),
    );
  }
}

class ImageFileData {
  final String fileName;
  final Uint8List imageData;
  String? response;
  Uint8List? responseFileData;

  ImageFileData({required this.fileName, required this.imageData});
}

class ImageToTextScreen extends StatefulWidget {
  const ImageToTextScreen({super.key});

  @override
  State<ImageToTextScreen> createState() => _ImageToTextScreenState();
}

class _ImageToTextScreenState extends State<ImageToTextScreen> {
  String? selectedItem;
  late String extension;
  List<ImageFileData> imageFiles = [];
  bool zipUploaded = false;
  bool isProcessing = false;
  bool hideGallery = false;
  final gemini = GeminiVisionService(apiKey: "AIzaSyA9DJV8r11A2MgXWgrxgFpZRQSZFByCOuY");
  String? folderName;

  Future<void> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['zip']);
    if (result != null && result.files.isNotEmpty) {
      final zipData = result.files.first.bytes!;
      _extractImagesFromZip(zipData);
    }
  }

  void _extractImagesFromZip(Uint8List zipData) {
    final archive = ZipDecoder().decodeBytes(zipData);
    final imageList = <ImageFileData>[];

    for (final file in archive) {
      final fileName = file.name;
      final lowerName = fileName.toLowerCase();
      if (!file.isFile){
        folderName = lowerName.substring(0,lowerName.length - 1);
      }else {
        if (lowerName.endsWith('.png') || lowerName.endsWith('.jpg') ||
            lowerName.endsWith('.jpeg')) {
          imageList.add(ImageFileData(
            fileName: fileName,
            imageData: Uint8List.fromList(file.content as List<int>),
          ));
        }
      }
    }

    setState(() {
      imageFiles = imageList;
      zipUploaded = true;
      hideGallery = false;
    });
  }

  Future<void> _generateFromImages() async {
    setState(() {
      isProcessing = true;
      hideGallery = false;
    });

    for (int i = 0; i < imageFiles.length; i++) {
      final img = imageFiles[i];
      try {
        final response = await gemini.analyzeImage(
            img.imageData,
            "Convert this image into clean, structured $selectedItem code.Return ONLY the raw code. DO NOT include any markdown formatting like triple backticks (\`\`\`) or language names. The output must start directly with the first line of code."
        );
        if(selectedItem=="Flutter"){
          extension = ".dart";
        }else if(selectedItem=="Android with kotlin"){
          extension = ".kt";
        }else if(selectedItem=="Android with java"){
          extension = ".java";
        }else if(selectedItem=="React Native (Typescript) With CLI"){
          extension = ".tsx";
        }else if(selectedItem=="React Native (Java Script)"){
          extension = ".js";
        }else if(selectedItem=="Jetpack Compose"){
          extension = ".kt";
        }else{
          extension = ".txt";
        }
        final filename = img.fileName.split('.').first + extension;
        final contentBytes = Uint8List.fromList(response.codeUnits);

        setState(() {
          img.response = response;
          img.responseFileData = contentBytes;
        });
      } catch (e) {
        setState(() {
          img.response = 'Error: $e';
          img.responseFileData = Uint8List.fromList('Error: $e'.codeUnits);
        });
      }
    }

    setState(() {
      isProcessing = false;
    });
  }

  void _downloadFile(String fileName, Uint8List data) {
    final blob = html.Blob([data]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _downloadAllAsZip() {
    final archive = Archive();

    for (final file in imageFiles) {
      if (file.responseFileData != null) {
        final filename = file.fileName.split('.').first + extension;
        archive.addFile(ArchiveFile(
          filename,
          file.responseFileData!.length,
          file.responseFileData!,
        ));
      }
    }

    final zippedData = ZipEncoder().encode(archive);
    final blob = html.Blob([zippedData]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "$folderName.zip")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FirstKut')),
      body: Row(
        children: [
          Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  value: selectedItem,
                  hint: const Text("Select Language"),
                  onChanged: (value) {
                    setState(() {
                      selectedItem = value;
                      zipUploaded = false;
                      imageFiles.clear();
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'Flutter', child: Text('Flutter')),
                    DropdownMenuItem(value: 'Android with kotlin', child: Text('Android-Kotlin')),
                    DropdownMenuItem(value: 'Android with java', child: Text('Android-Java')),
                    DropdownMenuItem(value: 'React Native (Typescript) With CLI', child: Text('React Native(ts)')),
                    DropdownMenuItem(value: 'React Native (JavaScript)', child: Text('React Native(js)')),
                    DropdownMenuItem(value: 'Jetpack Compose', child: Text('Jetpack Compose')),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedItem != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Upload ZIP Folder"),
                    onPressed: _pickZip,
                  ),
                const SizedBox(height: 16),
                if (zipUploaded)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Generate"),
                    onPressed: isProcessing ? null : _generateFromImages,
                  ),
                const SizedBox(height: 24),
                const Text("Generated Files:"),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: imageFiles.length,
                    itemBuilder: (context, index) {
                      final file = imageFiles[index];
                      if (file.responseFileData == null) return const SizedBox.shrink();
                      final filename = file.fileName.split('.').first + extension;
                      return ListTile(
                        title: Text(filename),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () => _downloadFile(filename, file.responseFileData!),
                        ),
                      );
                    },
                  ),
                ),
                if (imageFiles.any((f) => f.responseFileData != null))
                  ElevatedButton.icon(
                    icon: const Icon(Icons.archive),
                    label: const Text("Download All"),
                    onPressed: _downloadAllAsZip,
                  ),
              ],
            ),
          ),
          const VerticalDivider(),
          if (!hideGallery)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: imageFiles.length,
                itemBuilder: (context, index) => Image.memory(imageFiles[index].imageData),
              ),
            ),
        ],
      ),
    );
  }
}
