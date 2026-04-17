import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../providers/contact_provider.dart';

class ContactDetailScreen extends StatelessWidget {
  final Contact contact;

  const ContactDetailScreen({super.key, required this.contact});

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final text = _buildShareText();
    final Uri whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _shareViaEmail(BuildContext context) async {
    final text = _buildShareText();
    final Uri emailUri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': 'Contact: ${contact.clientName ?? contact.companyName ?? "New Contact"}',
        'body': text,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email app available')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  String _buildShareText() {
    final buffer = StringBuffer();

    if (contact.clientName?.isNotEmpty == true) {
      buffer.writeln('Name: ${contact.clientName}');
    }
    if (contact.companyName?.isNotEmpty == true) {
      buffer.writeln('Company: ${contact.companyName}');
    }
    if (contact.email?.isNotEmpty == true) {
      buffer.writeln('Email: ${contact.email}');
    }
    if (contact.phoneNumber?.isNotEmpty == true) {
      buffer.writeln('Phone: ${contact.phoneNumber}');
    }
    if (contact.businessModel?.isNotEmpty == true) {
      buffer.writeln('\nBusiness Model: ${contact.businessModel}');
    }
    if (contact.businessOperation?.isNotEmpty == true) {
      buffer.writeln('\nBusiness Operation: ${contact.businessOperation}');
    }
    if (contact.targetMarket?.isNotEmpty == true) {
      buffer.writeln('\nTarget Market: ${contact.targetMarket}');
    }
    if (contact.lookingFor?.isNotEmpty == true) {
      buffer.writeln('\nLooking For: ${contact.lookingFor}');
    }
    if (contact.additionalNotes?.isNotEmpty == true) {
      buffer.writeln('\nNotes: ${contact.additionalNotes}');
    }

    return buffer.toString();
  }

  Future<void> _deleteContact(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final contactProvider = Provider.of<ContactProvider>(context, listen: false);
      final success = await contactProvider.deleteContact(contact.id!);

      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete contact'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: Text(
          'Contact Details',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'share_whatsapp') {
                _shareViaWhatsApp(context);
              } else if (value == 'share_email') {
                _shareViaEmail(context);
              } else if (value == 'delete') {
                _deleteContact(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share_whatsapp',
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Share via WhatsApp'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share_email',
                child: Row(
                  children: [
                    Icon(Icons.email, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Share via Email'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (contact.clientName?.isNotEmpty == true
                                ? contact.clientName![0]
                                : contact.companyName?.isNotEmpty == true
                                    ? contact.companyName![0]
                                    : 'C')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (contact.clientName?.isNotEmpty == true)
                    Text(
                      contact.clientName!,
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (contact.companyName?.isNotEmpty == true)
                    Text(
                      contact.companyName!,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (contact.email?.isNotEmpty == true ||
                      contact.phoneNumber?.isNotEmpty == true) ...[
                    _buildSectionTitle('Contact Information'),
                    _buildInfoCard([
                      if (contact.email?.isNotEmpty == true)
                        _buildInfoRow(
                          Icons.email_outlined,
                          'Email',
                          contact.email!,
                          onTap: () => _launchEmail(contact.email!),
                        ),
                      if (contact.phoneNumber?.isNotEmpty == true)
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Phone',
                          contact.phoneNumber!,
                          onTap: () => _launchPhone(contact.phoneNumber!),
                        ),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionTitle('Business Information'),
                  _buildInfoCard([
                    if (contact.businessModel?.isNotEmpty == true)
                      _buildInfoRow(
                        Icons.business_outlined,
                        'Business Model',
                        contact.businessModel!,
                      ),
                    if (contact.businessOperation?.isNotEmpty == true)
                      _buildInfoRow(
                        Icons.settings_outlined,
                        'Business Operation',
                        contact.businessOperation!,
                      ),
                    if (contact.targetMarket?.isNotEmpty == true)
                      _buildInfoRow(
                        Icons.bar_chart_outlined,
                        'Target Market',
                        contact.targetMarket!,
                      ),
                    if (contact.lookingFor?.isNotEmpty == true)
                      _buildInfoRow(
                        Icons.search_outlined,
                        'Looking For',
                        contact.lookingFor!,
                      ),
                  ]),
                  if (contact.additionalNotes?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Additional Notes'),
                    _buildInfoCard([
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          contact.additionalNotes!,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ]),
                  ],
                  if (contact.transcription?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildSectionTitle('Transcription'),
                    _buildInfoCard([
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          contact.transcription!,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  _buildSectionTitle('Metadata'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.access_time,
                      'Created',
                      dateFormat.format(contact.createdAt),
                    ),
                    _buildInfoRow(
                      Icons.update,
                      'Updated',
                      dateFormat.format(contact.updatedAt),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.blue[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.open_in_new, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
