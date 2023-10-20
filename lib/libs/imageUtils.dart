import 'dart:typed_data';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:image/image.dart' as img;

class _imageUtils {
  Uint8List uintListToBytes(List<int> uintList) {
    final buffer = Uint8List.fromList(uintList);
    final byteData = ByteData.view(buffer.buffer);
    return byteData.buffer.asUint8List();
  }

  Future<List<int>?> resizePhoto(inputImageData) async {
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

        //ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //  content: Text('invalid photo resolstion',
        //      style: TextStyle(fontSize: 20, color: Colors.red)),
        //));
        return null;
      }

      final List<int> editedBytes = img.encodeJpg(image, quality: 100);

      return editedBytes;
    } on Exception catch (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
      print(error);
      return null;
    }
  }
}

_imageUtils imageUtils = _imageUtils();
