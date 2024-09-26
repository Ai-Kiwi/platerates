import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../libs/alertSystem.dart';

class RecipeEditor extends StatefulWidget {
  final String recipeData;

  RecipeEditor({
    required this.recipeData,
  });

  @override
  _RecipeEditorState createState() =>
      _RecipeEditorState(recipeData: recipeData);
}

class _RecipeEditorState extends State<RecipeEditor> {
  QuillController _controller = QuillController.basic();
  final String recipeData;
  bool loading = true;
  _RecipeEditorState({
    required this.recipeData,
  });

  @protected
  @mustCallSuper
  void initState() {
    final json = jsonDecode(recipeData);
    _controller.document = Document.fromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: loading == true
            ? SafeArea(
                top: true,
                bottom: true,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        width: double.infinity,
                        height: 50.0,
                        child: ElevatedButton(
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          )),
                          onPressed: () async {
                            //returns result
                            final json = jsonEncode(
                                _controller.document.toDelta().toJson());

                            Navigator.pop(
                              context,
                              json,
                            );
                          },
                          child: const Text(
                            'Save changes',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ),
                    ),
                    QuillSimpleToolbar(
                      controller: _controller,
                      configurations: const QuillSimpleToolbarConfigurations(
                          showUndo: false,
                          showRedo: false,
                          showFontFamily: false,
                          showHeaderStyle: true,
                          showFontSize: false,
                          showSuperscript: false,
                          showAlignmentButtons: false,
                          showBackgroundColorButton: true,
                          showBoldButton: true,
                          showCenterAlignment: false,
                          showInlineCode: false,
                          showSearchButton: false,
                          showJustifyAlignment: false,
                          showClipboardCut: false,
                          showClipboardCopy: false,
                          showClipboardPaste: false,
                          showClearFormat: false,
                          showStrikeThrough: true,
                          showIndent: false,
                          showSubscript: false,
                          showDividers: false,
                          showDirection: false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: QuillEditor.basic(
                          controller: _controller,
                          configurations: const QuillEditorConfigurations(),
                        ),
                      ),
                    )
                  ],
                ))
            : const Center(
                child: CircularProgressIndicator(),
              ));
  }
}

class RecipeViewer extends StatefulWidget {
  final String recipeData;

  RecipeViewer({
    required this.recipeData,
  });

  @override
  _RecipeViewerState createState() =>
      _RecipeViewerState(recipeData: recipeData);
}

class _RecipeViewerState extends State<RecipeViewer> {
  QuillController _controller = QuillController.basic();
  final String recipeData;
  bool loading = true;
  _RecipeViewerState({
    required this.recipeData,
  });

  @protected
  @mustCallSuper
  void initState() {
    final json = jsonDecode(recipeData);
    _controller.document = Document.fromJson(json);
    _controller.readOnly = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: loading == true
            ? SafeArea(
                top: true,
                bottom: true,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        width: double.infinity,
                        height: 50.0,
                        child: ElevatedButton(
                          style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          )),
                          onPressed: () async {
                            //returns result
                            final json = jsonEncode(
                                _controller.document.toDelta().toJson());

                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Close recipe',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: QuillEditor.basic(
                          controller: _controller,
                          configurations: const QuillEditorConfigurations(),
                        ),
                      ),
                    )
                  ],
                ))
            : const Center(
                child: CircularProgressIndicator(),
              ));
  }
}
