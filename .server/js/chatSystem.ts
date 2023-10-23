import express from "express";
import { generateRandomString } from "./utilFunctions";
const router = express.Router();
import { databases } from "./database";
import mongoDB, { Int32 } from "mongodb";
import { Request, Response } from "express";
import { sendNotification, sendNotificationToDevices } from "./notificationSystem";
import { testTokenValid } from "./userLogins";
import { confirmActiveAccount, confirmTokenValid } from "./securityUtils";


let wsClients : Record<string, any> = []


router.ws('/chatWs', function(ws, req) {
    var connectionId = generateRandomString(16);
    while (wsClients[connectionId] != undefined) {
        connectionId = generateRandomString(16);
    }


    wsClients[connectionId] = {
        ws : ws,

    }

    console.log(`websocket connection made with id ${connectionId}`)



    ws.on('message', async (msg) => {
      try{
        console.log("chat websocket message")
        var jsonData = JSON.parse(msg.toString());


        if (jsonData["request"] == "authenticate") {
            //attempt user token
            const userIpAddress : string = req.socket.remoteAddress as string;
            const result = await testTokenValid(jsonData["token"],userIpAddress);
            const vaildToken : boolean = result.valid;
            const userId : string | undefined = result.userId;

            if (vaildToken){
                wsClients[connectionId].userId = userId;
                
                //attempt to join the chat room
                let chatRoomData = await databases.chat_rooms.findOne({ chatRoomId: jsonData["chatRoomId"], users: { $all: [userId] } })

                if (chatRoomData != null){
                    wsClients[connectionId].chatRoomId = jsonData["chatRoomId"];
                    console.log("authenticated client")

                    let privateChatOtherUser = null;
                    if (chatRoomData["privateChat"] === true){
                        //it is a private chat so get data about it
                        if (chatRoomData.users[0] !== wsClients[connectionId].userId){
                            privateChatOtherUser = chatRoomData.users[0]
                        }else{
                            privateChatOtherUser = chatRoomData.users[1]
                        }   
                    }


                    ws.send(JSON.stringify({
                        success : true,
                        action : "authenticated",
                        data : {
                            chatRoomId : jsonData["chatRoomId"],
                            userId : userId,
                            privateChat : chatRoomData["privateChat"],
                            privateChatOtherUser: privateChatOtherUser,
                        }
                    }));

                }else{
                    ws.send(JSON.stringify({
                        success : false,
                        reason : "can't view chat room"
                    }));
                    ws.close();
                }


            }else{
                console.log("invalid token")
                ws.send(JSON.stringify({
                    success : false,
                    reason : "invalid token"
                }));
                ws.close();
            }
        }else if (jsonData["request"] == "send_message") {
            var messageId;
            while (true) {
                messageId = generateRandomString(16);
                const dataBaseMessage = await databases.chat_messages.findOne({messageId : messageId});
                if (dataBaseMessage === null){
                    break;
                }
            }

            if (typeof jsonData["text"] !== "string" ){
                ws.send(JSON.stringify({
                    success : false,
                    reason : "no text given"
                }));
                return;
            }
            
            if ((jsonData["text"] as String).length > 1000){
                ws.send(JSON.stringify({
                    success : false,
                    reason : "text to large"
                }));
                return;
            }

            const sendTime = Date.now()

            const dataSending = {
                messageId : messageId,
                text : jsonData["text"],
                messagePoster : wsClients[connectionId].userId,
                chatRoomId : wsClients[connectionId].chatRoomId,
                sendTime : sendTime,
            }



            const messageDatabaseResponse = await databases.chat_messages.insertOne(dataSending)

            if (messageDatabaseResponse.acknowledged === true){
                if (wsClients[connectionId].chatRoomId){
                  let chatRoomData = await databases.chat_rooms.findOne({ chatRoomId: wsClients[connectionId].chatRoomId})
                  let chatSenderUserData = await databases.user_data.findOne({ userId: wsClients[connectionId].userId})




                  let usersToSendTo : Array<String> = chatRoomData ? chatRoomData.users : {} 
                  for (let key in wsClients) {
                      if (wsClients[connectionId].chatRoomId === wsClients[key].chatRoomId){
                          wsClients[key].ws.send(JSON.stringify({
                              action : "new_message",
                              data : dataSending,
                              
                          }))


                          if (usersToSendTo.indexOf(wsClients[key].userId) != undefined){
                            usersToSendTo.splice(usersToSendTo.indexOf(wsClients[key].userId));
                          }
                      }
                  }
                  
                  if (chatRoomData != null && chatSenderUserData != null){
                    console.log(usersToSendTo)
                    if (chatRoomData.privateChat === true){
                      sendNotificationToDevices(chatSenderUserData.username,dataSending.text,"newMessage",usersToSendTo,"this does nothing rn");
                    }else{
                      sendNotificationToDevices(chatRoomData.chatName,`${chatSenderUserData.username} : ${dataSending.text}`,"newMessage",usersToSendTo,"this does nothing rn");
                    }
                    
                  }
                    
                  
                }
            }
            

        }else if (jsonData["request"] == "past_messages") {
            const messages = await databases.chat_messages.find({ chatRoomId: wsClients[connectionId].chatRoomId, sendTime: { $lt: jsonData["pastItemDate"]}}).sort({sendTime: -1}).limit(25).toArray();
            let returnData = {
              "items": [] as { type: string; data: string;}[]
            }
       
            if (messages.length == 0) {
              console.log("nothing to fetch");
            }
      
            for (var i = 0; i < messages.length; i++) {
                ws.send(JSON.stringify({
                    action : "past_message",
                    data : messages[i],
                    
                }))
            }

        }else{
            console.log("unkown command")
            ws.send(JSON.stringify({
                success : false,
                reason : "unkown command"
            }));
        }
        
    }catch (err){
        console.log("server error")
        console.log(err);
        ws.send(JSON.stringify({
            success : false,
            reason : "server error"
        }));
        ws.close();
    }
    });


    ws.on('close', async (msg) => {
        console.log(`closed websocket connection ${connectionId}`)
        delete wsClients[connectionId];
    });


  
});

