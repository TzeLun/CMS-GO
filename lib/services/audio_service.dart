import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path ?? _currentRecordingPath;
    } catch (e) {
      _isRecording = false;
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      _isRecording = false;
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
    } catch (e) {
      throw Exception('Failed to cancel recording: $e');
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
