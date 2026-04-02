

import 'package:firstkut/core/theme/app_color.dart';
import 'package:firstkut/features/presentation/bloc/image_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final ImageToTextBloc bloc;

  const CustomDropdown({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final state = bloc.state;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: state.selectedItem,
        hint: const Text("Select Language"),
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down),
        onChanged: (value) => bloc.selectLanguage(value!),
        items: const [
          DropdownMenuItem(value: 'Flutter', child: Text('Flutter')),
          DropdownMenuItem(
              value: 'React Native (JavaScript)',
              child: Text('React Native(js)')),
        ],
      ),
    );
  }
}