import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:our_whatsapp/Features/Chats/data/model/MessageModel.dart';
import 'package:our_whatsapp/Features/Chats/data/model/userData.dart';
import 'package:our_whatsapp/Features/Chats/presentation/manager/GetUserDataCubit/get_user_data_cubit.dart';
import 'package:our_whatsapp/Features/Chats/presentation/view/widget/charbubble.dart';
import 'package:our_whatsapp/core/helper/Fun.dart';
import 'package:uuid/uuid.dart';

class ChatDetailScreen extends StatefulWidget {
  final MyUserData user;
  const ChatDetailScreen({super.key, required this.user});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late MyUserData ownuser;
  ScrollController controller = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  @override
  void initState() {
    ownuser = context.read<GetUserDataCubit>().userData;
    super.initState();
    if (ownuser.ids != null && ownuser.ids!.contains(widget.user.id)) {
    } else {
      FirebaseFirestore.instance
          .collection('Chats')
          .doc(getRoomId(id1: widget.user.id, id2: ownuser.id))
          .set({
        'roomid': getRoomId(
          id1: widget.user.id,
          id2: ownuser.id,
        ),
        'senderid': ownuser.id,
        "senderimage": ownuser.image,
        'sendername': ownuser.username,
        "receiverid": widget.user.id,
        'receiverimage': widget.user.image,
        'receivername': widget.user.username,
        'lastmessage': "",
        "time": DateTime.now(),
        'participants': [widget.user.id, ownuser.id],
      });
      FirebaseFirestore.instance.collection('Users').doc(ownuser.id).update({
        'ids': FieldValue.arrayUnion([widget.user.id])
      });

      FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user.id)
          .update({
        'ids': FieldValue.arrayUnion([ownuser.id])
      });
      context.read<GetUserDataCubit>().userData.ids!.add(widget.user.id);
    }
  }

  List<MessageModel>? allMessages;
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      var uuid = const Uuid().v4();
      await FirebaseFirestore.instance
          .collection('Chats')
          .doc(getRoomId(id1: widget.user.id, id2: ownuser.id))
          .collection('Messages')
          .doc(uuid)
          .set({
        'senderId': ownuser.id,
        'sendername': ownuser.username,
        'receiverId': widget.user.id,
        'message': _messageController.text,
        'time': DateTime.now(),
        'id': uuid
      });
      FirebaseFirestore.instance
          .collection('Chats')
          .doc(getRoomId(id1: widget.user.id, id2: ownuser.id))
          .update({
        'lastmessage': _messageController.text,
        "time": DateTime.now(),
        "receiverid": widget.user.id,
        'receiverimage': widget.user.image,
        'receivername': widget.user.username,
        'senderid': ownuser.id,
        'sendername': ownuser.username,
        "senderimage": ownuser.image,
        'participants': [widget.user.id, ownuser.id],
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.user.image),
                radius: 20,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.user.username,
                      style: const TextStyle(fontSize: 16)),
                  const Text('Last seen today',
                      style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              print('Video call pressed');
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              print('Voice call pressed');
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'Settings',
                  child: Text('Settings'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('Chats')
                  .doc(getRoomId(id1: widget.user.id, id2: ownuser.id))
                  .collection('Messages')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages.'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                var messages = snapshot.data!.docs;
                List<MessageModel> allMessages = [];
                for (var message in messages) {
                  allMessages.add(MessageModel(
                      id: message['id'],
                      receiver: message['receiverId'],
                      message: message['message'],
                      sender: message['senderId'],
                      time: (message['time'] as Timestamp).toDate()));
                }
                return Expanded(
                  child: messages.isNotEmpty
                      ? ListView.builder(
                          controller: controller,
                          reverse: true,
                          itemCount: allMessages.length,
                          itemBuilder: (context, index) {
                            return allMessages[index].sender == ownuser.id
                                ? ChatBubble(
                                    message: allMessages[index],
                                    OwnUser: ownuser,
                                    user2: widget.user,
                                  )
                                : ChatRecivedBubble(
                                    message: allMessages[index],
                                    OwnUser: ownuser,
                                    user2: widget.user,
                                  );
                          },
                        )
                      : const Center(child: Text('No messages yet.')),
                );
              }),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    _sendMessage();

                    if (allMessages == null) {
                      log("eslam");
                    } else {
                      controller.animateTo(0,
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.bounceInOut);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'Settings':
        print('Settings Selected');
        break;
    }
  }
}
