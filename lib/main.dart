import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'gemini_service.dart'; // your API handler

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
  bool showEditor = false;
  bool generationStarted = false;
  int _selectedFileIndexForEditor = 0;
  String editorText = '';
  String? folderName;
  final TextEditingController _codeController = TextEditingController();

  final gemini = GeminiVisionService(
      apiKey: "AIzaSyA9DJV8r11A2MgXWgrxgFpZRQSZFByCOuY");

  Future<void> _pickZip() async {
    final result = await FilePicker.platform
        .pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['zip']);
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
      if (!file.isFile) {
        folderName = lowerName.substring(0, lowerName.length - 1);
      } else {
        if (lowerName.endsWith('.png') ||
            lowerName.endsWith('.jpg') ||
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
      showEditor = false;
    });
  }

  Future<void> _generateFromImages() async {
    if (generationStarted) return;
    generationStarted = true;

    setState(() {
      isProcessing = true;
      showEditor = false;
    });

    for (int i = 0; i < imageFiles.length; i++) {
      final img = imageFiles[i];
      try {
        final response = await gemini.analyzeImage(
            img.imageData,
            "Convert this image into clean, structured $selectedItem code. Return ONLY the raw code without markdown or formatting."
        );

        if (selectedItem == "Flutter") {
          extension = ".dart";
        } else if (selectedItem == "Android with kotlin" ||
            selectedItem == "Jetpack Compose") {
          extension = ".kt";
        } else if (selectedItem == "Android with java") {
          extension = ".java";
        } else if (selectedItem == "React Native (Typescript) With CLI") {
          extension = ".tsx";
        } else if (selectedItem == "React Native (JavaScript)") {
          extension = ".js";
        } else {
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
      generationStarted = false;
      if (imageFiles.any((f) => f.response != null)) {
        showEditor = true;
        _selectedFileIndexForEditor = 0;
        _loadEditorWithIndex(_selectedFileIndexForEditor);
      }
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

  void _loadEditorWithIndex(int index) {
    final file = imageFiles[index];
    _codeController.text = file.response ?? '';
    editorText = file.response ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FirstKut'),
        actions: [
          if (zipUploaded && !isProcessing)
            Row(
              children: [
                const Text("Gallery"),
                Switch(
                  value: showEditor,
                  onChanged: (value) {
                    setState(() {
                      showEditor = value;
                      if (showEditor) {
                        _loadEditorWithIndex(_selectedFileIndexForEditor);
                      }
                    });
                  },
                ),
                const Text("Code Editor"),
                const SizedBox(width: 16),
              ],
            ),
        ],
      ),
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
                        onTap: () {
                          setState(() {
                            _selectedFileIndexForEditor = index;
                            _loadEditorWithIndex(index);
                            showEditor = true;
                          });
                        },
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
          Expanded(
            child: isProcessing
                ? const Center(child: CircularProgressIndicator())
                : showEditor
                ? _buildCodeEditorView()
                : _buildReorderableGallery(),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableGallery() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ReorderableGridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: imageFiles.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            final item = imageFiles.removeAt(oldIndex);
            imageFiles.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final file = imageFiles[index];
          return Card(
            key: ValueKey(file.fileName),
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                Positioned.fill(child: Image.memory(file.imageData, fit: BoxFit.fitHeight)),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 22),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.black45),
                    ),
                    onPressed: () {
                      // open an edit dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Edit Image"),
                          content: Image.memory(file.imageData),
                          actions: [
                            TextButton(
                              child: const Text("Close"),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCodeEditorView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DropdownButton<int>(
                value: _selectedFileIndexForEditor,
                items: List.generate(imageFiles.length, (index) {
                  final name = imageFiles[index].fileName.split('.').first + extension;
                  return DropdownMenuItem(value: index, child: Text(name));
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFileIndexForEditor = value;
                      _loadEditorWithIndex(value);
                    });
                  }
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text("Download File"),
                onPressed: () {
                  final file = imageFiles[_selectedFileIndexForEditor];
                  final filename = file.fileName.split('.').first + extension;
                  _downloadFile(filename, file.responseFileData!);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _codeController,
              expands: true,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Generated Code",
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              onChanged: (value) {
                setState(() => editorText = value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
