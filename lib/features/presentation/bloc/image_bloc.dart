import 'dart:typed_data';
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

  final gemini = GeminiVisionService(
    apiKey: "AIzaSyDQieDmGQfi8nwcTpHX_mPUwge0kJxASOE", // 🔴 replace
  );

  void selectLanguage(String value) {
    state = state.copyWith(
      selectedItem: value,
      zipUploaded: false,
      imageFiles: [],
    );
    notifyListeners();
  }

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
          images.add(ImageFileData(
          fileName: file.name,
          imageData: Uint8List.fromList(file.content as List<int>),
        ));
      }
    }

    state = state.copyWith(imageFiles: images, zipUploaded: true);
    notifyListeners();
  }


  Future<void> generate() async {
    if (state.imageFiles.isEmpty) return;

    state = state.copyWith(isProcessing: true);
    notifyListeners();

    for (int i = 0; i < state.imageFiles.length; i++) {
      final img = state.imageFiles[i];

      try {
        final res = await gemini.analyzeImage(
          img.imageData,
          "Convert this image into clean ${state.selectedItem} code. Return only raw code.",
        );

        // ✅ extension logic
        String ext = ".txt";
        if (state.selectedItem == "Flutter") ext = ".dart";
        else if (state.selectedItem == "Android with kotlin" ||
            state.selectedItem == "Jetpack Compose") ext = ".kt";
        else if (state.selectedItem == "Android with java") ext = ".java";
        else if (state.selectedItem ==
            "React Native (Typescript) With CLI") ext = ".tsx";
        else if (state.selectedItem == "React Native (JavaScript)") ext = ".js";

        // ✅ IMPORTANT FIX (trigger UI update properly)
        final updatedList = List<ImageFileData>.from(state.imageFiles);
        updatedList[i].response = res;
        updatedList[i].responseFileData =
            Uint8List.fromList(res.codeUnits);

        state = state.copyWith(
          imageFiles: updatedList,
          extension: ext,
        );

        notifyListeners(); // 🔥 VERY IMPORTANT

        // ⏱️ delay (avoid quota burst)
        await Future.delayed(const Duration(seconds: 2));

      } catch (e) {
        final updatedList = List<ImageFileData>.from(state.imageFiles);
        updatedList[i].response = "Error: $e";
        updatedList[i].responseFileData =
            Uint8List.fromList("Error".codeUnits);

        state = state.copyWith(imageFiles: updatedList);
        notifyListeners();

        print("Gemini Error: $e");

        // ⛔ STOP if quota exceeded
        break;
      }
    }

    // ✅ Load first file in editor
    if (state.imageFiles
        .any((f) => f.responseFileData != null)) {
      loadEditor(0);
    }

    state = state.copyWith(
      isProcessing: false,
      showEditor: true,
    );

    notifyListeners();
  }


  void loadEditor(int index) {
    final file = state.imageFiles[index];
    controller.text = file.response ?? '';

    state = state.copyWith(
      selectedIndex: index,
      editorText: file.response ?? '',
    );
  }

  void downloadFileAt(int index) {
    final file = state.imageFiles[index];

    final baseName = file.fileName.split('/').last.split('.').first;
    final name = "$baseName${state.extension}";

    downloadFile(name, file.response ?? '');
  }

  void downloadAll() {
    final files = <String, String>{};

    for (final file in state.imageFiles) {
      if (file.responseFileData == null) continue;

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


  String getProjectPath(String fileName) {
    final baseName = fileName.split('/').last.split('.').first;

    if (state.selectedItem == "Flutter") {
      return "lib/$baseName${state.extension}";
    }

    if (state.selectedItem == "Android with kotlin" ||
        state.selectedItem == "Jetpack Compose") {
      return "app/src/main/java/com/example/app/$baseName${state.extension}";
    }

    if (state.selectedItem == "Android with java") {
      return "app/src/main/java/com/example/app/$baseName${state.extension}";
    }

    if (state.selectedItem!.contains("React Native")) {
      return "src/$baseName${state.extension}";
    }

    return "$baseName${state.extension}";
  }

  Map<String, List<ImageFileData>> getGroupedFiles() {
    final Map<String, List<ImageFileData>> map = {};

    for (var file in state.imageFiles) {
      if (file.responseFileData == null) continue;

      final path = getProjectPath(file.fileName);

      final parts = path.split('/');
      final folder = parts.first; // lib

      map.putIfAbsent(folder, () => []);
      map[folder]!.add(file as ImageFileData);
    }

    return map;
  }
}




