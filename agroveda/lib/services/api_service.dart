import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {

  const baseUrl = "https://agroveda-backend.onrender.com";

  static Future<Map<String, dynamic>?> predictDisease(File imageFile) async {
    try {

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/predict"),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      var response = await request.send();

      var responseBody = await response.stream.bytesToString();

      print("STATUS CODE: ${response.statusCode}");
      print("RAW RESPONSE: $responseBody");

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        print("Server error");
        return null;
      }

    } catch (e) {
      print("API ERROR: $e");
      return null;
    }
  }
}