//smart little function to kill broken connections
//const interval = setInterval(function ping() {
//    for (let key in wsClients) {
//        const ws = wsClients[key].ws;
//
//        if (ws.isAlive === false) return ws.terminate();
//
//        wsClients[key].ws.isAlive = false;
//        ws.ping();
//    };
//}, 30000); { $lt: jsonData["pastItemDate"]}}).sort({sendTime: -1}).limit(25).toArray();


//let collection: mongoDB.Collection = database.collection('chat_rooms');
//
//collection.insertOne({
//    chatRoomId : generateRandomString(16),
//    privateChat : true,
//    users : ["TBAvGVwBF5i0S856","Gy4YCkEBsGWCRcHd"]
//}),


router.post('/chat/openList', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
    console.log(" => user fetching feed")
    try{
      const startPosPost = req.body.startPosPost;
      let startPosPostDate: number = 100000000000000
      const userId : string | undefined = req.body.tokenUserId;
  
      if (startPosPost) {
        if (startPosPost.type === "chat_room" && !startPosPost.data){
          console.log("invalid start chat")
          return res.status(400).send("invalid start chat");
        }

        const startPosPostData = await databases.chat_rooms.findOne({ chatRoomId: startPosPost.data, users: { $all: [userId] } })
        if (!startPosPostData){
          console.log("invalid start chat")
          return res.status(400).send("invalid start chat");
        }

        startPosPostDate = startPosPostData.postDate;
      }
  
      const posts = await databases.chat_rooms.find({ users: { $all: [userId] }, lastMessage: { $lt: startPosPostDate}}).sort({lastMessage: -1}).limit(5).toArray();
      let returnData = {
        "items": [] as { type: string; data: string;}[]
      }

      if (posts.length == 0) {
        console.log("nothing to fetch");
      }
  
      for (var i = 0; i < posts.length; i++) {
        if (posts[i].userId !== null) {
          returnData["items"].push({
            type : "chat_room",
            data : posts[i].chatRoomId,
          });
        }
      }

      console.log("returning chats");
      return res.status(200).json(returnData);
    }catch(err){
      console.log(err);
      return res.status(500).send("server error");
    }
})



