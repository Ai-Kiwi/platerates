import express from 'express';
const router = express.Router();
import { database } from "./database";
import mongoDB from "mongodb";
import { generateRandomString } from "./utilFunctions";
import { time } from "console";
import { testToken } from "./userLogin";
import { json } from 'node:stream/consumers';

async function sendNotification(notificationData : {userId : string, action : string, itemId : string | undefined}){
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
                receiverId : notificationData.userId,
                read : false,
                sentDate : Date.now(),
                deviceReceived : false,
            })

            if (response.acknowledged === true){
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
                receiverId : notificationData.userId,
                read : false,
                sentDate : Date.now(),
                deviceReceived : false,
            })

            if (response.acknowledged === true){
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
    console.log(" => user searching")
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
  
            const startPosPostData = await collection.findOne({ userId: startPosPost.data })
            if (startPosPostData === null){
              console.log("invalid start notification")
              return res.status(400).send("invalid start notification");
            }
              
            startPosInfo = startPosPostData.sentDate;
          }
    
          const dataReturning = await collection.find({ sentDate: { $lt: startPosInfo}}).sort({sentDate : -1}).limit(15).toArray();
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

//scrollable notifications
//view notification data
//phone get notfcations to send
//phone notfication sent

export {
    router,
    sendNotification
}