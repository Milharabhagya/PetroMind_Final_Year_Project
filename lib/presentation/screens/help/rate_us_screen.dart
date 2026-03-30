import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateUsScreen extends StatefulWidget {
  const RateUsScreen({super.key});

  @override
  State<RateUsScreen> createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  int _rating = 0;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('ratings').add({
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'unknown',
        'rating': _rating,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your rating!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Rate Us',
            style:
                TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF8B0000),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_gas_station,
                    color: Colors.amber, size: 40),
                const Text('PetroMind',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Enjoying PetroMind?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Text("We'd love to hear your feedback",
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () =>
                          setState(() => _rating = index + 1),
                      icon: Icon(
                        index < _rating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.white,
                        size: 36,
                      ),
                    );
                  }),
                ),
                if (_rating > 0) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    // ✅ Calls Firestore submit, shows loading while saving
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Color(0xFF8B0000), strokeWidth: 2),
                          )
                        : const Text('Submit Rating',
                            style:
                                TextStyle(color: Color(0xFF8B0000))),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}