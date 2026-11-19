class ProfileAvatar {
  ProfileAvatar({required Iterable<int> bytes, required this.filename})
    : bytes = List.unmodifiable(bytes) {
    if (this.bytes.isEmpty || this.bytes.length > maxBytes) {
      throw const AvatarSelectionException(AvatarProblem.tooBig);
    }
    if (filename.isEmpty || filename.contains('/') || filename.contains('\\')) {
      throw const AvatarSelectionException(AvatarProblem.unreadableName);
    }
    if (!RegExp(
      r'\.(jpe?g|png|webp)$',
      caseSensitive: false,
    ).hasMatch(filename)) {
      throw const AvatarSelectionException(AvatarProblem.wrongFormat);
    }
  }
  static const maxBytes = 5 * 1024 * 1024;
  final List<int> bytes;
  final String filename;
}

enum AvatarProblem { tooBig, unreadableName, wrongFormat }

class AvatarSelectionException implements Exception {
  const AvatarSelectionException(this.problem);
  final AvatarProblem problem;
}
