import 'package:firebase_auth/firebase_auth.dart';
import '../realtime_database_service.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RealtimeDatabaseService _dbService = RealtimeDatabaseService();

  // Base path for user data
  String get _usersPath => 'users';

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get current user path
  String get _currentUserPath => '$_usersPath/$_currentUserId';

  // Get user data from Realtime Database
  Future<UserModel?> getCurrentUser() async {
    if (_currentUserId == null) return null;

    final snapshot = await _dbService.getData(_currentUserPath);
    if (snapshot.value == null) return null;

    return UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
  }

  // Update user profile in Realtime Database
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    if (_currentUserId == null) return;

    await _dbService.updateData(_currentUserPath, userData);
  }

  // Save user to Realtime Database (used after authentication)
  Future<void> saveUserToDatabase(User user) async {
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'photo_url': user.photoURL,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'last_login': DateTime.now().millisecondsSinceEpoch,
    };

    await _dbService.setData('$_usersPath/${user.uid}', userData);
  }

  // Update user's last login timestamp
  Future<void> updateLastLogin() async {
    if (_currentUserId == null) return;

    await _dbService.updateData(_currentUserPath, {
      'last_login': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Delete user from Realtime Database
  Future<void> deleteUserData() async {
    if (_currentUserId == null) return;

    await _dbService.deleteData(_currentUserPath);
  }

  // Check if a user exists in the Realtime Database
  Future<bool> checkUserExists(String uid) async {
    final snapshot = await _dbService.getData('$_usersPath/$uid');
    return snapshot.value != null;
  }

  // Update profile photo
  Future<void> updateProfilePhoto(String photoUrl) async {
    if (_currentUserId == null) return;

    // Update both Auth profile and database
    try {
      // Update Auth user profile
      await _auth.currentUser?.updatePhotoURL(photoUrl);

      // Update in database
      await _dbService.updateData(_currentUserPath, {
        'photo_url': photoUrl,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating profile photo: $e');
      rethrow;
    }
  }

  // Update user profile details
  Future<void> updateUserProfileData({
    String? displayName,
    String? email,
    String? phoneNumber,
  }) async {
    if (_currentUserId == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await _auth.currentUser?.updateDisplayName(displayName);
        updates['display_name'] = displayName;
      }

      // Update email if provided
      if (email != null &&
          email.isNotEmpty &&
          email != _auth.currentUser?.email) {
        await _auth.currentUser?.updateEmail(email);
        updates['email'] = email;
      }

      // Update phone number if provided
      if (phoneNumber != null) {
        updates['phone_number'] = phoneNumber;
      }

      // Only update if there are changes
      if (updates.length > 1) {
        // More than just updated_at
        await _dbService.updateData(_currentUserPath, updates);
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
