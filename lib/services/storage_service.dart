import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'package:uuid/uuid.dart';

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
