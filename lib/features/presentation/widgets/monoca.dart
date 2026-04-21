import 'dart:convert';
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'dart:html' as html;


class MonacoEditorWidget extends StatefulWidget {
  final String code;

  const MonacoEditorWidget({super.key, required this.code});

  @override
  State<MonacoEditorWidget> createState() => _MonacoEditorWidgetState();
}

class _MonacoEditorWidgetState extends State<MonacoEditorWidget> {
  late final String viewId;
  html.IFrameElement? iframe;

  @override
  void initState() {
    super.initState();

    // ✅ stable id (only once)
    viewId = 'monaco-editor-${DateTime.now().millisecondsSinceEpoch}';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
      iframe = html.IFrameElement()
        ..src = 'editor.html' // ✅ IMPORTANT (not assets/)
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      iframe!.onLoad.listen((event) async {
        // 🔥 wait for Monaco fully ready
        await Future.delayed(const Duration(milliseconds: 300));

        _sendCode(widget.code);
      });

      return iframe!;
    });
  }

  @override
  void didUpdateWidget(covariant MonacoEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔥 update code when changed
    if (oldWidget.code != widget.code) {
      _sendCode(widget.code);
    }
  }

  void _sendCode(String code) {
    iframe?.contentWindow?.postMessage(code, '*');
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewId);
  }
}