import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankScreen extends StatefulWidget {
  @override
  _BankScreenState createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  static const Color kPrimaryColor = Color(0xFF1E3A8A);
  static const Color kSecondaryColor = Color(0xFF334155);
  static const Color kBackgroundColor = Color(0xFFF1F5F9);
  static const Color kTextColor = Color(0xFF0F172A);

  bool _isLoading = false;
  List<Map<String, dynamic>> bankAccounts = [];
  final List<String> _banks = [
    'العمقي',
    'الكريمي',
    'القطيبي',
    'البسيري',
    'بن دول'
  ];

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('bank_accounts')
            .where('driverId', isEqualTo: user.uid)
            .get();

        setState(() {
          bankAccounts = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
        });
      }
    } catch (e) {
      print('Error loading bank accounts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBankAccount(String accountId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bank_accounts')
          .doc(accountId)
          .delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الحساب البنكي بنجاح')),
      );
      
      _loadBankAccounts(); // إعادة تحميل القائمة
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف الحساب: $e')),
      );
    }
  }

  Future<void> _editBankAccount(Map<String, dynamic> account) async {
    final TextEditingController bankNameController = TextEditingController(text: account['bankName']);
    final TextEditingController accountNumberController = TextEditingController(text: account['accountNumber']);
    String? selectedBank = account['bankName'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الحساب البنكي', style: TextStyle(fontFamily: 'Tajawal')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBank,
                    hint: const Text('اختر البنك', style: TextStyle(fontFamily: 'Tajawal')),
                    isExpanded: true,
                    items: _banks.map((String bank) {
                      return DropdownMenuItem<String>(
                        value: bank,
                        child: Text(bank, style: const TextStyle(fontFamily: 'Tajawal')),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedBank = newValue;
                      bankNameController.text = newValue ?? '';
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'رقم الحساب',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedBank != null && accountNumberController.text.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('bank_accounts')
                      .doc(account['id'])
                      .update({
                    'bankName': selectedBank,
                    'accountNumber': accountNumberController.text,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  Navigator.pop(context);
                  _loadBankAccounts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث الحساب البنكي بنجاح')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء تحديث الحساب: $e')),
                  );
                }
              }
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewBankAccount() async {
    final TextEditingController bankNameController = TextEditingController();
    final TextEditingController accountNumberController = TextEditingController();
    String? selectedBank;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة حساب بنكي جديد', style: TextStyle(fontFamily: 'Tajawal')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBank,
                    hint: const Text('اختر البنك', style: TextStyle(fontFamily: 'Tajawal')),
                    isExpanded: true,
                    items: _banks.map((String bank) {
                      return DropdownMenuItem<String>(
                        value: bank,
                        child: Text(bank, style: const TextStyle(fontFamily: 'Tajawal')),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      selectedBank = newValue;
                      bankNameController.text = newValue ?? '';
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'رقم الحساب',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedBank != null && accountNumberController.text.isNotEmpty) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('bank_accounts')
                        .add({
                      'driverId': user.uid,
                      'bankName': selectedBank,
                      'accountNumber': accountNumberController.text,
                      'createdAt': FieldValue.serverTimestamp(),
                      'isActive': true,
                    });
                    
                    Navigator.pop(context);
                    _loadBankAccounts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة الحساب البنكي بنجاح')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('حدث خطأ أثناء إضافة الحساب: $e')),
                  );
                }
              }
            },
            child: const Text('إضافة', style: TextStyle(fontFamily: 'Tajawal')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          iconTheme: IconThemeData(
            color: kBackgroundColor
          ),
          title: const Text('الحسابات البنكية', style: TextStyle(fontFamily: 'Tajawal' , color: kBackgroundColor)),
          backgroundColor: kPrimaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.add , color: kBackgroundColor,),
              onPressed: _addNewBankAccount,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : bankAccounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: kSecondaryColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد حسابات بنكية مضافة',
                          style: TextStyle(
                            fontSize: 16,
                            color: kSecondaryColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addNewBankAccount,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة حساب بنكي'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bankAccounts.length,
                    itemBuilder: (context, index) {
                      final account = bankAccounts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: kPrimaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        account['bankName'] ?? 'غير معروف',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: kPrimaryColor),
                                        onPressed: () => _editBankAccount(account),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: kSecondaryColor),
                                        onPressed: () => showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Tajawal')),
                                            content: const Text(
                                              'هل أنت متأكد من حذف هذا الحساب البنكي؟',
                                              style: TextStyle(fontFamily: 'Tajawal'),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteBankAccount(account['id']);
                                                },
                                                child: const Text(
                                                  'حذف',
                                                  style: TextStyle(color: Colors.red, fontFamily: 'Tajawal'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'رقم الحساب: ${account['accountNumber'] ?? 'غير معروف'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: kSecondaryColor,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              // if (account['createdAt'] != null)
                              //   Padding(
                              //     padding: const EdgeInsets.only(top: 8),
                              //     child: Text(
                              //       'تاريخ الإضافة: ${_formatDate(account['createdAt'])}',
                              //       style: const TextStyle(
                              //         fontSize: 14,
                              //         color: kSecondaryColor,
                              //         fontFamily: 'Tajawal',
                              //       ),
                              //     ),
                              //   ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'غير معروف';
    
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return 'غير معروف';
    }
  }
}
