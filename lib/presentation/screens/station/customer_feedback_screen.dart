import 'package:flutter/material.dart';

class CustomerFeedbackScreen extends StatelessWidget {
  const CustomerFeedbackScreen({super.key});

  final List<Map<String, dynamic>> reviews = const [
    {
      'name': 'Samantha Perera',
      'rating': 4,
      'time': '75 ago',
      'comment':
          'This is a good app, but there is a little bit issue in the app for me. Its not out of Stock.'
    },
    {
      'name': 'Dhanshima Wikramasinghe',
      'rating': 4,
      'time': '22/01/2026',
      'comment':
          'Diesel which marked available in the app, Didn\'t was not actually available. Its out of Stock.'
    },
    {
      'name': 'Tharindra Jayasinghe',
      'rating': 3,
      'time': '22/01/2026',
      'comment':
          'Thank you for available in the petromind. It\'s good, but the petrol is out of stock.'
    },
    {
      'name': 'Kasun Fernando',
      'rating': 4,
      'time': '22/01/2026',
      'comment':
          'The prices are all done with the app. I think this is a nice app. Keep up the good work. Looking forward to more improvements.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Customer Feedback',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,

        // ✅ removed right-side icons
        actions: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Station image
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.grey,
                      child: const Center(
                        child: Icon(Icons.local_gas_station,
                            size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'IOC Kaduwela!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        ...List.generate(
                          4,
                          (_) => const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                        ),
                        const Icon(Icons.star_half,
                            color: Colors.amber, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reviews
            ...reviews.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 18,
                          child: Text(
                            r['name'].toString()[0],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < (r['rating'] as int)
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          r['time'],
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r['comment'],
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}