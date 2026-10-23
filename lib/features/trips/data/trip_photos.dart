import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Where a trip photo comes from.
enum TripPhotoSource { gallery, camera }

/// The user refused access to the photos or the camera.
class TripPhotoDenied implements Exception {
  const TripPhotoDenied();
}

/// The picture couldn't be read.
class TripPhotoFailed implements Exception {
  const TripPhotoFailed();
}

/// Picks a photo for the share card. Kept in memory only: never saved with
/// the data, never uploaded.
abstract interface class TripPhotoPicker {
  /// The photo upright, cropped to [aspect] (width / height) when given, or
  /// null when the user cancelled. Throws [TripPhotoDenied] or
  /// [TripPhotoFailed]. Without [aspect] the whole picture is kept, so each
  /// card size can take its own middle part without stretching it.
  Future<Uint8List?> pick(TripPhotoSource source, {double? aspect});
}

final tripPhotoPickerProvider =
    Provider<TripPhotoPicker>((_) => const DeviceTripPhotoPicker());

/// The phone's gallery (the system photo picker: no permission needed) or
/// camera (asked for only then), at most 1080 px wide, quality 80.
class DeviceTripPhotoPicker implements TripPhotoPicker {
  const DeviceTripPhotoPicker();

  @override
  Future<Uint8List?> pick(TripPhotoSource source, {double? aspect}) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source == TripPhotoSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 80,
      );
    } on PlatformException catch (e) {
      throw isDenial(e.code)
          ? const TripPhotoDenied()
          : const TripPhotoFailed();
    }
    if (file == null) return null;
    final Uint8List raw = await file.readAsBytes();
    final Uint8List? out = await compute(cropToAspect, (raw, aspect));
    if (out == null) throw const TripPhotoFailed();
    return out;
  }

  /// image_picker's codes for a refused permission.
  static bool isDenial(String code) =>
      code.contains('access_denied') || code.contains('permission');
}

/// The picture turned upright and, with an [aspect] (width / height), its
/// middle at that shape; as JPEG 80; null when it can't be decoded.
Uint8List? cropToAspect((Uint8List, double?) args) {
  final (Uint8List bytes, double? aspect) = args;
  final img.Image? src = img.decodeImage(bytes);
  if (src == null) return null;
  final img.Image upright = img.bakeOrientation(src);
  if (aspect == null) {
    return Uint8List.fromList(img.encodeJpg(upright, quality: 80));
  }
  int w = upright.width;
  int h = (w / aspect).round();
  if (h > upright.height) {
    h = upright.height;
    w = (h * aspect).round();
  }
  final img.Image cut = img.copyCrop(upright,
      x: (upright.width - w) ~/ 2,
      y: (upright.height - h) ~/ 2,
      width: w,
      height: h);
  return Uint8List.fromList(img.encodeJpg(cut, quality: 80));
}
