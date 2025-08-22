import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = supabase;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    if (!isLoggedIn) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Refresh current user profile (force reload from database)
  Future<UserModel?> refreshCurrentUserProfile() async {
    return await getCurrentUserProfile();
  }

  // Sign up with email and password (with email verification)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName ?? '',
        },
        emailRedirectTo:
            'https://staymitra.app/email-verified', // Deep link for email verification
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password (with email verification check)
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Check if email is verified
        if (response.user!.emailConfirmedAt == null) {
          // Email not verified, sign out the user
          await _supabase.auth.signOut();
          return {
            'success': false,
            'message':
                'Email not verified. Please check your email and verify your account before logging in.',
            'needsVerification': true,
          };
        }

        return {
          'success': true,
          'message': 'Login successful!',
          'user': response.user,
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid email or password.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Check if current user's email is verified
  bool get isEmailVerified {
    final user = _supabase.auth.currentUser;
    return user?.emailConfirmedAt != null;
  }

  // Resend email verification
  Future<Map<String, dynamic>> resendEmailVerification(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'https://staymitra.app/email-verified',
      );

      return {
        'success': true,
        'message': 'Verification email sent! Please check your inbox.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send verification email: ${e.toString()}',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://rssnqbqbrejnjeiukrdr.supabase.co/auth/v1/callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // Check if authentication was successful
      if (response == true) {
        // Wait a moment for the auth state to update
        await Future.delayed(const Duration(seconds: 2));

        final user = _supabase.auth.currentUser;
        if (user != null) {
          return {
            'success': true,
            'message': 'Google sign-in successful!',
            'user': user,
          };
        }
      }

      return {
        'success': false,
        'message': 'Google sign-in was cancelled or failed.',
      };
    } catch (e) {
      print('Google sign in error: $e');
      return {
        'success': false,
        'message': 'Google sign-in failed: ${e.toString()}',
      };
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'https://rssnqbqbrejnjeiukrdr.supabase.co/auth/v1/callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (response == true) {
        return true;
      }
      return false;
    } catch (e) {
      print('Apple sign in error: $e');
      return false;
    }
  }

  // Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'https://rssnqbqbrejnjeiukrdr.supabase.co/auth/v1/callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (response == true) {
        return true;
      }
      return false;
    } catch (e) {
      print('Facebook sign in error: $e');
      return false;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<UserModel?> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    String? location,
    String? website,
    String? avatarUrl,
  }) async {
    if (!isLoggedIn) return null;

    try {
      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (fullName != null) updates['full_name'] = fullName;
      if (bio != null) updates['bio'] = bio;
      if (location != null) updates['location'] = location;
      if (website != null) updates['website'] = website;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser!.id)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
