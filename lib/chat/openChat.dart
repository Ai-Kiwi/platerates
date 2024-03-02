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
import 'package:chatview/chatview.dart';
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

Future<ChatUser> getUserInfo(String userId, context) async {
  var userData = await dataCollect.getUserData(userId, context, false);

  // ignore: prefer_typing_uninitialized_variables
  var imageData;
  if (userData["avatar"] != null) {
    // ignore: use_build_context_synchronously
    Map avatarData =
        await dataCollect.getAvatarData(userData["avatar"], context, false);
    imageData = avatarData["imageData"];
  }

  final returnUserData = ChatUser(
    id: userId,
    name: userData['username'],
    //profilePhoto: Image.memory(base64Decode(imageData))
    //
    //
    //imageData != null ? base64Decode(imageData) : imageData,
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
  var currentUser =
      ChatUser(id: '', name: ''); //id of user who is person typing
  bool dataGathered = false;
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

  //this is temp data that gets overided because of my code awfull code, one of those things I should improve
  var chatController = ChatController(
    initialMessageList: [],
    scrollController: ScrollController(),
    chatUsers: [
      ChatUser(id: '2', name: 'Simform'),
      ChatUser(id: '3', name: "John")
    ],
  );

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

            var messageAdding;

            if (jsonData["data"]["replyMessage"] == null) {
              messageAdding = Message(
                id: jsonData["data"]["messageId"],
                message: jsonData["data"]["text"],
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  jsonData["data"]["sendTime"],
                  isUtc: true,
                ),
                sendBy: jsonData["data"]["messagePoster"],
                messageType: MessageType.text,
              );
            } else {
              print("reply message");
              messageAdding = Message(
                id: jsonData["data"]["messageId"],
                message: jsonData["data"]["text"],
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  jsonData["data"]["sendTime"],
                  isUtc: true,
                ),
                sendBy: jsonData["data"]["messagePoster"],
                replyMessage: ReplyMessage(
                  //  messageType: MessageType.text,
                  message: jsonData["data"]["replyMessage"]["text"],
                  replyBy: jsonData["data"]["messagePoster"],
                  replyTo: jsonData["data"]["replyMessage"]["messagePoster"],
                  messageId: jsonData["data"]["replyMessage"]["messageId"],
                ),
              );
            }

            if (jsonData["action"] == "past_message") {
              chatController.loadMoreData([messageAdding]);
            } else {
              chatController.addMessage(messageAdding);
            }
          } else if (jsonData["action"] == "authenticated") {
            currentUser =
                await getUserInfo(jsonData["data"]["userId"], context);

            pastItemDate = 99999999999999;
            channel.sink.add(jsonEncode({
              "request": "past_messages",
              "pastItemDate": pastItemDate,
              "token": userManager.token,
            }));
            privateChat = jsonData["data"]["privateChat"];
            if (privateChat == true) {
              privateChatOtherUser = jsonData["data"]["privateChatOtherUser"];

              chatController = ChatController(
                initialMessageList: [],
                scrollController: ScrollController(),
                chatUsers: [
                  await getUserInfo(jsonData["data"]["userId"], context),
                  await getUserInfo(
                      jsonData["data"]["privateChatOtherUser"], context),
                ],
              );

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
            //types.User userTypingData =
            //    await getUserInfo(jsonData["userId"], context);
            //
            //setState(() {
            //  print(jsonData["typing"]);
            //  if (jsonData["typing"] == true) {
            //    if (_usersTyping.contains(userTypingData) == false) {
            //      _usersTyping.add(userTypingData);
            //    } else {
            //      print("user already in list");
            //    }
            //  } else {
            //    if (_usersTyping.contains(userTypingData)) {
            //      _usersTyping.remove(userTypingData);
            //    } else {
            //      print("user not in list");
            //    } //yeah this is working fully yet
            //  }
            //});
            //print(userTypingData);
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

  @override
  void initState() {
    super.initState();
    _chatWebsocket();
  }

  @override
  void dispose() {
    _typingTimer?.cancel(); // Cancel the timer when disposing the widget.
    super.dispose();
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

  void onSendTap(
      String message, ReplyMessage replyMessage, MessageType messageType) {
    //print(messageType.isText);
    //print(replyMessage.messageId);
    channel.sink.add(jsonEncode({
      "request": "send_message",
      "token": userManager.token,
      "text": message,
      "reply-message": replyMessage.messageId
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
    setState(() {
      //gonna be honest for some reaosn data freezes after sending message and this fixes it, dont ask me why it does what it does lmao
      dataGathered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (dataGathered == true) {
      return Scaffold(
        body: SafeArea(
          bottom: true,
          top: true,
          child: ChatView(
            appBar: Container(
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
            featureActiveConfig: const FeatureActiveConfig(
              enableSwipeToReply: true,
              enableSwipeToSeeTime: true,
              enableReactionPopup: false,
              enablePagination: true,
              enableOtherUserProfileAvatar: false,
              enableDoubleTapToLike: false,
            ),

            currentUser: currentUser,
            chatController: chatController,
            onSendTap: onSendTap,
            sendMessageConfig: SendMessageConfiguration(
              replyMessageColor: Colors.green,
              replyTitleColor: Colors.black54,
              replyDialogColor: Colors.white,
              textFieldConfig: TextFieldConfiguration(
                textStyle: TextStyle(color: Colors.black),
                onMessageTyping: (status) {
                  // send composing/composed status to other client
                  // your code goes here
                  print("typing");
                  print(status);
                },

                /// After typing stopped, the threshold time after which the composing
                /// status to be changed to [TypeWriterStatus.typed].
                /// Default is 1 second.
                compositionThresholdTime: const Duration(seconds: 1),
              ),
            ),
            loadMoreData: () async {
              print("load more");
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
            isLastPage: false,
            chatViewState: ChatViewState
                .hasMessages, // Add this state once data is available.
            chatBubbleConfig: const ChatBubbleConfiguration(
              outgoingChatBubbleConfig: ChatBubble(
                senderNameTextStyle: TextStyle(color: Colors.white),
                // Sender's message chat bubble
                color: Colors.green,
                textStyle: TextStyle(
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(2),
                ),
              ),
              inComingChatBubbleConfig: ChatBubble(
                senderNameTextStyle: TextStyle(color: Colors.white),
                // Receiver's message chat bubble
                color: Color.fromARGB(255, 75, 75, 75),
                textStyle: TextStyle(
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(2),
                ),
              ),
            ),

            repliedMessageConfig: const RepliedMessageConfiguration(
              backgroundColor: Colors.green,
              verticalBarColor: Colors.white70,
              repliedMsgAutoScrollConfig: RepliedMsgAutoScrollConfig(
                enableHighlightRepliedMsg: true,
                highlightColor: Colors.green,
                highlightScale: 1.1,
              ),
              textStyle: TextStyle(
                color: Colors.white,
                letterSpacing: 0.25,
              ),
              replyTitleTextStyle: TextStyle(color: Colors.white),
            ),
            swipeToReplyConfig: const SwipeToReplyConfiguration(
              replyIconColor: Colors.grey,
            ),

            chatBackgroundConfig: const ChatBackgroundConfiguration(
              backgroundColor: Color.fromRGBO(16, 16, 16, 1),
              defaultGroupSeparatorConfig: DefaultGroupSeparatorConfiguration(
                textStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}
//TODO needed 
//test if doesn't show new messages added
//test everything in a live chat
//split notifcations off for reply
//add sending images
//add voice chat


//TODO not needed
//add message read
//message reactions
//typing text
//unsend messages
//display if they are online or not, and if are in chat
//add back typing detection
//add when user has seen messages
//fix crash on websocket close
//make message unloading when scrolling up
