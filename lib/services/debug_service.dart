import 'package:staymitra/config/supabase_config.dart';

class DebugService {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  final _supabase = supabase;

  // Test Supabase connection and storage
  Future<void> testSupabaseConnection() async {
    try {
      print('=== SUPABASE CONNECTION TEST ===');

      // Test basic connection
      print('Supabase URL: https://rssnqbqbrejnjeiukrdr.supabase.co');
      print('Supabase connection established');

      // Test storage access
      print('\n=== STORAGE TEST ===');
      try {
        final buckets = await _supabase.storage.listBuckets();
        print('Available buckets: ${buckets.map((b) => b.name).toList()}');

        // Check if our required buckets exist
        final requiredBuckets = ['posts', 'campaigns', 'avatars'];
        for (final bucketName in requiredBuckets) {
          final bucketExists = buckets.any((b) => b.name == bucketName);
          print('Bucket "$bucketName": ${bucketExists ? "EXISTS" : "MISSING"}');
        }
      } catch (e) {
        print('Storage access error: $e');
      }

      // Test database access
      print('\n=== DATABASE TEST ===');
      try {
        final response = await _supabase.from('users').select('count').count();
        print('Users table accessible: ${response.count} users');
      } catch (e) {
        print('Database access error: $e');
      }

      print('=== TEST COMPLETE ===\n');
    } catch (e) {
      print('Connection test failed: $e');
    }
  }

  // Test image upload specifically
  Future<void> testImageUpload() async {
    try {
      print('=== IMAGE UPLOAD TEST ===');

      // Check if posts bucket exists
      try {
        final bucket = await _supabase.storage.getBucket('posts');
        print('Posts bucket exists: ${bucket.name}');
        print('Posts bucket public: ${bucket.public}');
      } catch (e) {
        print('Posts bucket error: $e');

        // Try to create it
        try {
          await _supabase.storage.createBucket('posts');
          print('Created posts bucket successfully');
        } catch (createError) {
          print('Failed to create posts bucket: $createError');
        }
      }

      print('=== IMAGE UPLOAD TEST COMPLETE ===\n');
    } catch (e) {
      print('Image upload test failed: $e');
    }
  }
}
