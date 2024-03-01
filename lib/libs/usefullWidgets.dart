import 'package:PlateRates/libs/alertSystem.dart';
import 'package:flutter/material.dart';

class PageBackButton extends StatelessWidget {
  final Widget child;
  final bool active;
  final bool warnDiscardChanges;

  const PageBackButton(
      {required this.child,
      required this.active,
      required this.warnDiscardChanges});

  @override
  Widget build(BuildContext context) {
    return Stack(alignment: Alignment.topLeft, children: <Widget>[
      Align(alignment: Alignment.center, child: child),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: Visibility(
              visible: active,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  if (warnDiscardChanges == true) {
                    openAlert(
                        "yes_or_no",
                        "Discard changes",
                        "Any unsaved changes will be discarded.\nAre you sure you want to continue?",
                        context,
                        {
                          "no": () {
                            Navigator.pop(context);
                          },
                          "yes": () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          }
                        },
                        null);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ))),
    ]);
  }
}
