import 'dart:typed_data';
import 'dart:html' as html;
import 'package:firstkut/core/utils/file_downloader_web.dart';
import 'package:firstkut/features/presentation/bloc/image_state.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/models/image_file_model.dart';
import '../../data/gemini_service.dart';


class ImageToTextBloc extends ChangeNotifier {

  ImageToTextState state = ImageToTextState();
  final TextEditingController controller = TextEditingController();

  Function()? onApiError;

  final gemini = GeminiVisionService(
    apiKey: "AIzaSyCA0kgxcPDq_I34nA77eFxSb25G9uUzM4k",
  );

  // ---------------- LANGUAGE SELECT ----------------
  void selectLanguage(String value) {
    state = state.copyWith(
      selectedItem: value,
      zipUploaded: false,
      imageFiles: [],
      extension: ".txt",
    );
    notifyListeners();
  }

  // ---------------- PICK ZIP ----------------
  Future<void> pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null) {
      _extractImages(result.files.first.bytes!);
    }
  }

  // ---------------- EXTRACT IMAGES ----------------
  void _extractImages(Uint8List zipData) {
    final archive = ZipDecoder().decodeBytes(zipData);
    final images = <ImageFileData>[];

    for (final file in archive) {
      final name = file.name.toLowerCase();

      if (!file.isFile) {
        state.folderName = name.replaceAll("/", "");
      } else if (name.endsWith('.png') ||
          name.endsWith('.jpg') ||
          name.endsWith('.jpeg')) {
        images.add(
          ImageFileData(
            fileName: file.name,
            imageData: Uint8List.fromList(file.content as List<int>),
          ),
        );
      }
    }

    // 🔥 IMPORTANT: set default extension
    state = state.copyWith(
      imageFiles: images,
      zipUploaded: true,
      extension: ".txt",
    );

    notifyListeners();
  }

  // ---------------- GENERATE CODE ----------------
  Future<void> generate() async {
    if (state.imageFiles.isEmpty) return;

    state = state.copyWith(isProcessing: true);
    notifyListeners();

    for (int i = 0; i < state.imageFiles.length; i++) {
      final img = state.imageFiles[i];

      try {
        final raw = await gemini.analyzeImage(
          img.imageData,
          "Convert this image into clean ${state.selectedItem} code. Do not include markdown. Return only plain code.",
        );

        // 🔥 CLEAN RESPONSE
        String res = raw
            .replaceAll("```dart", "")
            .replaceAll("```kotlin", "")
            .replaceAll("```java", "")
            .replaceAll("```javascript", "")
            .replaceAll("```typescript", "")
            .replaceAll("```", "")
            .trim();

        if (res.isEmpty) {
          res = "// No code generated";
        }

        // ---------------- EXTENSION ----------------
        String ext = ".txt";
        if (state.selectedItem == "Flutter") ext = ".dart";
        else if (state.selectedItem == "Android with kotlin" ||
            state.selectedItem == "Jetpack Compose") ext = ".kt";
        else if (state.selectedItem == "Android with java") ext = ".java";
        else if (state.selectedItem ==
            "React Native (Typescript) With CLI") ext = ".tsx";
        else if (state.selectedItem == "React Native (JavaScript)")
          ext = ".js";

        final updatedList = List<ImageFileData>.from(state.imageFiles);

        updatedList[i] = updatedList[i].copyWith(
          response: res,
          responseFileData: Uint8List.fromList(res.codeUnits),
        );

        state = state.copyWith(
          imageFiles: updatedList,
          extension: ext,
        );

        notifyListeners();

        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
      //   final updatedList = List<ImageFileData>.from(state.imageFiles);
      //
      //   updatedList[i] = updatedList[i].copyWith(
      //     response: "Error: $e",
      //     responseFileData: Uint8List.fromList("Error".codeUnits),
      //   );
      //
      //   state = state.copyWith(imageFiles: updatedList);
      //   notifyListeners();
      //
      //   break;
      // }

        state = state.copyWith(isProcessing: false);
        notifyListeners();

        // 🔥 trigger popup
        if (onApiError != null) {
          onApiError!();
        }

        return; // stop execution
      }
    }

    // 🔥 LOAD FIRST FILE
    if (state.imageFiles.any((f) => f.response != null)) {
      loadEditor(0);
    }

    state = state.copyWith(
      isProcessing: false,
      showEditor: true,
    );

    notifyListeners();
  }

  // ---------------- LOAD EDITOR ----------------
  void loadEditor(int index) {
    final file = state.imageFiles[index];

    controller.text = file.response ?? '';

    state = state.copyWith(
      selectedIndex: index,
      editorText: file.response ?? '',
    );

    notifyListeners();
  }

  // ---------------- DOWNLOAD SINGLE ----------------
  void downloadFileAt(int index) {
    final file = state.imageFiles[index];

    final baseName = file.fileName
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[^/.]+$'), '');

    final name = "$baseName${state.extension}";

    downloadFile(name, file.response ?? '');
  }

  // ---------------- DOWNLOAD ALL ----------------
  void downloadAll() {
    final files = <String, String>{};

    for (final file in state.imageFiles) {
      final path = getProjectPath(file.fileName);

      files[path] = file.response ?? '';
    }

    String projectName = "project";

    if (state.selectedItem == "Flutter") {
      projectName = "flutter_project";
    } else if (state.selectedItem == "Android with kotlin" ||
        state.selectedItem == "Android with java" ||
        state.selectedItem == "Jetpack Compose") {
      projectName = "android_project";
    } else if (state.selectedItem!.contains("React Native")) {
      projectName = "react_native_project";
    }

    downloadZip(files, projectName);
  }

  // ---------------- PATH FIX ----------------
  String getProjectPath(String fileName) {
    final baseName = fileName
        .split('/')
        .last
        .replaceAll(RegExp(r'\.[^/.]+$'), '');

    if (state.selectedItem == "Flutter") {
      return "lib/$baseName${state.extension}";
    }

    if (state.selectedItem == "Android with kotlin" ||
        state.selectedItem == "Jetpack Compose" ||
        state.selectedItem == "Android with java") {
      return "app/src/main/java/com/example/app/$baseName${state.extension}";
    }

    if (state.selectedItem!.contains("React Native")) {
      return "src/$baseName${state.extension}";
    }

    return "$baseName${state.extension}";
  }

  // ---------------- GROUP FILES (🔥 FIXED) ----------------
  Map<String, List<ImageFileData>> getGroupedFiles() {
    final Map<String, List<ImageFileData>> map = {};

    for (var file in state.imageFiles) {
      final path = getProjectPath(file.fileName);
      final folder = path.split('/').first;

      map.putIfAbsent(folder, () => []);
      map[folder]!.add(file as ImageFileData);
    }

    return map;
  }

  // ---------------- DISPLAY NAME (🔥 NEW) ----------------
  String getDisplayName(ImageFileData file) {
    final baseName = file.fileName.split('/').last;

    // before generate → original name
    if (file.response == null) return baseName;

    // after generate → replace extension
    return baseName.replaceAll(RegExp(r'\.[^/.]+$'), '') +
        state.extension;
  }

  void updateImageWithPrompt({
    required int index,
    Uint8List? newImage,
    String? newFileName,
    String? prompt,
  }) {
    final updatedList = List<ImageFileData>.from(state.imageFiles);

    final old = updatedList[index];

    updatedList[index] = old.copyWith(
      imageData: newImage ?? old.imageData,
      fileName: newFileName ?? old.fileName, // ✅ CRITICAL FIX
      response: prompt?.isNotEmpty == true ? prompt : old.response,
    );

    state = state.copyWith(imageFiles: updatedList);

    notifyListeners();
  }
}







