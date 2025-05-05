import 'dart:convert';
import 'package:http/http.dart' as http;
import 'category.dart';

class CategoryService {
  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('http://192.168.205.252/flutter_api/get_categories.php'),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Category.fromJson(json)).toList();
        } else {
          throw Exception("Invalid data format");
        }
      } catch (e) {
        print("JSON parsing error: $e");
        throw Exception("Failed to parse categories");
      }
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
