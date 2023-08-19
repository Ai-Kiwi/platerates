import { database } from "./database";
import mongoDB from "mongodb";
import { generateRandomString } from "./utilFunctions";
import { time } from "console";

async function sendNotification(notificationData : {userId : string, action : string, itemId : string}){
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

//scrollable notifications
//view notification data
//phone get notfcations to send
//phone notfication sent

export {
    sendNotification
}