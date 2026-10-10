import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class RateDriverScreen extends StatefulWidget {
  final String driverName;
  final String driverImage;
  final double distance;
  final String driverId;

  const RateDriverScreen({
    Key? key,
    required this.driverName,
    required this.driverImage,
    required this.distance,
    required this.driverId,
  }) : super(key: key);

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _rating = 0;
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_rating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final driverRef = FirebaseFirestore.instance.collection('driverUsers').doc(widget.driverId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final driverDoc = await transaction.get(driverRef);
        
        if (!driverDoc.exists) {
          throw Exception('لم يتم العثور على بيانات السائق');
        }

        final currentData = driverDoc.data()!;
        final currentRating = (currentData['rating'] ?? 0).toInt();
        final currentTotalRatings = (currentData['totalRatings'] ?? 0).toInt();
        
        final newTotalRatings = currentTotalRatings + 1;
        final newRating = currentRating + _rating;

        transaction.update(driverRef, {
          'rating': newRating,
          'totalRatings': newTotalRatings,
        });
      });

      if (mounted) {
        Navigator.pop(context, {
          'rating': _rating,
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'خطأ',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'حدث خطأ أثناء حفظ التقييم. يرجى المحاولة مرة أخرى.',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'حسناً',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        title: const Text(
          'تقييم الرحلة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: widget.driverImage.isNotEmpty
                  ? Image.memory(
                      base64Decode(widget.driverImage),
                      fit: BoxFit.cover,
                      width: 80,
                      height: 80,
                    )
                  : const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF1E3A8A),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.driverName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'سائق',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            'المسافة: ${widget.distance.toStringAsFixed(2)} كم',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'كيف كانت رحلتك؟',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'تقييمك سيساعد في تحسين تجربة القيادة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            size: 40,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'إرسال التقييم',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
