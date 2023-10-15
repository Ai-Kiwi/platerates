import 'dart:convert';
import 'dart:math';

import 'package:Toaster/libs/userAvatar.dart' as toasterUserAvatar;
import 'package:Toaster/libs/dataCollect.dart';
import 'package:Toaster/login/userLogin.dart';
import 'package:Toaster/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
//import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class FullPageChat extends StatefulWidget {
  final String chatRoomId;
  const FullPageChat({required this.chatRoomId});

  @override
  _fullPageChatState createState() =>
      _fullPageChatState(chatRoomId: chatRoomId);
}

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

Future<types.User> getUserInfo(String userId, context) async {
  var userData = await dataCollect.getUserData(userId, context, false);

  final returnUserData = types.User(
    id: userId,
    firstName: userData['username'],
  );

  return returnUserData;
}

class topUserBar extends StatelessWidget {
  final bool privateChat;
  final String? otherUserId;
  final chatImage;
  final chatName;

  const topUserBar(
      {required this.privateChat,
      this.otherUserId,
      required this.chatImage,
      required this.chatName});

  @override
  Widget build(BuildContext context) {
    if (privateChat == false) {
      return Container(
        height: 25,
        child: const Center(child: Text("groups not added yet")),
      );
    } else {
      return Container(
        height: 50,
        child: Center(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 30,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            toasterUserAvatar.UserAvatar(
              avatarImage: chatImage,
              size: 35,
              roundness: 35,
              onTapFunction: 'openProfile',
              context: context,
              userId: otherUserId,
            ),
            const SizedBox(width: 8),
            Text(
              "$chatName",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            )
          ],
        )),
      );
    }
  }
}

class _fullPageChatState extends State<FullPageChat> {
  final String chatRoomId;
  final List<types.Message> _messages = [];
  bool dataGathered = false;
  var _user = const types.User(id: 'none');
  var channel =
      WebSocketChannel.connect(Uri.parse("$serverWebsocketDomain/chatWs"));
  int pastItemDate = 99999999999999;
  int lastReachedTopTime = 0;
  int lastReachedTimeMessageTime = 0;
  //other user data
  bool privateChat = false;
  late String privateChatOtherUser;
  String groupName = "";
  var groupImage;

  _fullPageChatState({required this.chatRoomId});

  Future<void> _chatWebsocket() async {
    //add loading when authacating room
    //add error when not in the room

    channel.stream.listen(
      (message) async {
        try {
          Map jsonData = jsonDecode(message);
          print(jsonData);

          if (jsonData["action"] == "new_message" ||
              jsonData["action"] == "past_message") {
            //if (pastItemDate > jsonData["data"]["sendTime"]) {
            //  pastItemDate = jsonData["data"]["sendTime"];
            //}
            //var messageStatus = types.Status.sending;
            //if (jsonData["data"]["singlePersonStatus"] == "sending") {
            //  messageStatus = types.Status.sending;
            //} else if (jsonData["data"]["singlePersonStatus"] == "sent") {
            //  messageStatus = types.Status.sent;
            //} else if (jsonData["data"]["singlePersonStatus"] == "seen") {
            //  messageStatus = types.Status.seen;
            //}

            final textMessage = types.TextMessage(
              author:
                  await getUserInfo(jsonData["data"]["messagePoster"], context),
              createdAt: jsonData["data"]["sendTime"],
              id: jsonData["data"]["messageId"],
              text: jsonData["data"]["text"],
              //status: messageStatus
            );

            _addMessage(
                textMessage, (jsonData["action"] == "past_message") == true);
          } else if (jsonData["action"] == "authenticated") {
            _user = await getUserInfo(jsonData["data"]["userId"], context);
            pastItemDate = 99999999999999;
            _messages.clear();
            channel.sink.add(jsonEncode({
              "request": "past_messages",
              "pastItemDate": pastItemDate,
              "token": userManager.token,
            }));
            privateChat = jsonData["data"]["privateChat"];
            if (privateChat == true) {
              privateChatOtherUser = jsonData["data"]["privateChatOtherUser"];

              // ignore: use_build_context_synchronously
              Map fetchedData = await dataCollect.getUserData(
                  privateChatOtherUser, context, false);

              // ignore: use_build_context_synchronously
              Map avatarData = await dataCollect.getAvatarData(
                  fetchedData["avatar"], context, false);
              setState(() {
                dataGathered = true;
                groupName = fetchedData["username"];

                //posterAvatar = avatarData["imageData"];
                if (avatarData["imageData"] != null) {
                  groupImage = base64Decode(avatarData["imageData"]);
                }
              });
            }
          }
        } catch (err) {
          print("error reading data");
          print(err);
        }

        print("data got");
        //channel.sink.add('received!');
        //channel.sink.close();
      },
      onDone: () {
        dataGathered = false;
        print('ws channel closed');
        Navigator.pop(context);
      },
      onError: (error) {
        dataGathered = false;
        print('ws error $error');
      },
    );

    print("sending start data for chat");
    channel.sink.add(jsonEncode({
      "request": "authenticate",
      "token": userManager.token,
      "chatRoomId": chatRoomId,
    }));
  }

  @override
  void initState() {
    super.initState();
    _chatWebsocket();
  }

  void _addMessage(types.Message message, bool addToEnd) {
    setState(() {
      if (addToEnd) {
        _messages.add(message);
      } else {
        _messages.insert(0, message);
      }
    });
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    channel.sink.add(jsonEncode({
      "request": "send_message",
      "token": userManager.token,
      "text": message.text
    }));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (dataGathered == true) {
      return Scaffold(
          backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
          body: Stack(
            children: [
              Chat(
                showUserAvatars: false,
                showUserNames: true,
                theme: DefaultChatTheme(
                  primaryColor: theme.primaryColor,
                  backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
                ),
                usePreviewData: true,
                messages: _messages,
                onSendPressed: _handleSendPressed,
                user: _user,
                //onEndReachedThreshold: 80,
                onEndReached: () async {
                  if (lastReachedTimeMessageTime != pastItemDate ||
                      lastReachedTopTime <
                          (DateTime.now().millisecondsSinceEpoch -
                              (1000 * 5))) {
                    print("fetching");
                    lastReachedTimeMessageTime = pastItemDate;
                    lastReachedTopTime = DateTime.now().millisecondsSinceEpoch;
                    channel.sink.add(jsonEncode({
                      "request": "past_messages",
                      "pastItemDate": pastItemDate,
                      "token": userManager.token,
                    }));
                  }
                },
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(24, 24, 24, 1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: topUserBar(
                    privateChat: privateChat,
                    otherUserId: privateChatOtherUser,
                    chatImage: groupImage,
                    chatName: groupName,
                  ),
                ),
              ),
            ],
          ));
    } else {
      return const Scaffold(
        backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}

//talking will be websockets
//server will send when user is typing
//server will send on new message
//client will send acknolagment, if server doesn't get one will keep resending
//messages have id to make sure if send twice by server it does nothing
//client will tell server that it has sent message, will not care if it has or hasn't been accepted

//add typing
//add when message last seen
//add support for files and images
//add support for avatars
//support replying to messages
//fix crash on websocket close
//make top bar not green
//make other user border not white
//make some system for users color
//make message unloading when scrolling up