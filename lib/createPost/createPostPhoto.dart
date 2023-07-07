import 'dart:io';

import 'package:Toaster/createPost/createPost.dart';
import 'package:Toaster/libs/loadScreen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:image/image.dart' as img;

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(_cameras![0], ResolutionPreset.max);
      try {
        await _cameraController!.initialize().then((_) {
          setState(() {});
        });
      } catch (e) {}
    }
    if (!mounted) return;
    setState(() {
      _isCameraReady = true;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<String> _resizePhoto(String filePath) async {
    try {
      final file = File(filePath);
      var image = img.decodeJpg(File(filePath).readAsBytesSync());
      image = img.copyResize(image!, width: 1080);

      List<int> imgSize = img.findTrim(image);

      image = img.copyCrop(image,
          height: 1080, width: 1080, x: 0, y: (imgSize[3] - 1080) ~/ 2);

      //if there is already a photo remove it
      if (await file.exists()) {
        // If the file exists, delete it
        try {
          await file.delete();
        } catch (e) {
          return "";
        }
      }

      await img.encodeJpgFile(filePath, image, quality: 100);
      return filePath;
    } on Error {
      return "";
    }
  }

  Future<String> _takePicture() async {
    if (!_isCameraReady || _cameraController == null) return "";

    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/';
    await Directory(dirPath).create(recursive: true);
    String filePath = '${dirPath}PostPicture.jpg';
    File pictureFile = File(filePath);

    if (_cameraController!.value.isTakingPicture) return "";

    //if there is already a photo remove it
    if (await pictureFile.exists()) {
      // If the file exists, delete it
      try {
        await pictureFile.delete();
      } catch (e) {
        return "";
      }
    }

    try {
      final image = await _cameraController!.takePicture();

      return await _resizePhoto(image.path);
    } on CameraException {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _cameras == null || _cameras!.isEmpty) {
      return LoadingScreen(toasterLogo: false);
    }

    var size = MediaQuery.of(context).size.width;
    size = size -
        64; //really hacky work around, as image needs to be sqaure because there is padding on each side.

    return Scaffold(
      backgroundColor: Color.fromRGBO(16, 16, 16, 1),
      body: Center(
          child: ListView(children: [
        const Center(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
                child: Text(
                  "Create post",
                  style: TextStyle(color: Colors.white, fontSize: 40),
                ))),
        const Divider(
          color: Color.fromARGB(255, 110, 110, 110),
          thickness: 1.0,
        ),
        const SizedBox(height: 8.0),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
                decoration: BoxDecoration(
                    color: Color.fromARGB(215, 40, 40, 40),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Color.fromARGB(215, 45, 45, 45), width: 3)),
                width: double.infinity,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                          //photo display area
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Container(
                            width: size,
                            height: size,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              child: OverflowBox(
                                alignment: Alignment.center,
                                child: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Container(
                                    width: size,
                                    height: size *
                                        _cameraController!.value.aspectRatio,
                                    child: CameraPreview(_cameraController!),
                                  ),
                                ),
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),
                      Padding(
                        //take photo button
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
                              final imagePath = await _takePicture();

                              if (imagePath.isNotEmpty) {
                                // You can handle the captured image path here, e.g., display it on a new page or save it.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CreatePostPage(
                                            imagePath: imagePath,
                                          )),
                                );
                              } else {
                                Alert(
                                  context: context,
                                  type: AlertType.error,
                                  title: "error taking photo",
                                  desc:
                                      "please contact owner to get this issue fixed.",
                                  buttons: [
                                    DialogButton(
                                      child: Text(
                                        "ok",
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      width: 120,
                                    )
                                  ],
                                ).show();
                              }
                            },
                            child: const Text(
                              'Take photo',
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ])))
      ])),
    );
  }
}
