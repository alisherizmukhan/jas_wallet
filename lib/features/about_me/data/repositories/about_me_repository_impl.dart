import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/about_me_entity.dart';
import '../../domain/repositories/about_me_repository.dart';

/// Implementation of AboutMeRepository with SharedPreferences persistence.
class AboutMeRepositoryImpl implements AboutMeRepository {
  static const String _storageKey = 'user_about_me';

  @override
  Future<AboutMeEntity> getAboutMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString == null) return AboutMeEntity.empty;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AboutMeEntity.fromJson(json);
    } catch (_) {
      return AboutMeEntity.empty;
    }
  }

  @override
  Future<AboutMeEntity> getAboutMeByUserId(String userId) async {
    return AboutMeEntity(
      id: 'about_$userId',
      userId: userId,
      content: '',
    );
  }

  @override
  Future<AboutMeEntity> updateAboutMe(AboutMeEntity aboutMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(aboutMe.toJson()));
    return aboutMe;
  }
}
