import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class AnalysisResult {
  final String foodName;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final int fiber;
  final int sugar;
  final String verdict;
  final int healthScore;

  AnalysisResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
    required this.sugar,
    required this.verdict,
    required this.healthScore,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      foodName: json['food_name'],
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fats: json['fats'],
      fiber: json['fiber'],
      sugar: json['sugar'],
      verdict: json['verdict'],
      healthScore: json['health_score'],
    );
  }
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch(e) {}
    return 'http://127.0.0.1:8000';
  }

  static Future<AnalysisResult> analyzeFood(String filePath, {List<int>? fileBytes, String? fileName}) async {
    var uri = Uri.parse('$baseUrl/analyze-food');
    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb && fileBytes != null) {
      var multipartFile = http.MultipartFile.fromBytes('image', fileBytes, filename: fileName ?? 'upload.jpg');
      request.files.add(multipartFile);
    } else {
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
    }

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var data = jsonDecode(responseData);
        return AnalysisResult.fromJson(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
