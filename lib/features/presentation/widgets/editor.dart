import 'package:firstkut/core/theme/app_color.dart';
import 'package:firstkut/features/presentation/bloc/image_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EditorWidget extends StatelessWidget {
  final ImageToTextBloc bloc;

  const EditorWidget({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final state = bloc.state;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  // decoration: BoxDecoration(
                  //   color: const Color(0xffF3F4F8),
                  //   borderRadius: BorderRadius.circular(10),
                  // ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.deepPurple.withOpacity(0.3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: DropdownButton<int>(
                    value: state.selectedIndex,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.deepPurple),
                    items: List.generate(state.imageFiles.length, (index) {
                      final name = state.imageFiles[index]
                          .fileName
                          .split('.')
                          .first +
                          state.extension;
                      return DropdownMenuItem(
                          value: index, child: Text(name));
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        bloc.loadEditor(value);
                        bloc.notifyListeners();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              InkWell(
                onTap: () => bloc.downloadFileAt(state.selectedIndex),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      // colors: [Color(0xff5B2EFF), Color(0xff8F6CFF)],
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.download, color: AppColors.white),
                      SizedBox(width: 8),
                      Text(
                        "Download",
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: bloc.controller,
                expands: true,
                maxLines: null,
                style: const TextStyle(
                    color: AppColors.white, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  bloc.state =
                      bloc.state.copyWith(editorText: value);
                  bloc.notifyListeners();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}