import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser;
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chat')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, chatSnapshots) {
          if (chatSnapshots.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
            return const Center(
              child: Text('No messages found..!!'),
            );
          }

          if (chatSnapshots.hasError) {
            return const Center(
              child: Text('Some thing went wrong..!!'),
            );
          }

          final messages = chatSnapshots.data!.docs;

          return ListView.builder(
              padding: const EdgeInsets.only(bottom: 40, left: 15, right: 15),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: ((ctx, index) {
                final chatMessages = messages[index].data();

                final nextMessages = index + 1 < messages.length
                    ? messages[index + 1].data()
                    : null;

                final currentMessageUserId = chatMessages['user_id'];
                final nextMessageUserId =
                    nextMessages != null ? nextMessages['user_id'] : null;
                final nextUserIsSame =
                    nextMessageUserId == currentMessageUserId;

                if (nextUserIsSame) {
                  return MessageBubble.next(
                      message: chatMessages['text'],
                      isMe: authenticatedUser!.uid == currentMessageUserId);
                } else {
                  return MessageBubble.first(
                      userImage: chatMessages['user_image'],
                      username: chatMessages['user_name'],
                      message: chatMessages['text'],
                      isMe: authenticatedUser!.uid == currentMessageUserId);
                }
              }));
        });
  }
}
