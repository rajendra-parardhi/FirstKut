
import 'package:firstkut/core/theme/app_color.dart';
import 'package:firstkut/features/presentation/bloc/image_bloc.dart';
import 'package:firstkut/features/presentation/widgets/custom.dart';
import 'package:firstkut/features/presentation/widgets/editor.dart';
import 'package:firstkut/features/presentation/widgets/gallery_widget.dart';
import 'package:firstkut/features/presentation/widgets/gradient_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class ImageToTextScreen extends StatelessWidget {
  const ImageToTextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ImageToTextBloc>();
    final state = bloc.state;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: AppColors.textWhite),
            SizedBox(width: 8),
            Text(
              "FirstKut",
              style: TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          if (state.zipUploaded && !state.isProcessing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Gallery",
                      style: TextStyle(color: AppColors.textPrimary), // ✅ FIX
                    ),
                    Switch(
                      value: state.showEditor,
                      activeColor: AppColors.primary, // ✅ FIX
                      inactiveThumbColor: AppColors.primaryLight, // ✅ FIX
                      onChanged: (value) {
                        bloc.state =
                            bloc.state.copyWith(showEditor: value);
                        if (value) bloc.loadEditor(state.selectedIndex);
                        bloc.notifyListeners();
                      },
                    ),
                    const Text(
                      "Editor",
                      style: TextStyle(color: AppColors.textPrimary), // ✅ FIX
                    ),
                  ],
                ),
              ),
            )
        ],
      ),

      body: Row(
        children: [
          // LEFT PANEL
          Container(
            width: 340,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: Offset(2, 0),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Code Generator",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary, // ✅ FIX
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Upload UI images → get clean code",
                  style: TextStyle(
                    color: AppColors.textSecondary, // ✅ FIX
                  ),
                ),
                const SizedBox(height: 20),

                CustomDropdown(bloc: bloc),

                const SizedBox(height: 16),

                if (state.selectedItem != null)
                  GradientButton(
                    icon: Icons.upload,
                    text: "Upload ZIP",
                    colors: const [
                      AppColors.buttonPrimary,
                      AppColors.primaryLight
                    ], // ✅ BLACK BUTTON
                    onTap: bloc.pickZip,
                  ),

                const SizedBox(height: 10),

                if (state.zipUploaded)
                  GradientButton(
                    icon: Icons.auto_awesome,
                    text: "Generate Code",
                    colors: const [
                      AppColors.buttonPrimary,
                      AppColors.primaryLight
                    ], // ✅ BLACK BUTTON
                    onTap: state.isProcessing ? null : bloc.generate,
                  ),

                const SizedBox(height: 20),

                const Text(
                  "Generated Files",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary, // ✅ FIX
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      final grouped = bloc.getGroupedFiles();

                      if (grouped.isEmpty) {
                        return const Center(
                          child: Text(
                            "No files generated yet",
                            style: TextStyle(
                                color: AppColors.textSecondary), // ✅ FIX
                          ),
                        );
                      }

                      return ListView(
                        children: grouped.entries.map((entry) {
                          final folderName = entry.key;
                          final files = entry.value;

                          return Container(
                            margin:
                            const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.folderBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.border), // ✅ ADD BORDER
                            ),
                            child: ExpansionTile(
                              leading: const Icon(Icons.folder,
                                  color: AppColors.primary), // ✅ FIX
                              title: Text(
                                folderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary, // ✅ FIX
                                ),
                              ),
                              children: files.map((file) {
                                final baseName = file.fileName
                                    .split('/')
                                    .last
                                    .split('.')
                                    .first;
                                final fileName =
                                    "$baseName${state.extension}";

                                return ListTile(
                                  contentPadding:
                                  const EdgeInsets.only(left: 40),
                                  leading: const Icon(
                                    Icons.insert_drive_file,
                                    size: 18,
                                    color: AppColors.primaryLight, // ✅ FIX
                                  ),
                                  title: Text(
                                    fileName,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary), // ✅ FIX
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download,
                                        color: AppColors.primary), // ✅ FIX
                                    onPressed: () => bloc.downloadFileAt(
                                      state.imageFiles.indexOf(file),
                                    ),
                                  ),
                                  onTap: () {
                                    final i =
                                    state.imageFiles.indexOf(file);
                                    bloc.loadEditor(i);
                                    bloc.state = bloc.state
                                        .copyWith(showEditor: true);
                                    bloc.notifyListeners();
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                if (state.imageFiles
                    .where((f) => f.responseFileData != null)
                    .isNotEmpty)
                  GradientButton(
                    icon: Icons.archive,
                    text: "Download All",
                    colors: const [
                      AppColors.buttonPrimary,
                      AppColors.primaryLight
                    ], // ✅ BLACK BUTTON
                    onTap: bloc.downloadAll,
                  ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          // RIGHT PANEL
          Expanded(
            child: state.isProcessing
                ? const Center(child: CircularProgressIndicator())
                : state.showEditor
                ? EditorWidget(bloc: bloc)
                : GalleryWidget(bloc: bloc),
          )
        ],
      ),
    );
  }
}
// class ImageToTextScreen extends StatelessWidget {
//   const ImageToTextScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final bloc = context.watch<ImageToTextBloc>();
//     final state = bloc.state;
//
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.gradientStart, AppColors.gradientEnd],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         title: Row(
//           children: const [
//             Icon(Icons.auto_awesome, color: AppColors.textWhite),
//             SizedBox(width: 8),
//             Text(
//               "FirstKut",
//               style: TextStyle(
//                 color: AppColors.textWhite,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           if (state.zipUploaded && !state.isProcessing)
//             Padding(
//               padding: const EdgeInsets.only(right: 12),
//               child: Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                 // decoration: BoxDecoration(
//                 //   color: AppColors.white.withOpacity(0.15),
//                 //   borderRadius: BorderRadius.circular(20),
//                 //   border: Border.all(color: AppColors.borderLight),
//                 // ),
//                 decoration: BoxDecoration(
//                   color: AppColors.white,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: AppColors.border),
//                 ),
//                 child: Row(
//                   children: [
//                     const Text("Gallery",
//                         style: TextStyle(color: AppColors.textWhite)),
//                     Switch(
//                       value: state.showEditor,
//                       activeColor: AppColors.textWhite,
//                       inactiveThumbColor: AppColors.textWhite,
//                       onChanged: (value) {
//                         bloc.state = bloc.state.copyWith(showEditor: value);
//                         if (value) bloc.loadEditor(state.selectedIndex);
//                         bloc.notifyListeners();
//                       },
//                     ),
//                     const Text("Editor",
//                         style: TextStyle(color: AppColors.textWhite)),
//                   ],
//                 ),
//               ),
//             )
//         ],
//       ),
//
//       body: Row(
//         children: [
//           // LEFT PANEL
//           Container(
//             width: 340,
//             padding: const EdgeInsets.all(18),
//             decoration: const BoxDecoration(
//               color: AppColors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.shadowLight,
//                   blurRadius: 10,
//                   offset: Offset(2, 0),
//                 )
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text("AI Code Generator",
//                     style:
//                     TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 6),
//                 Text("Upload UI images → get clean code",
//                     style: TextStyle(color: AppColors.textGrey.shade600)),
//                 const SizedBox(height: 20),
//
//                 CustomDropdown(bloc: bloc),
//
//                 const SizedBox(height: 16),
//
//                 if (state.selectedItem != null)
//                   GradientButton(
//                     icon: Icons.upload,
//                     text: "Upload ZIP",
//                     colors: [AppColors.blue, AppColors.blueAccent],
//                     onTap: bloc.pickZip,
//                   ),
//
//                 const SizedBox(height: 10),
//
//                 if (state.zipUploaded)
//                   GradientButton(
//                     icon: Icons.auto_awesome,
//                     text: "Generate Code",
//                     colors: const [
//                       AppColors.deepPurple,
//                       AppColors.purpleAccent
//                     ],
//                     onTap: state.isProcessing ? null : bloc.generate,
//                   ),
//
//                 const SizedBox(height: 20),
//
//                 const Text("Generated Files",
//                     style:
//                     TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//
//                 const SizedBox(height: 10),
//
//                 Expanded(
//                   child: Builder(
//                     builder: (context) {
//                       final grouped = bloc.getGroupedFiles();
//
//                       if (grouped.isEmpty) {
//                         return const Center(
//                             child: Text("No files generated yet"));
//                       }
//
//                       return ListView(
//                         children: grouped.entries.map((entry) {
//                           final folderName = entry.key;
//                           final files = entry.value;
//
//                           return Container(
//                             margin: const EdgeInsets.symmetric(vertical: 6),
//                             decoration: BoxDecoration(
//                               color: AppColors.folderBg,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: ExpansionTile(
//                               leading: const Icon(Icons.folder,
//                                   color: AppColors.deepPurple),
//                               title: Text(
//                                 folderName,
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.bold),
//                               ),
//                               children: files.map((file) {
//                                 final baseName = file.fileName
//                                     .split('/')
//                                     .last
//                                     .split('.')
//                                     .first;
//                                 final fileName =
//                                     "$baseName${state.extension}";
//
//                                 return ListTile(
//                                   contentPadding:
//                                   const EdgeInsets.only(left: 40),
//                                   leading: const Icon(
//                                       Icons.insert_drive_file,
//                                       size: 18),
//                                   title: Text(fileName),
//                                   trailing: IconButton(
//                                     icon: const Icon(Icons.download),
//                                     onPressed: () => bloc.downloadFileAt(
//                                       state.imageFiles.indexOf(file),
//                                     ),
//                                   ),
//                                   onTap: () {
//                                     final i =
//                                     state.imageFiles.indexOf(file);
//                                     bloc.loadEditor(i);
//                                     bloc.state = bloc.state
//                                         .copyWith(showEditor: true);
//                                     bloc.notifyListeners();
//                                   },
//                                 );
//                               }).toList(),
//                             ),
//                           );
//                         }).toList(),
//                       );
//                     },
//                   ),
//                 ),
//
//                 if (state.imageFiles
//                     .where((f) => f.responseFileData != null)
//                     .isNotEmpty)
//                   GradientButton(
//                     icon: Icons.archive,
//                     text: "Download All",
//                     colors:
//                     const [AppColors.black87, AppColors.black54],
//                     onTap: bloc.downloadAll,
//                   ),
//               ],
//             ),
//           ),
//
//           const VerticalDivider(width: 1),
//
//           // RIGHT PANEL
//           Expanded(
//             child: state.isProcessing
//                 ? const Center(child: CircularProgressIndicator())
//                 : state.showEditor
//                 ? EditorWidget(bloc: bloc)
//                 : GalleryWidget(bloc: bloc),
//           )
//         ],
//       ),
//     );
//   }
//   }
//
