import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_project/screens/driver_screens/driver_orders_screen.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:flutter/scheduler.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../theme/app_colors.dart';

class PaymentPDFScreen extends StatefulWidget {
  @override
  _PaymentPDFScreenState createState() => _PaymentPDFScreenState();
}

class _PaymentPDFScreenState extends State<PaymentPDFScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  List<DocumentSnapshot> _documents = [];
  bool _isLoading = true;
  final Map<String, Image> _imageCache = {};
  final currencyFormat = NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1, curve: Curves.easeOutBack),
      ),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _loadDocuments();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('payments')
            .where('driverId', isEqualTo: user.uid)
            .get();

        final sortedDocs = querySnapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['pdfBase64'] != null || data['imageBase64'] != null;
            })
            .toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aDate = (aData['createdAt'] as Timestamp).toDate();
            final bDate = (bData['createdAt'] as Timestamp).toDate();
            return bDate.compareTo(aDate);
          });

        setState(() {
          _documents = sortedDocs;
          _isLoading = false;
        });

        for (var doc in _documents) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['imageBase64'] != null) {
            _loadBase64Image(data['imageBase64'], doc.id);
          }
        }
      }
    } catch (e) {
      print('Error loading payments: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحميل المستندات')),
      );
    }
  }

  Future<void> _loadBase64Image(String base64String, String docId) async {
    try {
      final image = Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
      );

      await precacheImage(image.image, context);

      setState(() {
        _imageCache[docId] = image;
      });
    } catch (e) {
      print('Error loading base64 image: $e');
    }
  }

  void _showFullScreenImage(String docId) {
    final image = _imageCache[docId];
    if (image != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Stack(
            children: [
              InteractiveViewer(
                child: image,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDocumentCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = (data['createdAt'] as Timestamp).toDate();
    final formattedDate = DateFormat('yyyy/MM/dd - HH:mm').format(timestamp);
    final amount = data['amount'] as num? ?? 0;
    final docId = doc.id;
    final paymentType = data['paymentType'] as String? ?? 'رسوم';
    final status = data['status'] as String? ?? 'pending';
    final hasImage = data['imageBase64'] != null;
    final hasPdf = data['pdfBase64'] != null;
    final riderId = data['riderId'] as String? ?? 'غير معروف';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'معرف الراكب: $riderId',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                paymentType,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasImage && hasPdf)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.image, size: 16, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                                    ],
                                  ),
                                )
                              else if (hasImage)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.image, size: 16, color: Colors.blue),
                                )
                              else if (hasPdf)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasImage || hasPdf)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasImage && _imageCache.containsKey(docId))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الصورة المرفقة:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _showFullScreenImage(docId),
                                child: Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _imageCache[docId],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (hasPdf && data['pdfBase64'] != null) ...[
                          if (hasImage) const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ملف PDF المرفق:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SfPdfViewer.memory(
                                    base64Decode(data['pdfBase64']),
                                    canShowScrollHead: false,
                                    canShowScrollStatus: false,
                                    enableDoubleTapZooming: false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      data['notes'],
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          
          iconTheme: IconThemeData(
            color: kBackgroundColor,
          ),
          title: const Text(
            'المستندات المدفوعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: kBackgroundColor,
            ),
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _documents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد مستندات مدفوعة',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _documents.length,
                    itemBuilder: (context, index) => _buildDocumentCard(_documents[index]),
                  ),
      ),
    );
  }
}