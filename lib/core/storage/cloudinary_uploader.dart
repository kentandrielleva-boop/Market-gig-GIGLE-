import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Unsigned image uploads to Cloudinary via stdlib [HttpClient].
///
/// Setup (Cloudinary console):
/// 1. Settings -> Upload -> Upload presets -> Add upload preset.
/// 2. Signing Mode: **Unsigned**. Folder: e.g. `market-gig` (optional).
/// 3. Pass values at run time (no secrets in repo):
///    `flutter run --dart-define=CLOUDINARY_CLOUD_NAME=xxx
///     --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy`
class CloudinaryUploader {
  const CloudinaryUploader({
    required this.cloudName,
    required this.uploadPreset,
  });

  final String cloudName;
  final String uploadPreset;

  /// Uploads [filePath] to `folder/` and returns the `secure_url`.
  /// Already-remote (`http`) URLs pass through unchanged.
  Future<String> uploadImage(String filePath, {required String folder}) async {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw StateError(
        'Cloudinary is not configured. Run with '
        '--dart-define=CLOUDINARY_CLOUD_NAME=xxx '
        '--dart-define=CLOUDINARY_UPLOAD_PRESET=yyy.',
      );
    }
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final filename = p.basename(filePath);

    final boundary =
        '----dart${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      final body = BytesBuilder();
      void field(String name, String value) {
        body.add(
          utf8.encode(
            '--$boundary\r\nContent-Disposition: form-data; name="$name"\r\n\r\n$value\r\n',
          ),
        );
      }

      field('upload_preset', uploadPreset);
      field('folder', folder);
      body.add(
        utf8.encode(
          '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="$filename"\r\n'
          'Content-Type: ${_contentTypeFor(p.extension(filePath))}\r\n\r\n',
        ),
      );
      body.add(bytes);
      body.add(utf8.encode('\r\n--$boundary--\r\n'));

      final payload = body.toBytes();
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );
      request.headers.set(HttpHeaders.contentLengthHeader, payload.length);
      request.add(payload);
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException(
          'Cloudinary upload failed (${response.statusCode}): $text',
        );
      }
      final json = jsonDecode(text) as Map<String, dynamic>;
      final url = json['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw StateError('Cloudinary upload returned no secure_url.');
      }
      return url;
    } finally {
      client.close();
    }
  }

  static String _contentTypeFor(String extension) {
    return switch (extension.toLowerCase()) {
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      '.heic' || '.heif' => 'image/heic',
      _ => 'image/jpeg',
    };
  }
}

/// `--dart-define` config; empty until the user passes real values.
class CloudinaryConfig {
  static const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}
