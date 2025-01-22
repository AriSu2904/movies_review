import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static const String likesKey = 'liked_reviews';

  static Future<Set<String>> getLikedReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final likedReviews = prefs.getStringList(likesKey);
    return likedReviews?.toSet() ?? <String>{};
  }

  static Future<void> likeReview(String reviewId) async {
    final prefs = await SharedPreferences.getInstance();
    final likedReviews = await getLikedReviews();
    likedReviews.add(reviewId);
    await prefs.setStringList(likesKey, likedReviews.toList());
  }

  static Future<void> unlikeReview(String reviewId) async {
    final prefs = await SharedPreferences.getInstance();
    final likedReviews = await getLikedReviews();
    likedReviews.remove(reviewId);
    await prefs.setStringList(likesKey, likedReviews.toList());
  }
}
