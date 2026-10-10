import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_project/chats/chat_screen.dart';

// Modern navy color palette
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue

class SelectUserPage extends StatefulWidget {
  final String currentUserId;
  const SelectUserPage({super.key, required this.currentUserId});

  @override
  State<SelectUserPage> createState() => _SelectUserPageState();
}

class _SelectUserPageState extends State<SelectUserPage> {
  Future<void> createChatWithFirstMessage(String otherUserId, String otherUserName) async {
    final chatsRef = FirebaseFirestore.instance.collection('chats');

    final querySnapshot = await chatsRef
        .where('participants', arrayContains: widget.currentUserId)
        .get();

    String? chatId;

    for (var doc in querySnapshot.docs) {
      List participants = doc['participants'];
      if (participants.contains(otherUserId)) {
        chatId = doc.id;
        break;
      }
    }

    if (chatId == null) {
      final newChatDoc = await chatsRef.add({
        'participants': [widget.currentUserId, otherUserId],
        'lastMessage': 'مرحباً!',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      await newChatDoc.collection('messages').add({
        'senderId': widget.currentUserId,
        'text': 'مرحباً! هذه أول رسالة.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      chatId = newChatDoc.id;
    }

    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          chatId: chatId!,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
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
          iconTheme: IconThemeData(
            color: kBackgroundColor,
          ),
          elevation: 0,
          backgroundColor: kPrimaryColor,
          title: const Text(
            'المحادثات',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Tajawal',
            ),
          ),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: kPrimaryColor,
                ),
              );
            }

            final users = snapshot.data!.docs.where((doc) => doc.id != widget.currentUserId).toList();

            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: kSecondaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا يوجد مستخدمون آخرون',
                      style: TextStyle(
                        fontSize: 18,
                        color: kSecondaryColor,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                var userDoc = users[index];
                var userName = userDoc['name'] ?? 'مستخدم';
                var userId = userDoc.id;

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('chats')
                      .where('participants', arrayContains: widget.currentUserId)
                      .get(),
                  builder: (context, chatSnapshot) {
                    String lastMessage = '';

                    if (chatSnapshot.hasData) {
                      for (var chat in chatSnapshot.data!.docs) {
                        List participants = chat['participants'];
                        if (participants.contains(userId)) {
                          lastMessage = chat['lastMessage'] ?? '';
                          break;
                        }
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shadowColor: kPrimaryColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => createChatWithFirstMessage(userId, userName),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                kBackgroundColor.withOpacity(0.3),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: kPrimaryColor.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(Icons.person, color: kPrimaryColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: kTextColor,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMessage.isEmpty ? 'ابدأ المحادثة الآن' : lastMessage,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: kSecondaryColor.withOpacity(0.8),
                                        fontFamily: 'Tajawal',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: kSecondaryColor.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
