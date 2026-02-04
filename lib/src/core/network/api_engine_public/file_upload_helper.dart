import 'dart:io';
import 'package:dio/dio.dart';

import 'package:path/path.dart' as path;
import 'package:sandwich_ai/src/core/network/api_engine_private/network_exception.dart';
import 'package:sandwich_ai/src/core/network/api_engine_public/api_constants.dart';

class FileUploadHelper {
  static Future<MultipartFile> createMultipartFile(
    String filePath, {
    String? filename,
    String? contentType,
  }) async {
    final file = File(filePath);

    // Check if file exists
    if (!await file.exists()) {
      throw NetworkException.defaultError('File not found: $filePath');
    }

    // Check file size
    final fileSize = await file.length();
    if (fileSize > ApiConstants.maxFileSize) {
      throw NetworkException.defaultError(
        'File size exceeds maximum allowed size (${ApiConstants.maxFileSize} bytes)',
      );
    }

    // Check file extension
    final fileExtension = path.extension(filePath).toLowerCase().substring(1);
    final allowedExtensions = [
      ...ApiConstants.allowedImageFormats,
      ...ApiConstants.allowedDocumentFormats,
    ];

    if (!allowedExtensions.contains(fileExtension)) {
      throw NetworkException.defaultError(
        'File format not supported. Allowed formats: ${allowedExtensions.join(', ')}',
      );
    }

    return MultipartFile.fromFile(
      filePath,
      filename: filename ?? path.basename(filePath),
      contentType: contentType != null ? DioMediaType.parse(contentType) : null,
    );
  }

  static FormData createFormData(Map<String, dynamic> fields) {
    return FormData.fromMap(fields);
  }

  static String getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
