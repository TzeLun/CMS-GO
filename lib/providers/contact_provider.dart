import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class ContactProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService.instance;

  List<Contact> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<Contact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadContacts(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from local database first
      _contacts = await _dbService.readAllContacts(userId);
      notifyListeners();

      // Then sync with server
      try {
        final serverContacts = await _apiService.getContacts();
        _contacts = serverContacts;
        notifyListeners();
      } catch (e) {
        // If server fails, continue with local data
        debugPrint('Failed to sync with server: $e');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createContact(Contact contact) async {
    try {
      // Save to local database first
      final localContact = await _dbService.createContact(contact);
      _contacts.insert(0, localContact);
      notifyListeners();

      // Then sync with server
      try {
        final serverContact = await _apiService.createContact(contact);
        // Update local contact with server ID
        final index = _contacts.indexWhere((c) => c.id == localContact.id);
        if (index != -1) {
          _contacts[index] = serverContact;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Failed to sync with server: $e');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateContact(Contact contact) async {
    try {
      await _dbService.updateContact(contact);
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _contacts[index] = contact;
        notifyListeners();
      }

      // Sync with server
      try {
        await _apiService.updateContact(contact.id!, contact);
      } catch (e) {
        debugPrint('Failed to sync with server: $e');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteContact(String id) async {
    try {
      await _dbService.deleteContact(id);
      _contacts.removeWhere((c) => c.id == id);
      notifyListeners();

      // Sync with server
      try {
        await _apiService.deleteContact(id);
      } catch (e) {
        debugPrint('Failed to sync with server: $e');
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> transcribeAudio(String audioFilePath) async {
    try {
      return await _apiService.transcribeAudio(audioFilePath);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> extractContactInfo(String transcription) async {
    try {
      return await _apiService.extractContactInfo(transcription);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
