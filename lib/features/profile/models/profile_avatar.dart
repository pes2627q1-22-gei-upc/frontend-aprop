class ProfileAvatar {
  ProfileAvatar({required Iterable<int> bytes, required this.filename})
    : bytes = List.unmodifiable(bytes) {
    if (this.bytes.isEmpty || this.bytes.length > maxBytes) {
      throw const AvatarSelectionException('Tria una foto de menys de 5 MB.');
    }
    if (filename.isEmpty || filename.contains('/') || filename.contains('\\')) {
      throw const AvatarSelectionException(
        'No hem pogut llegir el nom de la foto.',
      );
    }
    if (!RegExp(
      r'\.(jpe?g|png|webp)$',
      caseSensitive: false,
    ).hasMatch(filename)) {
      throw const AvatarSelectionException('Tria una foto JPG, PNG o WebP.');
    }
  }
  static const maxBytes = 5 * 1024 * 1024;
  final List<int> bytes;
  final String filename;
}

class AvatarSelectionException implements Exception {
  const AvatarSelectionException(this.message);
  final String message;
}
