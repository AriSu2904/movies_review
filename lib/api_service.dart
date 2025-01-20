import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:movie_reviews/aws_s3_service.dart';

class ApiService {
  static const String baseUrl =
      'https://crudcrud.com/api/04eb4cbaf5b349ba99b39cc93db14814';

  Future<bool> registerUser(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);
        return users.any((user) => user['username'] == username);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> loginUser(String username, String password) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);
        return users.any((user) =>
            user['username'] == username && user['password'] == password);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getReviews(String username) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reviews'));
      if (response.statusCode == 200) {
        final List reviews = jsonDecode(response.body);
        return reviews
            .where((review) => review['username'] == username)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      print('Uploading image to aws s3...');

      String fileName = image.path.split('/').last;
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      fileName = '$timestamp-$fileName';

      if (!fileName.toLowerCase().endsWith('.jpg')) {
        fileName = '${fileName.split('.').first}.jpg';
      }

      await s3Storage.putObject(
        'jpn-bucket',
        'movies/$fileName',
        image.openRead().cast<Uint8List>(),
        metadata: {'Content-Type': 'image/jpeg'},
        onProgress: (bytes) => print('$bytes uploaded'),
      );

      print('Image uploaded to aws s3');
      return 'https://jpn-bucket.s3-ap-southeast-2.amazonaws.com/movies/$fileName';
    } catch (e) {
      print('Error uploading image to imgbb: $e');
      return null;
    }
  }

  Future<bool> addReview(String username, String title, int rating,
      String comment, File image) async {
    try {
      final imageUri = await _uploadImage(image);

      print('Adding review with image: $imageUri');

      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'title': title,
          'rating': rating,
          'comment': comment,
          'imageUri': imageUri
        }),
      );

      print('Response status: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  Future<bool> updateReviewWithImage(
      String id, String username, String title, int rating, String comment, File image) async {
    try {
      final imageUri = await _uploadImage(image);

      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'title': title,
          'rating': rating,
          'comment': comment,
          'imageUri': imageUri
        }),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  Future<bool> updateReview(
      String id, String username, String title, int rating, String comment, String image) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'username': username,
          'title': title,
          'rating': rating,
          'comment': comment,
          'imageUri': image
        }),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating review: $e');
      return false;
    }
  }

  Future<bool> deleteReview(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/reviews/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
}
