import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:PlateRates/libs/alertSystem.dart';
import 'package:PlateRates/libs/report.dart';
import 'package:PlateRates/libs/userAvatar.dart' as plateRatesUserAvatar;
import 'package:PlateRates/libs/dataCollect.dart';
import 'package:PlateRates/login/userLogin.dart';
import 'package:PlateRates/main.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
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
            plateRatesUserAvatar.UserAvatar(
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
  final List<types.User> _usersTyping = [];
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
              (jsonData["action"] == "past_message" &&
                  pastItemDate > jsonData["data"]["sendTime"])) {
            if (jsonData["action"] == "past_message") {
              pastItemDate = jsonData["data"]["sendTime"];
            }
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

              // ignore: prefer_typing_uninitialized_variables
              var imageData;
              if (fetchedData["avatar"] != null) {
                // ignore: use_build_context_synchronously
                Map avatarData = await dataCollect.getAvatarData(
                    fetchedData["avatar"], context, false);
                imageData = avatarData["imageData"];
              }
              setState(() {
                dataGathered = true;
                groupName = fetchedData["username"];

                //posterAvatar = avatarData["imageData"];
                if (imageData != null) {
                  groupImage = base64Decode(imageData);
                }
              });
            }
          } else if (jsonData["action"] == "user_typing") {
            types.User userTypingData =
                await getUserInfo(jsonData["userId"], context);

            setState(() {
              print(jsonData["typing"]);
              if (jsonData["typing"] == true) {
                if (_usersTyping.contains(userTypingData) == false) {
                  _usersTyping.add(userTypingData);
                } else {
                  print("user already in list");
                }
              } else {
                if (_usersTyping.contains(userTypingData)) {
                  _usersTyping.remove(userTypingData);
                } else {
                  print("user not in list");
                } //yeah this is working fully yet
              }
            });
            print(userTypingData);
          }
        } on Exception catch (error, stackTrace) {
          FirebaseCrashlytics.instance.recordError(error, stackTrace);
          print("error reading data");
          print(error);
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

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
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
    if (_typingTimer != null) {
      if (_typingTimer!.isActive) {
        _typingTimer?.cancel();
        channel.sink.add(jsonEncode({
          "request": "typing_indicator",
          "token": userManager.token,
          "typing": false,
        }));
        typing = false;
      }
    }
  }

  Future<void> _handleMessageHold(
      BuildContext context, types.Message p1) async {
    //openAlert("info", "message data", p1.id, context, null);
    openAlert(
        "custom_buttons", "select action for message", null, context, null, [
      DialogButton(
        color: Colors.red,
        child: const Text(
          '🚩 report comment',
          style: TextStyle(fontSize: 16.0, color: Colors.white),
        ),
        onPressed: () async {
          reportSystem.reportItem(context, "chat_message", p1.id);
        },
      )
    ]);
  }

  Timer? _typingTimer;
  bool typing = false;
  Future<void> _handleTextChange(String text) async {
    if (_typingTimer == null || !_typingTimer!.isActive) {
      // Start the timer when the user starts typing.
      print("user started typing");
      if (_typingTimer != null) {
        print(_typingTimer!.isActive);
      }
      if (typing == false) {
        channel.sink.add(jsonEncode({
          "request": "typing_indicator",
          "token": userManager.token,
          "typing": true,
        }));
        typing = true;
      }

      _typingTimer = Timer(Duration(seconds: 3), () {
        // Code to run after the user stops typing for 2 seconds.
        print("User stopped typing.");
        channel.sink.add(jsonEncode({
          "request": "typing_indicator",
          "token": userManager.token,
          "typing": false,
        }));
        typing = false;
      });
    } else {
      // If the user continues typing, reset the timer.
      _typingTimer?.cancel();
      _handleTextChange(text);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel(); // Cancel the timer when disposing the widget.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (dataGathered == true) {
      return Scaffold(
          body: Stack(
        children: [
          Chat(
            showUserAvatars: false,
            showUserNames: true,
            theme: DefaultChatTheme(
              primaryColor: theme.primaryColor,
              backgroundColor: const Color.fromRGBO(16, 16, 16, 1),
            ),
            typingIndicatorOptions: TypingIndicatorOptions(
              typingMode: TypingIndicatorMode.both,
              typingUsers: _usersTyping,
            ),
            usePreviewData: true,
            messages: _messages,
            onSendPressed: _handleSendPressed,
            user: _user,
            onPreviewDataFetched: _handlePreviewDataFetched,
            //onEndReachedThreshold: 80,
            onMessageLongPress: (context, p1) {
              _handleMessageHold(context, p1);
            },
            inputOptions: InputOptions(
              onTextChanged: _handleTextChange,
            ),
            onEndReached: () async {
              if (lastReachedTimeMessageTime != pastItemDate ||
                  lastReachedTopTime <
                      (DateTime.now().millisecondsSinceEpoch - (1000 * 5))) {
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}

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
//unsend messages
