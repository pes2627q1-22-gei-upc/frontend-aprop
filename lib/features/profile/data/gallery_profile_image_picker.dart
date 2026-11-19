import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile_avatar.dart';
import '../repositories/profile_image_picker.dart';

class GalleryProfileImagePicker implements ProfileImagePicker {
  GalleryProfileImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<ProfileAvatar?> pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    if (await file.length() > ProfileAvatar.maxBytes) {
      throw const AvatarSelectionException(AvatarProblem.tooBig);
    }
    return ProfileAvatar(bytes: await file.readAsBytes(), filename: file.name);
  }

  @override
  Future<bool> hadInterruptedSelection() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final recovered = await _picker.retrieveLostData();
    // A restarted process may have a different account. Never upload recovered
    // bytes automatically; invite the user to choose the image again.
    return !recovered.isEmpty;
  }
}
