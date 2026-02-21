import 'package:flutter/foundation.dart';
import '../database/services/profile_service.dart';
import '../database/services/user_service.dart';
import '../models/profile.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final UserService _userService = UserService();

  Profile? _activeProfile;
  bool _isLoaded = false;

  Profile? get activeProfile => _activeProfile;
  bool get isLoaded => _isLoaded;

  int get activeProfileId => _activeProfile?.profileId ?? 1;
  String get currencySymbol => _activeProfile?.currencySymbol ?? '₹';
  String get currencyCode => _activeProfile?.currencyCode ?? 'INR';
  String get profileName => _activeProfile?.name ?? 'Default';

  /// Called once at app startup (after splash determines user is set up).
  Future<void> initialize() async {
    final user = await _userService.getCurrentUser();
    if (user == null) return;

    _activeProfile = await _profileService.getActiveProfile(user.userId!);

    // If no profile exists yet (fresh install after migration), create default India profile
    if (_activeProfile == null) {
      final id = await _profileService.createProfile(
        Profile(
          userId: user.userId!,
          name: 'India',
          currencyId: 1, // INR is seeded as id=1
          countryCode: 'IN',
          isActive: true,
          currencyCode: 'INR',
          currencySymbol: '₹',
          currencyName: 'Indian Rupee',
        ),
      );
      await _profileService.setActiveProfile(id, user.userId!);
      _activeProfile = await _profileService.getActiveProfile(user.userId!);
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Switches to the given profile. All listening screens will rebuild.
  Future<void> switchProfile(Profile profile, int userId) async {
    await _profileService.setActiveProfile(profile.profileId!, userId);
    _activeProfile = await _profileService.getActiveProfile(userId);
    notifyListeners();
  }

  /// Refreshes active profile data (e.g. after editing profile name/currency).
  Future<void> refresh(int userId) async {
    _activeProfile = await _profileService.getActiveProfile(userId);
    notifyListeners();
  }
}
