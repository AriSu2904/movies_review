import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://crudcrud.com/api/a3aa26d01ca440a3bd72b5c65eefe8d2';

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
      print('Uploading image to imgbb...');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://api.imgbb.com/1/upload?key=de5420226e97640a2c24f9396ad9eea3'),
      );
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        filename: image.path.split('/').last,
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final json = jsonDecode(responseBody);

        print('Response from imgbb: $json');

        print('Image uploaded to imgbb: ${json['data']['url']}');

        return json['data']['url']; // Get the image URL from imgbb response
      } else {
        print('Failed to upload image to imgbb: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image to imgbb: $e');
      return null;
    }
  }

  Future<bool> addReview(String username, String title, int rating,
      String comment, File image) async {
    try {
      final uri = await _uploadImage(image);
      final imageUri = _replaceImageUri(uri!);
      
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
      String id, String title, int rating, String comment, File image) async {
    try {
      final uri = await _uploadImage(image);
      final imageUri = _replaceImageUri(uri!);

      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
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
      String id, String title, int rating, String comment, String image) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
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

  String _replaceImageUri(String imageUri) {
    return imageUri.replaceAll('https://i.ibb.co.com/', 'https://i.ibb.co/');
  }
}