router.post('/chat/roomData', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
    console.log(" => user fetching chat room data")
      try{
        const token = req.body.token;
        const chatRoomId = req.body.chatRoomId;
        const userIpAddress : string = req.headers['x-forwarded-for'] as string;
        const onlyUpdateChangeable = req.body.onlyUpdateChangeable;
        const userId : string = req.body.tokenUserId;
  
        
      
        var itemData = await databases.chat_rooms.findOne({chatRoomId: chatRoomId})
  
        if (itemData === null) {
          console.log("invalid chat room");
          return res.status(404).send("invalid chat room");
        }
  
        if ((itemData.users as Array<any>).includes(userId) === false){
          console.log("user not in chat room");
          return res.status(403).send("user not in chat room");
        }


        //used so there is less code on client
        let privateChatOtherUser = null;
        if (itemData["privateChat"] === true){
            //it is a private chat so get data about it
            if (itemData.users[0] !== userId){
              privateChatOtherUser = itemData.users[0]
            }else{
              privateChatOtherUser = itemData.users[1]
            }   
        }

        console.log("sending post data");
        if (onlyUpdateChangeable === true) {
          return res.status(200).json({
            chatRoomId : itemData.chatRoomId,
            lastMessage : itemData.lastMessage,
            users : itemData.users,
            chatName : itemData.chatName,
            privateChatOtherUser : privateChatOtherUser,
          });
        }
        return res.status(200).json({
          chatRoomId : itemData.chatRoomId,
          privateChat : itemData.privateChat,
          lastMessage : itemData.lastMessage,
          users : itemData.users,
          chatName : itemData.chatName,
          privateChatOtherUser : privateChatOtherUser,

          
        });
      }catch(err){
        console.log(err);
        return res.status(500).send("server error")
      }
  })


  router.post('/chat/openChat', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
    console.log(" => user opening chat")
      try{
        const chatUserId = req.body.chatUserId;
        const userId : string | undefined = req.body.tokenUserId;
      
        var chatRoomData = await databases.chat_rooms.findOne({privateChat : true, users : { "$all" : [userId, chatUserId]} })
  
        var otherUserData = await databases.user_data.findOne({userId : chatUserId})

        //make sure other users exist
        if (otherUserData === null){
          console.log("other user not found");
          return res.status(404).send("other user not found");
        }

        if (userId == chatUserId){
          console.log("cannot be same user");
          return res.status(400).send("cannot be same user");
        }

        var chatRoomId = "";
        if (chatRoomData === null) {
          //need to make chatroom
          while (true) {
            chatRoomId = generateRandomString(16);
            var testingChatRoomData = await databases.chat_rooms.findOne({chatRoomId : chatRoomId})
            if (testingChatRoomData === null){
              break
            }
            console.log("chat room id already in use trying another")
            
          }

          const response = await databases.chat_rooms.insertOne({
            "creationDate": Date.now(),
            "chatRoomId": chatRoomId,
            "chatName": "",
            "privateChat": true,
            "lastMessage": 0,
            "users": [
              userId,
              chatUserId
            ]
          })

          if (response.acknowledged == false){
            console.log("failed creating chat");
            return res.status(500).send("failed creating chat");
          }

        }else{
          chatRoomId = chatRoomData.chatRoomId;
        }

        console.log("sending chat data");
        return res.status(200).json({
          chatRoomId : chatRoomId,
        });
      }catch(err){
        console.log(err);
        return res.status(500).send("server error")
      }
  })



export {
    router,
}