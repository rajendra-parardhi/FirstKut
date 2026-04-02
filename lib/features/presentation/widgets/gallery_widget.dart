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
                borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(file.imageData, fit: BoxFit.fitHeight),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: IconButton(
                    icon: const Icon(Icons.edit,
                        color: AppColors.white, size: 22),
                    style: ButtonStyle(
                      backgroundColor:
                      WidgetStateProperty.all(Colors.black45),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            AlertDialog(
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
}