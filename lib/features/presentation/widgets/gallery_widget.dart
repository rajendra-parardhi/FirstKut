import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firstkut/core/theme/app_color.dart';
import 'package:firstkut/features/presentation/bloc/image_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class GalleryWidget extends StatelessWidget {
  final ImageToTextBloc bloc;

  const GalleryWidget({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final state = bloc.state;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ReorderableGridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: state.imageFiles.length,
        onReorder: (oldIndex, newIndex) {
          final item = state.imageFiles.removeAt(oldIndex);
          state.imageFiles.insert(newIndex, item);
          bloc.notifyListeners();
        },
        itemBuilder: (context, index) {
          final file = state.imageFiles[index];

          return Card(
            key: ValueKey(file.fileName),
            clipBehavior: Clip.hardEdge,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(
                    file.imageData,
                    fit: BoxFit.fitHeight,
                  ),
                ),

                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: AppColors.white,
                      size: 22,
                    ),
                    style: ButtonStyle(
                      backgroundColor:
                      WidgetStateProperty.all(Colors.black45),
                    ),

                    // 🔥 EDIT DIALOG
                    onPressed: () {
                      final TextEditingController promptController =
                      TextEditingController();

                      Uint8List? newImage;
                      String? newFileName; // ✅ FIX

                      showDialog(
                        context: context,
                        builder: (_) => StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AlertDialog(
                              title: const Text("Edit Image"),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 🔥 SHOW IMAGE
                                    Image.memory(
                                      newImage ?? file.imageData,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),

                                    const SizedBox(height: 10),

                                    // 🔥 PICK IMAGE
                                    ElevatedButton(
                                      onPressed: () async {
                                        final result =
                                        await FilePicker.platform.pickFiles(
                                          type: FileType.image,
                                          withData: true,
                                        );

                                        if (result != null) {
                                          setStateDialog(() {
                                            newImage =
                                                result.files.first.bytes;

                                            // ✅ FIX: capture new filename
                                            newFileName = result
                                                .files.first.name
                                                .replaceAll(
                                              RegExp(r'\.[^/.]+$'),
                                              '',
                                            );
                                          });
                                        }
                                      },
                                      child: const Text("Upload Image"),
                                    ),

                                    const SizedBox(height: 10),

                                    // 🔥 PROMPT
                                    TextField(
                                      controller: promptController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText: "Enter prompt",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              actions: [
                                TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () =>
                                      Navigator.pop(context),
                                ),

                                ElevatedButton(
                                  child: const Text("Apply"),
                                  onPressed: () {
                                    bloc.updateImageWithPrompt(
                                      index: index,
                                      newImage: newImage,
                                      newFileName:
                                      newFileName, // ✅ FIX
                                      prompt: promptController.text,
                                    );

                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          },
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
}