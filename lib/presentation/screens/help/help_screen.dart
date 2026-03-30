import 'package:flutter/material.dart';
import 'faq_screen.dart';
import 'complaint_screen.dart';
import 'rate_us_screen.dart';
import 'chatbot_screen.dart'; // ✅ Petra uses your existing chatbot screen

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Help',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000),
                borderRadius: BorderRadius.circular(16),
              ),
              // ✅ Removed const from inner Column to allow non-const children
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('How can\nwe help you?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ✅ All _helpItem calls are non-const (no const keyword on Column)
            _helpItem(
              context,
              Icons.smart_toy,
              'Get a Support with Petra',
              'Get in touch with our AI chat bot',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatbotScreen())),
            ),
            _helpItem(
              context,
              Icons.help_outline,
              'FAQ',
              'Frequently asked questions',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FaqScreen())),
            ),
            _helpItem(
              context,
              Icons.feedback,
              'Raise a Complaint',
              'Report an issue or share feedback',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ComplaintScreen())),
            ),
            _helpItem(
              context,
              Icons.star,
              'Rate Us',
              'Share your Feedback and Rate',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RateUsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8B0000), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}