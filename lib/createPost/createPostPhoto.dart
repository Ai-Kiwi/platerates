import 'package:PlateRates/createPost/createPost.dart';
import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/imageUtils.dart';
import 'package:PlateRates/libs/loadScreen.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  int cameraIndex = 0;
  bool _takingPhoto = false;
  var imagesTaken = [];

  @override
  void initState() {
    super.initState();
    if (userManager.loggedIn == true) {
      _initializeCamera();
    }
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
      } on Exception catch (error, stackTrace) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
        try {
          // ignore: use_build_context_synchronously
          openAlert(
              "error", "failed loading camera", "$error", context, null, null);
        } catch (e) {}
      }
    }
    if (!mounted) return;
    if (_cameras != null && _cameras!.isNotEmpty) {
      setState(() {
        _isCameraReady = true;
      });
    } else {
      openAlert("error", "no camera connected", null, context, null, null);
    }
  }

  Future<void> _swapCamera() async {
    if (_isCameraReady == true) {
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
          // ignore: use_build_context_synchronously
          openAlert(
              "error", "failed loading camera", "$e", context, null, null);
        }
      }
      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<List<int>?> _takePicture() async {
    setState(() {
      _takingPhoto = true;
    });

    if (!_isCameraReady || _cameraController == null) return null;

    if (_cameraController!.value.isTakingPicture) return null;

    try {
      final image = await _cameraController!.takePicture();
      //print(image);

      setState(() {
        _takingPhoto = false;
      });
      return await imageUtils.resizePhoto(await image.readAsBytes());
      //return "e";
      //} on CameraException {
      //  print("camera exception");
      //  return "";
      //}
    } catch (err) {
      print(err);
      setState(() {
        _takingPhoto = false;
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userManager.loggedIn == false) {
      print("not logged in");
      return LoginPage();
    }

    if (_takingPhoto == true) {
      return const Scaffold(
          body: Center(
        child: CircularProgressIndicator(),
      ));
    }

    var size = MediaQuery.of(context).size.width;
    size = size -
        32; //really hacky work around, as image needs to be sqaure because there is padding on each side.

    return Scaffold(
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
                  //web verison reminded
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
                    child: SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  )),
                                  onPressed: () async {
                                    final imageTakenData = await _takePicture();

                                    if (imageTakenData != null) {
                                      // ignore: use_build_context_synchronously
                                      setState(() {
                                        imagesTaken.add(imageTakenData);
                                      });
                                    } else {
                                      // ignore: use_build_context_synchronously
                                      openAlert("error", "error loading camera",
                                          null, context, null, null);
                                    }
                                  },
                                  child: const Text(
                                    'Take photo',
                                    style: TextStyle(fontSize: 18.0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
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
          child: SizedBox(
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
                    setState(() {
                      imagesTaken.add(imageData);
                    });
                  }
                } catch (err) {
                  // ignore: use_build_context_synchronously
                  openAlert("error", "error taking photo", "$err", context,
                      null, null);

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
        Visibility(
          visible: imagesTaken.length > 0,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: ListView.builder(
                    itemCount: imagesTaken.length,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      var convertedImageData =
                          Uint8List.fromList(imagesTaken[index]);
                      return Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            child: AspectRatio(
                                aspectRatio: 1,
                                child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Stack(children: [
                                      Align(
                                        alignment: Alignment.center,
                                        child: Image.memory(convertedImageData),
                                      ),
                                      Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  imagesTaken.removeAt(index);
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red,
                                                size: 32,
                                              ))),
                                      Visibility(
                                        visible: index != 0,
                                        child: Align(
                                            alignment: Alignment.topLeft,
                                            child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    var swappingImage =
                                                        imagesTaken[index - 1];
                                                    imagesTaken[index - 1] =
                                                        imagesTaken[index];
                                                    imagesTaken[index] =
                                                        swappingImage;
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.arrow_back,
                                                  color: Colors.grey,
                                                  size: 32,
                                                ))),
                                      ),
                                    ]
                                        //child: Text("e"),
                                        ))),
                          ));
                    },
                  ),
                ),
              ),
              Padding(
                //use photo present button
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    )),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreatePostPage(
                                  imagesData: imagesTaken,
                                )),
                      );
                    },
                    child: const Text(
                      'Upload photos',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  ),
                ),
              ),
            ],
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
      return LoadingScreen(plateRatesLogo: false);
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
