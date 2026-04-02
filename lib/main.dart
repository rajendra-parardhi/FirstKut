
import 'package:firstkut/features/presentation/bloc/image_bloc.dart';
import 'package:firstkut/features/screens/image_to_text_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ImageToTextBloc(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FirstKut',
      theme: ThemeData.light(),
      home: const ImageToTextScreen(),
    );
  }
}
