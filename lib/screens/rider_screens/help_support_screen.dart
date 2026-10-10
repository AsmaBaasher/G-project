import 'package:flutter/material.dart';

// Modern navy color palette (adjust if your app uses a different set)
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          title: const Text(
            'المساعدة والدعم',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'قم الدعم',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 16.0),
              // Support Contact Info
              _buildContactItem(
                icon: Icons.phone,
                label: 'الفني',
                value: '777497890',
              ),
              const SizedBox(height: 12.0),
              _buildContactItem(
                icon: Icons.email,
                label: 'البريد الإلكتروني',
                value: 'support@yourapp.com',
              ),
              const SizedBox(height: 12.0),
              _buildContactItem(
                icon: Icons.web,
                label: 'الموقع الإلكتروني',
                value: 'www.yourapp.com',
              ),

              const SizedBox(height: 32.0),

              const Text(
                'أمثلة على الأسئلة الشائعة:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 16.0),

              // FAQs
              _buildFAQItem(
                question: 'كيف يمكنني تحديث بيانات حسابي؟',
                answer: 'يمكنك تعديل بياناتك من خلال شاشة الإعدادات ثم اختيار "تعديل الملف الشخصي".',
              ),
              const SizedBox(height: 16.0),
              _buildFAQItem(
                question: 'كيف أتواصل مع خدمة العملاء؟',
                answer: 'الفني: 777497890\nالبريد الإلكتروني: support@yourapp.com\nالموقع الإلكتروني: www.yourapp.com',
              ),
              // Add more FAQs here if needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kPrimaryColor, size: 24),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: kSecondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }
} 