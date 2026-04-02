import '../../domain/models/image_file_model.dart';

class ImageToTextState {
  String? selectedItem;
  String extension;
  List<ImageFileData> imageFiles;
  bool zipUploaded;
  bool isProcessing;
  bool showEditor;
  bool generationStarted;
  int selectedIndex;
  String editorText;
  String? folderName;

  ImageToTextState({
    this.selectedItem,
    this.extension = ".txt",
    this.imageFiles = const [],
    this.zipUploaded = false,
    this.isProcessing = false,
    this.showEditor = false,
    this.generationStarted = false,
    this.selectedIndex = 0,
    this.editorText = '',
    this.folderName,
  });

  ImageToTextState copyWith({
    String? selectedItem,
    String? extension,
    List<ImageFileData>? imageFiles,
    bool? zipUploaded,
    bool? isProcessing,
    bool? showEditor,
    bool? generationStarted,
    int? selectedIndex,
    String? editorText,
    String? folderName,
  }) {
    return ImageToTextState(
      selectedItem: selectedItem ?? this.selectedItem,
      extension: extension ?? this.extension,
      imageFiles: imageFiles ?? this.imageFiles,
      zipUploaded: zipUploaded ?? this.zipUploaded,
      isProcessing: isProcessing ?? this.isProcessing,
      showEditor: showEditor ?? this.showEditor,
      generationStarted: generationStarted ?? this.generationStarted,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      editorText: editorText ?? this.editorText,
      folderName: folderName ?? this.folderName,
    );
  }
}