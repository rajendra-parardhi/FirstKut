import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  final String apiKey;

  GeminiVisionService({required this.apiKey});

  Future<String> analyzeImage(Uint8List imageBytes, String prompt) async {
    final String base64Image = base64Encode(imageBytes);

    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey");

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inlineData": {
                "mimeType": "image/png", // or "image/jpeg" if needed
                "data": base64Image,
              }
            }
          ]
        }
      ]
    };

    final headers = {"Content-Type": "application/json"};

    final response =
    await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final content = decoded['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return content ?? 'No response text found';
    } else {
      throw Exception('Failed to call Gemini API: ${response.body}');
    }
  }
}
