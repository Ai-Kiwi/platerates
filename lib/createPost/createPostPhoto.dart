import 'package:Toaster/createPost/createPost.dart';
import 'package:Toaster/libs/imageUtils.dart';
import 'package:Toaster/libs/loadScreen.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
        try {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
            'failed loading camera',
            style: TextStyle(fontSize: 20, color: Colors.red),
          )));
        } catch (e) {}
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('failed loading camera',
              style: TextStyle(fontSize: 20, color: Colors.red)),
        ));
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

  Future<List<int>?> _takePicture() async {
    if (!_isCameraReady || _cameraController == null) return null;

    if (_cameraController!.value.isTakingPicture) return null;

    try {
      final image = await _cameraController!.takePicture();
      //print(image);

      return await imageUtils.resizePhoto(await image.readAsBytes());
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
        32; //really hacky work around, as image needs to be sqaure because there is padding on each side.

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
        Visibility(
            visible: kIsWeb,
            child: Column(children: [
              Padding(
                  //closed beta reminder
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                      width: double.infinity,
                      height: 60.0,
                      child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 231, 38, 38),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Center(
                              child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                                "You are using web version, currently the take photo function is buggy.\nto work around this please use the 'Use already captured photo' button below instead",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                )),
                          ))))),
              const SizedBox(height: 16.0),
            ])),
        Container(
            width: double.infinity,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  //photo display area
                  Container(
                    width: size,
                    height: size,
                    child: displayCamera(
                        cameraController: _cameraController,
                        size: size,
                        cameraReady: _isCameraReady,
                        cameras: _cameras),
                  ),
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
                                    borderRadius: BorderRadius.circular(15.0),
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                        'error taking photo',
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.red),
                                      )));
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
                                    borderRadius: BorderRadius.circular(15.0),
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
                ])),
        Padding(
          //use photo present button
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  const XTypeGroup typeGroup = XTypeGroup(
                    label: 'images',
                    extensions: <String>['jpg', 'png'],
                  );

                  XFile? file = await openFile(
                      acceptedTypeGroups: <XTypeGroup>[typeGroup]);

                  final List<int>? imageData =
                      await imageUtils.resizePhoto(await file?.readAsBytes());

                  if (imageData != null) {
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreatePostPage(
                                imageData: imageData,
                              )),
                    );
                  }
                } catch (err) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                    'error taking photo',
                    style: TextStyle(fontSize: 20, color: Colors.red),
                  )));

                  print(err);
                  return null;
                }
              },
              child: const Text(
                'Use already captured photo',
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
      borderRadius: BorderRadius.all(Radius.circular(16)),
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
