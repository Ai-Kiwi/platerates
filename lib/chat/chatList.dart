import 'dart:convert';

import 'package:Toaster/chat/openChat.dart';
import 'package:Toaster/libs/dataCollect.dart';
import 'package:Toaster/libs/lazyLoadPage.dart';
import 'package:Toaster/libs/userAvatar.dart';
import 'package:Toaster/main.dart';
import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;

class chatBarItem extends StatefulWidget {
  final chatItem;

  const chatBarItem({required this.chatItem});

  @override
  State<chatBarItem> createState() => _chatBarItemState(chatItem: chatItem);
}

class _chatBarItemState extends State<chatBarItem> {
  final chatItem;
  var chatRoomImageData;
  bool dataLoaded =
      false; //this really needs to be added lmao but will do when so and so what not
  bool unreadMessages = true;
  String chatRoomName = "";

  Future<void> _fetchOpenChatData() async {
    Map dataGatherd =
        await dataCollect.getChatRoomData(chatItem, context, false);

    if (dataGatherd["privateChat"] == true) {
      Map otherUserData = await dataCollect.getBasicUserData(
          dataGatherd["privateChatOtherUser"], context, false);

      Map avatarData = await dataCollect.getAvatarData(
          otherUserData["avatar"], context, false);

      setState(() {
        chatRoomName = otherUserData["username"];

        if (avatarData["imageData"] != null) {
          chatRoomImageData = base64Decode(avatarData["imageData"]);
        }
        if (dataGatherd["relativeViewerData"] != null) {
          unreadMessages =
              dataGatherd["relativeViewerData"]["hasUnreadMessages"];
        }

        dataLoaded = true;
      });
    } else {
      //
    }
  }

  Future<void> _fetchAndUpdateOpenChatData() async {
    await _fetchOpenChatData();
    if (await dataCollect.updateChatRoomData(chatItem, context, false) ==
        true) {
      await _fetchOpenChatData();
    }
  }

  @override
  void initState() {
    //jsonData = jsonDecode(notificationData);
    super.initState();
    _fetchAndUpdateOpenChatData();
    updateUnreadNotificationCount();
  }

  _chatBarItemState({required this.chatItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
      child: Container(
        width: double.infinity,
        child: GestureDetector(
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      UserAvatar(
                        avatarImage: chatRoomImageData,
                        size: 45,
                        roundness: 45,
                        onTapFunction: null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                        chatRoomName,
                        style: unreadMessages
                            ? const TextStyle(color: Colors.white, fontSize: 20)
                            : const TextStyle(color: Colors.grey, fontSize: 20),
                      )),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FullPageChat(
                          chatRoomId: chatItem,
                        )),
              );
            }),
      ),
    );
  }
}

class FullPageChatList extends StatefulWidget {
  @override
  _fullPageChatListState createState() => _fullPageChatListState();
}

class _fullPageChatListState extends State<FullPageChatList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const LazyLoadPage(
      openFullContentTree: false,
      widgetAddedToTop: Column(children: [
        SizedBox(height: 32),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "Open chats",
              style: TextStyle(color: Colors.white, fontSize: 40),
            )),
        Divider(
          color: Color.fromARGB(255, 110, 110, 110),
          thickness: 1.0,
        ),
        SizedBox(
          height: 16,
        )
      ]),
      urlToFetch: "/chat/openList",
      widgetAddedToEnd: Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "end of chats.",
              style: TextStyle(color: Colors.white, fontSize: 25),
            )),
      ),
      widgetAddedToBlank: Center(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Text(
              "no open chats to display",
              style: TextStyle(color: Colors.white, fontSize: 25),
            )),
      ),
    );
  }
}
