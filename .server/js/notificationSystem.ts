import express from 'express';
const router = express.Router();
import { database } from "./database";
import mongoDB from "mongodb";
import { generateRandomString } from "./utilFunctions";
import { time } from "console";
import { testToken } from "./userLogin";
import { json } from 'node:stream/consumers';
import firebase from 'firebase-admin'

// Create a list containing up to 500 registration tokens.
// These registration tokens come from the client FCM SDKs.


async function sendNotificationToDevices(title : String, body : String, channelId : String, userIds : Array<String>, notificationId : String | undefined) {
  console.log("sending notifications to devices")

  const collection: mongoDB.Collection = database.collection('user_data');
  
  const registrationTokens : Array<String> = [];
  
  let i = 0;
  while (i < userIds.length) {
    const avatarData = await collection.findOne({ userId: userIds[i] });
    
    if (avatarData !== null){
      if (avatarData!.deviceNotificationTokens !== null){
        avatarData!.deviceNotificationTokens.forEach((element : String) => {
          registrationTokens.push(element);
        });
      }
    }
    i++;
  }
  
  const message : any = {
    notification: {
      body: body,
      title: title
   },
   priority: "high",
    data: {
      title: title,
      body: body,
      channelId : channelId,
      notificationId : notificationId, 
    },
    tokens: registrationTokens,
  };

  console.log(JSON.stringify(message));

  if (registrationTokens.length < 1) {
    console.log("no tokens found no sending no notifcations")
    return;
  }
  
  console.log("sending notifcations")
  firebase.messaging().sendEachForMulticast(message)
  .then((response) => {
    console.log(response.successCount + ' messages were sent successfully');
  });

}


async function fetchUsername(userId : string){
  const collection: mongoDB.Collection = database.collection('user_data');

  const userData = await collection.findOne({ userId: userId });

  if (userData != null) {
    return userData.username
  }else{
    return "invalid user"
  }

}


router.post('/notification/updateDeviceToken', async (req, res) => {
  console.log(" => user update device token")
    try{
      const token = req.body.token;

      const newToken = req.body.newToken;
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const validToken : boolean = result.valid;
      const userId : string | undefined = result.userId;
    
      if (validToken) { // user token is valid
        const userDataCollection : mongoDB.Collection = database.collection('user_data');

        const response = await userDataCollection.updateOne({userId : userId},{ $set: {deviceNotificationTokens : [newToken]}});

        console.log("updated")
        return res.status(200).send("updated token");

      }else{
        console.log("invalid token");
        return res.status(401).send("invalid token");
      }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error");
    }
})


async function sendNotification(notificationData : {userId : string | undefined, action : string, itemId : string | undefined, receiverId : string}){
    try{
        const collection : mongoDB.Collection = database.collection("user_notifications");
        
        let notificationId;
        while (true){
            notificationId = generateRandomString(16);

            let notificationIdInUse = await collection.findOne({notificationId: notificationId});
            if (notificationIdInUse === null){
              break
            }
        }

        if (notificationData.action === "user_rated_post") {
            const response = await collection.insertOne({
                notificationId: notificationId,
                action : notificationData.action,
                itemId : notificationData.itemId,
                receiverId : notificationData.receiverId,
                userId : notificationData.userId,
                read : false,
                sentDate : Date.now(),
                deviceReceived : false,
            })

            if (response.acknowledged === true){
              const notificationDataFromDatabase = await collection.findOne({ notificationId: notificationId })
              sendNotificationToDevices(`toast rating`,`${await fetchUsername(notificationData.userId!)} rated your toast`,`userRating`,[notificationData.receiverId], JSON.stringify(notificationDataFromDatabase))
              console.log("sent notification");
            }else{
              console.log("failed sending notification");
            }

        //}else if (notificationData.action === "user_login") {
        //    collection.insertOne({
        //        notificationId: notificationId,
        //        action : notificationData.action,
        //    })
        //
        }else if (notificationData.action === "user_reply_post_rating") {
            const response = await collection.insertOne({
                notificationId: notificationId,
                action : notificationData.action,
                itemId : notificationData.itemId,
                receiverId : notificationData.receiverId,
                userId : notificationData.userId,
                read : false,
                sentDate : Date.now(),
                deviceReceived : false,
            })

            if (response.acknowledged === true){
              const notificationDataFromDatabase = await collection.findOne({ notificationId: notificationId })
              sendNotificationToDevices(`message reply`,`${await fetchUsername(notificationData.userId!)} replied to you`,`userComment`,[notificationData.receiverId], JSON.stringify(notificationDataFromDatabase))
              console.log("sent notification");
            }else{
              console.log("failed sending notification");
            }

        }else{
            console.log("unkown notification data");
        }

    }catch (err){
        console.log(err);
    }
}


