import 'dart:typed_data';

/// Main interface for cross-platform file saving.
/// The actual implementation is determined at compile time by conditional imports.
Future<void> saveFile(Uint8List bytes, String fileName) async {
  // This will be overridden by either web or mobile implementations.
  throw UnsupportedError('Cannot save file without platform-specific implementation.');
}
