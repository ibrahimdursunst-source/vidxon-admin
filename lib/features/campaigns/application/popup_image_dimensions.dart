import 'dart:typed_data';
import 'dart:ui' as ui;

class PopupImagePixelSize {
  const PopupImagePixelSize({required this.width, required this.height});

  final int width;
  final int height;
}

bool looksLikePopupImageBytes(Uint8List bytes) {
  if (bytes.length < 12) return false;
  if (bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return true;
  }
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return true;
  }
  if (bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return true;
  }
  return false;
}

/// Reads pixel size from already-selected local bytes. Failure is non-fatal.
Future<PopupImagePixelSize?> decodePopupImagePixelSize(Uint8List bytes) async {
  if (!looksLikePopupImageBytes(bytes)) {
    return null;
  }
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = PopupImagePixelSize(
      width: frame.image.width,
      height: frame.image.height,
    );
    frame.image.dispose();
    return size;
  } catch (_) {
    return null;
  }
}
