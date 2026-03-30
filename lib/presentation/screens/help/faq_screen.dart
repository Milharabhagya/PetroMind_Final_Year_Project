import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final List<Map<String, String>> faqs = const [
    {
      'question': 'How do I set up a price alert?',
      'answer':
          'Go to the Alerts tab, tap "Add Alert", select your fuel type and target price, then tap Save. You will be notified when the price drops to your target.',
    },
    {
      'question': 'How do I reset my password?',
      'answer':
          'On the login screen, tap "Forgot Password", enter your registered email address, and follow the instructions sent to your inbox.',
    },
    {
      'question': 'Can I use the app without registering?',
      'answer':
          'Some features like viewing fuel prices are available without an account. However, alerts, complaints, and personalised features require registration.',
    },
    {
      'question': 'How do I find the nearest fuel station?',
      'answer':
          'Open the Map tab and allow location access. Nearby stations will be shown with real-time fuel prices and availability.',
    },
    {
      'question': 'How do I raise a complaint?',
      'answer':
          'Go to Help > Raise a Complaint, select a station, fill in the subject and description, and tap Submit Complaint.',
    },
  ];

  // Track which index is expanded (-1 = none)
  int _expandedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('FAQ',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                      color: Colors.black, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.help, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Frequently Asked\nQuestions (FAQ)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                'Find quick answers to common questions about Petromind',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final isExpanded = _expandedIndex == index;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          // Tap same item to collapse, else expand new one
                          _expandedIndex = isExpanded ? -1 : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    faqs[index]['question']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: const Color(0xFF8B0000),
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const Divider(height: 20),
                              Text(
                                faqs[index]['answer']!,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}