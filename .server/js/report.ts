import express from 'express';
const router = express.Router();

import mongoDB from "mongodb";
import { Request, Response } from "express";
import { databases } from'./database';
import { generateRandomString } from'./utilFunctions';
import { sendMail } from'./mailsender';
import { confirmTokenValid } from './securityUtils';



router.post('/report', confirmTokenValid, async (req, res) => {
  console.log(" => user reporting item")
  try{
    const reportItem = req.body.reportItem;
    const reason = req.body.reason as String;
    const userId : string | undefined = req.body.tokenUserId;

    let rootItem = {
      type: reportItem.type,
      data: reportItem.data
    }

    //test if item already reported
    const userReportItem = await databases.reports.findOne({item : rootItem, reporterId : userId})
    if (userReportItem !== null) {
      console.log("already reported");
      return res.status(409).send("already reported")
    }

    let reportingItem;

    if (reportItem.type === "post"){
      reportingItem = await databases.posts.findOne({postId : reportItem.data});

    }else if (reportItem.type === "post_rating"){
      reportingItem = await databases.post_ratings.findOne({ratingId : reportItem.data});

    }else if (reportItem.type === "chat_message"){
      reportingItem = await databases.chat_messages.findOne({messageId : reportItem.data});

    }else{
      console.log("unkown type");
      return res.status(409).send("unkown type")

    }


    if (reportingItem === null) {
      console.log("item does not exist");
      return res.status(404).send("item does not exist")
    }

    if (reason.length > 1000){
      console.log("reason to large");
      return res.status(400).send("reason to large")
    }
    if (reason.length < 5){
      console.log("reason to small");
      return res.status(409).send("reason to small")
    } 


    let reportId: string;
    while (true){
      reportId =  generateRandomString(16);

      let postIdInUse = await databases.reports.findOne({reportId: reportId});
      if (postIdInUse === null){
        break
      }
    }

    const response = await databases.reports.insertOne(
      {
        item: rootItem,
        reporterId : userId,
        reportId: reportId,
        reason : reason,
      }
    )

    if (response.acknowledged === true){
      try{
        const userCredentials = await databases.user_credentials.findOne({userId:userId})


        if (userCredentials !== null){
        sendMail(
          '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
          userCredentials.email,
          "reported item",
          "thank you for reporting an item on toaster, we will get back to you shortly with our response to your report."
          );
        }

        sendMail(
          '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
          "toaster@aikiwi.dev",
          "reported item",
          "RING RING! NEW ITEM HAS BEEN REPORTED!\nYOU BETTER GET ONTO THIS ASAP"
        );


      }catch (err){
        console.log(err);
      }

      console.log("reported");
      return res.status(201).send("reported")
    }else{
      console.log("failed reporting");
      return res.status(500).send("failed reporting")
    }

  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

export {
  router,
};