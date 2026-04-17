import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/audio_service.dart';
import '../providers/contact_provider.dart';
import '../providers/auth_provider.dart';
import '../models/contact.dart';
import 'contact_detail_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioService _audioService = AudioService();
  bool _isRecording = false;
  bool _isProcessing = false;
  int _recordingDuration = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  void _startTimer() {
    _recordingDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _startRecording() async {
    try {
      await _audioService.startRecording();
      setState(() {
        _isRecording = true;
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioService.stopRecording();
      _stopTimer();
      setState(() {
        _isRecording = false;
      });

      if (path != null && mounted) {
        await _processRecording(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processRecording(String audioPath) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Transcribe audio
      final transcriptionResult = await contactProvider.transcribeAudio(audioPath);
      if (transcriptionResult == null) {
        throw Exception('Failed to transcribe audio');
      }

      final transcription = transcriptionResult['transcription'] as String?;
      if (transcription == null || transcription.isEmpty) {
        throw Exception('No transcription received');
      }

      // Extract contact information
      final extractedInfo = await contactProvider.extractContactInfo(transcription);
      if (extractedInfo == null) {
        throw Exception('Failed to extract contact information');
      }

      // Create contact
      final contact = Contact(
        userId: authProvider.user!.id,
        companyName: extractedInfo['company_name'] as String?,
        clientName: extractedInfo['client_name'] as String?,
        businessModel: extractedInfo['business_model'] as String?,
        businessOperation: extractedInfo['business_operation'] as String?,
        targetMarket: extractedInfo['target_market'] as String?,
        lookingFor: extractedInfo['looking_for'] as String?,
        phoneNumber: extractedInfo['phone_number'] as String?,
        email: extractedInfo['email'] as String?,
        additionalNotes: extractedInfo['additional_notes'] as String?,
        audioFilePath: audioPath,
        transcription: transcription,
      );

      await contactProvider.createContact(contact);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Navigate to contact detail
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ContactDetailScreen(contact: contact),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process recording: $e'),
            backgroundColor: Colors.red,
          ),
        );

        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _cancelRecording() async {
    await _audioService.cancelRecording();
    _stopTimer();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: Text(
          'Record Conversation',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isProcessing
          ? _buildProcessingView()
          : _buildRecordingView(),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Processing recording...',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transcribing and extracting information',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.red[50] : Colors.blue[50],
              border: Border.all(
                color: _isRecording ? Colors.red : Colors.blue[700]!,
                width: 3,
              ),
            ),
            child: Center(
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                size: 80,
                color: _isRecording ? Colors.red : Colors.blue[700],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isRecording ? 'Recording...' : 'Ready to record',
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (_isRecording)
            Text(
              _formatDuration(_recordingDuration),
              style: GoogleFonts.robotoMono(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                ElevatedButton(
                  onPressed: _cancelRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isRecording ? 'Stop' : 'Start Recording',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
