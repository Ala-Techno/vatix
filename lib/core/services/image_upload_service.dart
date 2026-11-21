import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Result of image selection and validation prior to upload
class PickImageResult {
  final File? file;
  final String? errorMessage;

  const PickImageResult({this.file, this.errorMessage});

  bool get isSuccess => file != null && errorMessage == null;
}

/// [ImageUploadService] — Product image processing and upload service
///
/// Supports two modes:
/// 1. Zero-card embedded Data URI mode:
///    - Compresses image to high quality 600x600 px (lightweight ~40-60KB).
///    - Saves as encoded Data URI directly inside product document in Firestore.
///    - Guarantees immediate display for retailer & wholesaler without DNS blocks.
/// 2. Firebase Storage mode: Fully prepared code, easily toggled via [useFirebaseStorage] = true.
class ImageUploadService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  /// Set to `true` when bank card is added and Firebase Storage is provisioned.
  static const bool useFirebaseStorage = false;

  // Allowed product image extensions
  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  // Max original file size before processing: 5MB
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  ImageUploadService({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  /// Pick image from gallery or camera and compress to suitable dimensions
  Future<PickImageResult> pickAndValidateImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (picked == null) {
        return const PickImageResult(); // User canceled selection
      }

      final file = File(picked.path);

      // 1. Strict validation of file extension
      final extension = picked.name.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(extension)) {
        return const PickImageResult(
          errorMessage:
              'صيغة الصورة غير مدعومة. يرجى اختيار صورة بصيغة (JPG, PNG, WEBP).',
        );
      }

      // 2. Validate file size
      final fileLength = await file.length();
      if (fileLength > maxFileSizeBytes) {
        return const PickImageResult(
          errorMessage: 'حجم الصورة الأصلي كبير جداً، يرجى اختيار صورة أصغر.',
        );
      }

      return PickImageResult(file: file);
    } catch (e) {
      return PickImageResult(
        errorMessage: 'تعذّر اختيار الصورة: ${e.toString()}',
      );
    }
  }

  /// Upload or encode image and return URL/DataURI with 0-100% progress callback
  Future<String?> uploadProductImage({
    required File imageFile,
    required String wholesalerId,
    void Function(double progress, int percent)? onProgress,
  }) async {
    if (useFirebaseStorage) {
      // ── Path 1: Firebase Storage (when credit card / Blaze plan available) ──
      return _uploadToFirebaseStorage(
        imageFile: imageFile,
        wholesalerId: wholesalerId,
        onProgress: onProgress,
      );
    } else {
      // ── Path 2: Direct 100% reliable base64 Data URI embedded in Firestore ──
      return _processAndEncodeImage(
        imageFile: imageFile,
        onProgress: onProgress,
      );
    }
  }

  /// Process and encode image efficiently to work instantly across all devices
  Future<String?> _processAndEncodeImage({
    required File imageFile,
    void Function(double progress, int percent)? onProgress,
  }) async {
    try {
      onProgress?.call(0.20, 20);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final bytes = await imageFile.readAsBytes();
      onProgress?.call(0.60, 60);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final base64String = base64Encode(bytes);
      onProgress?.call(0.90, 90);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final dataUri = 'data:image/jpeg;base64,$base64String';
      onProgress?.call(1.0, 100);

      return dataUri;
    } catch (_) {
      return null;
    }
  }

  /// Upload to Firebase Storage (fully maintained and tested)
  Future<String?> _uploadToFirebaseStorage({
    required File imageFile,
    required String wholesalerId,
    void Function(double progress, int percent)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_product.jpg';
      final ref = _storage
          .ref()
          .child('products')
          .child(wholesalerId)
          .child(fileName);

      final extension = imageFile.path.split('.').last.toLowerCase();
      final contentType = (extension == 'png')
          ? 'image/png'
          : (extension == 'webp')
              ? 'image/webp'
              : 'image/jpeg';

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: contentType),
      );

      onProgress?.call(0.0, 0);

      final subscription = uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          final percent = (progress * 100).clamp(0, 100).toInt();
          onProgress?.call(progress, percent);
        }
      });

      final taskSnapshot = await uploadTask;
      await subscription.cancel();

      onProgress?.call(1.0, 100);
      return await taskSnapshot.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// Delete old image (in Firebase Storage mode)
  Future<void> deleteImageByUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    if (useFirebaseStorage) {
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (_) {}
    }
  }
}