router.post('/notification/list', async (req, res) => {
    console.log(" => user fetching notifications")
      try{
        const searchText = req.body.searchText;
        const token = req.body.token;
        const startPosPost = req.body.startPosPost;
        let startPosInfo: number = 100000000000000

        const userIpAddress : string = req.headers['x-forwarded-for'] as string;

        const result = await testToken(token,userIpAddress);
        const validToken : boolean = result.valid;
        const userId : string | undefined = result.userId;
      
        if (validToken) { // user token is valid
          let collection: mongoDB.Collection = database.collection('user_notifications');
    
          if (startPosPost) {
            if (startPosPost.type === "notification" && !startPosPost.data){
              console.log("invalid start notification")
              return res.status(400).send("invalid start notification");
            }
            //unlike others data is a json object and has noti data in there
            const notificationData = JSON.parse(startPosPost.data);

            const startPosPostData = await collection.findOne({ notificationId: notificationData.notificationId })
            if (startPosPostData === null){
              console.log("invalid start notification")
              return res.status(400).send("invalid start notification");
            }
              
            startPosInfo = startPosPostData.sentDate;
          }
    
          const dataReturning = await collection.find({ sentDate: { $lt: startPosInfo}, receiverId : userId}).sort({sentDate : -1}).limit(15).toArray();
          let returnData = {
            "items": [] as { type: string; data: string;}[]
          }
     
          if (dataReturning.length == 0) {
            console.log("nothing to fetch");
          }


          for (var i = 0; i < dataReturning.length; i++) {
            if (dataReturning[i].userId !== null) {
              returnData["items"].push({
                type : "notification",
                data : JSON.stringify(dataReturning[i]),
              });
            }
          }
          
          console.log("returning notifications");
          return res.status(200).json(returnData);
    
        }else{
          console.log("invalid token");
          return res.status(401).send("invalid token");
        }
      }catch(err){
        console.log(err);
        return res.status(500).send("server error");
      }
  })


router.post('/notification/read', async (req, res) => {
  console.log(" => user marking notification as read")
    try{
      const notificationId = req.body.notificationId;
      const token = req.body.token;
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;
      const result = await testToken(token,userIpAddress);
      const validToken : boolean = result.valid;
      const userId : string | undefined = result.userId;
    
      if (validToken) { // user token is valid
        let collection: mongoDB.Collection = database.collection('user_notifications');
  
        let postFetching = await collection.findOne({notificationId : notificationId});

        if (postFetching === null){
          console.log("notification not found");
          return res.status(404).send("notification not found");
        }

        if (postFetching.receiverId !== userId){
          console.log("user doesn't own notification");
          return res.status(403).send("notification not yours");
        }


        let markReadResponse = await collection.updateOne({notificationId : notificationId},{$set: {read : true}});

        if (markReadResponse.acknowledged === true){
          console.log("marked notification read");
          return res.status(200).send("notification marked as read");
        }else{
          console.log("error marking read");
          return res.status(200).send("error marking notification read");
        }

        

  
      }else{
        console.log("invalid token");
        return res.status(401).send("invalid token");
      }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error");
    }
})

//scrollable notifications
//view notification data
//phone get notfcations to send
//phone notfication sent

export {
    router,
    sendNotification
}