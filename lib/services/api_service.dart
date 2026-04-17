import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/contact.dart';
import '../utils/constants.dart';

class ApiService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.userTokenKey);
  }

  Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Authentication
  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);
      await _storage.write(key: AppConstants.userTokenKey, value: data['token']);
      await _storage.write(key: AppConstants.userIdKey, value: user.id);
      await _storage.write(key: AppConstants.userEmailKey, value: user.email);
      await _storage.write(key: AppConstants.userNameKey, value: user.name);
      return user.copyWith(token: data['token']);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<User> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/register'),
      headers: _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);
      await _storage.write(key: AppConstants.userTokenKey, value: data['token']);
      await _storage.write(key: AppConstants.userIdKey, value: user.id);
      await _storage.write(key: AppConstants.userEmailKey, value: user.email);
      await _storage.write(key: AppConstants.userNameKey, value: user.name);
      return user.copyWith(token: data['token']);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  // Contacts
  Future<List<Contact>> getContacts() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/contacts'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Contact.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load contacts: ${response.body}');
    }
  }

  Future<Contact> getContact(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/contacts/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return Contact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load contact: ${response.body}');
    }
  }

  Future<Contact> createContact(Contact contact) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/contacts'),
      headers: _getHeaders(token),
      body: jsonEncode(contact.toJson()),
    );

    if (response.statusCode == 201) {
      return Contact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create contact: ${response.body}');
    }
  }

  Future<Contact> updateContact(String id, Contact contact) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/contacts/$id'),
      headers: _getHeaders(token),
      body: jsonEncode(contact.toJson()),
    );

    if (response.statusCode == 200) {
      return Contact.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update contact: ${response.body}');
    }
  }

  Future<void> deleteContact(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/contacts/$id'),
      headers: _getHeaders(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete contact: ${response.body}');
    }
  }

  // Transcription
  Future<Map<String, dynamic>> transcribeAudio(String audioFilePath) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}/transcribe'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });
    request.files.add(await http.MultipartFile.fromPath('audio', audioFilePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to transcribe audio: $responseBody');
    }
  }

  // Contact Extraction
  Future<Map<String, dynamic>> extractContactInfo(String transcription) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/extract'),
      headers: _getHeaders(token),
      body: jsonEncode({
        'transcription': transcription,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to extract contact info: ${response.body}');
    }
  }
}
