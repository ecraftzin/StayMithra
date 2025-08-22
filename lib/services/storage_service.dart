import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final SupabaseClient _supabase = supabase;
  final Uuid _uuid = const Uuid();

  // Upload image to Supabase Storage
  Future<String?> uploadImage(File imageFile, String bucket,
      {String? folder}) async {
    try {
      print('Starting image upload to bucket: $bucket, folder: $folder');

      // Generate unique filename
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${_uuid.v4()}.$fileExtension';
      final filePath = folder != null ? '$folder/$fileName' : fileName;

      print('Uploading file: $filePath');
      print('File size: ${await imageFile.length()} bytes');

      // Read file as bytes and upload
      final bytes = await imageFile.readAsBytes();
      print('Read ${bytes.length} bytes from file');

      // Upload file using bytes with upsert option
      await _supabase.storage.from(bucket).uploadBinary(filePath, bytes,
          fileOptions: const FileOptions(upsert: true));

      print('Upload successful for: $filePath');

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);

      print('Generated public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');

      // Try alternative upload method if first fails
      try {
        print('Trying alternative upload method...');
        final fileExtension = imageFile.path.split('.').last.toLowerCase();
        final fileName = '${_uuid.v4()}.$fileExtension';
        final filePath = folder != null ? '$folder/$fileName' : fileName;

        final bytes = await imageFile.readAsBytes();
        await _supabase.storage.from(bucket).uploadBinary(filePath, bytes);

        final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);
        print('Alternative upload successful: $publicUrl');
        return publicUrl;
      } catch (e2) {
        print('Alternative upload also failed: $e2');
        return null;
      }
    }
  }

  // Ensure a specific bucket exists
  Future<void> _ensureBucketExists(String bucketName) async {
    try {
      // Try to get bucket info - if it fails, create it
      await _supabase.storage.getBucket(bucketName);
      print('Bucket $bucketName already exists');
    } catch (e) {
      print('Bucket $bucketName does not exist, creating...');
      try {
        await _supabase.storage.createBucket(bucketName);
        print('Created bucket: $bucketName');
      } catch (createError) {
        print('Error creating bucket $bucketName: $createError');
      }
    }
  }

  // Upload image from XFile (works for both web and mobile)
  Future<String?> uploadImageFromXFile(XFile xFile, String bucket,
      {String? folder}) async {
    try {
      await _ensureBucketExists(bucket);

      // Get file extension from name instead of path to avoid blob URL issues
      String fileExtension = 'jpg'; // default
      if (xFile.name.contains('.')) {
        fileExtension = xFile.name.split('.').last.toLowerCase();
      }

      final fileName = '${_uuid.v4()}.$fileExtension';
      final filePath = folder != null ? '$folder/$fileName' : fileName;

      print('Uploading image: $fileName to path: $filePath');

      // Read file as bytes (works for both web and mobile)
      final bytes = await xFile.readAsBytes();
      print('Image file size: ${bytes.length} bytes');

      // Upload using binary data with file options
      await _supabase.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);
      print('Image upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image from XFile: $e');
      return null;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles, String bucket,
      {String? folder}) async {
    final uploadedUrls = <String>[];

    for (final imageFile in imageFiles) {
      final url = await uploadImage(imageFile, bucket, folder: folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // Delete image from storage
  Future<bool> deleteImage(String bucket, String filePath) async {
    try {
      await _supabase.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Get file path from URL
  String getFilePathFromUrl(String url, String bucket) {
    final bucketUrl =
        'https://rssnqbqbrejnjeiukrdr.supabase.co/storage/v1/object/public/$bucket/';
    if (url.startsWith(bucketUrl)) {
      return url.substring(bucketUrl.length);
    }
    return url;
  }

  // Upload multiple videos
  Future<List<String>> uploadVideos(List<File> videoFiles, String bucket,
      {String? folder}) async {
    final uploadedUrls = <String>[];

    for (final videoFile in videoFiles) {
      final url = await uploadVideo(videoFile, bucket, folder: folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  // Upload video from XFile (works for both web and mobile)
  Future<String?> uploadVideoFromXFile(XFile xFile, String bucket,
      {String? folder}) async {
    try {
      await _ensureBucketExists(bucket);

      // Get file extension from name instead of path to avoid blob URL issues
      String fileExtension = 'mp4'; // default
      if (xFile.name.contains('.')) {
        fileExtension = xFile.name.split('.').last.toLowerCase();
      }

      final fileName = '${_uuid.v4()}.$fileExtension';
      final filePath = folder != null ? '$folder/$fileName' : fileName;

      print('Uploading video: $fileName to path: $filePath');

      // Read file as bytes (works for both web and mobile)
      final bytes = await xFile.readAsBytes();
      print('Video file size: ${bytes.length} bytes');

      // Upload using binary data with file options
      await _supabase.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);
      print('Video upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading video from XFile: $e');
      return null;
    }
  }

  // Upload single video
  Future<String?> uploadVideo(File videoFile, String bucket,
      {String? folder}) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${videoFile.path.split('/').last}';
      final filePath = folder != null ? '$folder/$fileName' : fileName;

      final response =
          await _supabase.storage.from(bucket).upload(filePath, videoFile);

      if (response.isNotEmpty) {
        final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);

        return publicUrl;
      }
      return null;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  // Create storage buckets if they don't exist
  Future<void> createBucketsIfNeeded() async {
    try {
      final buckets = ['posts', 'campaigns', 'avatars'];

      for (final bucketName in buckets) {
        try {
          await _supabase.storage.createBucket(bucketName);
          print('Created bucket: $bucketName');
        } catch (e) {
          // Bucket might already exist, which is fine
          print('Bucket $bucketName might already exist: $e');
        }
      }
    } catch (e) {
      print('Error creating buckets: $e');
    }
  }
}
