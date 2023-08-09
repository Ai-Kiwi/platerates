import 'dart:io';

import 'package:Toaster/createPost/createPost.dart';
import 'package:Toaster/libs/loadScreen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  int cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController =
          CameraController(_cameras![cameraIndex], ResolutionPreset.max);
      try {
        await _cameraController!.initialize().then((_) {
          setState(() {});
        });
      } catch (e) {
        Fluttertoast.showToast(
            msg: "failed loading camera",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }
    if (!mounted) return;
    setState(() {
      _isCameraReady = true;
    });
  }

  Future<void> _swapCamera() async {
    _isCameraReady = false;
    cameraIndex += 1;
    setState(() {});
    if (cameraIndex > (_cameras!.length - 1)) {
      cameraIndex = 0;
    }
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController =
          CameraController(_cameras![cameraIndex], ResolutionPreset.max);
      try {
        await _cameraController!.initialize().then((_) {
          setState(() {});
        });
      } catch (e) {
        Fluttertoast.showToast(
            msg: "failed loading camera",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
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

  Future<List<int>?> _resizePhoto(inputImageData) async {
    try {
      var image = img.decodeImage(inputImageData);

      List<int> startImgSize = img.findTrim(image!);

      //test if width or height is more
      if (startImgSize[3] > startImgSize[2]) {
        //image is taller
        image = img.copyResize(image, width: 1080);

        List<int> imgSize = img.findTrim(image);

        image = img.copyCrop(image,
            height: 1080, width: 1080, x: 0, y: (imgSize[3] - 1080) ~/ 2);
      } else {
        //image is wider
        image = img.copyResize(image, height: 1080);

        List<int> imgSize = img.findTrim(image);

        image = img.copyCrop(image,
            height: 1080, width: 1080, x: (imgSize[2] - 1080) ~/ 2, y: 0);
      }

      List<int> finalImgSize = img.findTrim(image);

      if (finalImgSize[3] != 1080 || finalImgSize[2] != 1080) {
        print("photo to low resolstion");
        Fluttertoast.showToast(
            msg: "invalid photo resolstion",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 3,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
        return null;
      }

      final List<int> editedBytes = img.encodeJpg(image, quality: 100);

      return editedBytes;
    } catch (err) {
      print(err);
      return null;
    }
  }

  Future<List<int>?> _takePicture() async {
    if (!_isCameraReady || _cameraController == null) return null;

    if (_cameraController!.value.isTakingPicture) return null;

    try {
      final image = await _cameraController!.takePicture();
      //print(image);

      return await _resizePhoto(await image.readAsBytes());
      //return "e";
      //} on CameraException {
      //  print("camera exception");
      //  return "";
      //}
    } catch (err) {
      print(err);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            child: displayCamera(
                                cameraController: _cameraController,
                                size: size,
                                cameraReady: _isCameraReady,
                                cameras: _cameras),
                          )),
                      const SizedBox(height: 16),
                      Padding(
                        //take photo button
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                            width: double.infinity,
                            height: 50.0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      )),
                                      onPressed: () async {
                                        final imagePath = await _takePicture();

                                        if (imagePath != null) {
                                          // You can handle the captured image path here, e.g., display it on a new page or save it.
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    CreatePostPage(
                                                      imageData: imagePath,
                                                    )),
                                          );
                                        } else {
                                          Alert(
                                            context: context,
                                            type: AlertType.error,
                                            title: "error taking photo",
                                            buttons: [
                                              DialogButton(
                                                child: Text(
                                                  "ok",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20),
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(context),
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
                                SizedBox(width: 8),
                                Container(
                                  width: 50,
                                  height: 50,
                                  child: ElevatedButton(
                                      style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      )),
                                      onPressed: () async {
                                        _swapCamera();
                                      },
                                      child: const Center(
                                        child: Icon(
                                          Icons.switch_camera,
                                          size: 20,
                                        ),
                                      )),
                                ),
                              ],
                            )),
                      ),
                      const SizedBox(height: 16),
                    ]))),
        Padding(
          //take photo button
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
          child: Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              )),
              onPressed: () async {
                try {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();

                  final imageCollected = (result!.files).first;

                  final List<int>? imageData =
                      await _resizePhoto(imageCollected.bytes!);

                  if (imageData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreatePostPage(
                                imageData: imageData!,
                              )),
                    );
                  }
                } catch (err) {
                  Alert(
                    context: context,
                    type: AlertType.error,
                    title: "error taking photo",
                    buttons: [
                      DialogButton(
                        child: Text(
                          "ok",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                        width: 120,
                      )
                    ],
                  ).show();

                  print(err);
                  return null;
                }
              },
              child: const Text(
                'Use local file instead',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ),
        ),
      ])),
    );
  }
}

class displayCamera extends StatelessWidget {
  final cameraController;
  final size;
  final cameraReady;
  final cameras;

  const displayCamera({
    super.key,
    required this.cameraController,
    required this.size,
    required this.cameraReady,
    required this.cameras,
  });

  @override
  Widget build(BuildContext context) {
    if (!cameraReady || cameras == null || cameras!.isEmpty) {
      return LoadingScreen(toasterLogo: false);
    }

    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.fitWidth,
          child: Container(
            width: size,
            height: size * cameraController!.value.aspectRatio,
            child: CameraPreview(cameraController!),
          ),
        ),
      ),
    );
  }
}
