const express = require('express');
const router = express.Router();
const { database } = require('./database');
const { testToken } = require('./userLogin');
const { generateRandomString } = require('./utilFunctions');
const { sendMail } = require('./mailsender');



router.post('/report', async (req, res) => {
  console.log(" => user reporting item")
  try{
    const token = req.body.token;
    const reportItem = req.body.reportItem;
    const reason = req.body.reason;
    [validToken, userId] = await testToken(token,req.headers['x-forwarded-for']);
    const reportsCollection = database.collection('reports');
    const userCredentialsCollection = database.collection('user_credentials')

    if (validToken){

      var rootItem = {
        type: reportItem.type,
        data: reportItem.data
      }

      //test if item already reported
      const userReportItem = await reportsCollection.findOne({item : rootItem, reporterId : userId})
      if (userReportItem !== null) {
        console.log("already reported");
        return res.status(409).send("already reported")
      }

      var reportingItem;

      if (reportItem.type === "post"){
        const postsollection = database.collection('posts');
        reportingItem = await postsollection.findOne({postId : reportItem.data});

      }else if (reportItem.type === "post_rating"){
        const postRatingsollection = database.collection('post_ratings');
        reportingItem = await postRatingsollection.findOne({ratingId : reportItem.data});

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


      var reportId;
      while (true){
        reportId =  generateRandomString(16);

        let postIdInUse = await reportsCollection.findOne({reportId: reportId});
        if (postIdInUse === null){
          break
        }
      }

      const response = await reportsCollection.insertOne(
        {
          item: rootItem,
          reporterId : userId,
          reportId: reportId,
          reason : reason,
        }
      )

      if (response.acknowledged === true){
        try{
          const userCredentials = await userCredentialsCollection.findOne({userId:userId})



          sendMail(
          '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
          userCredentials.email,
          "reported item",
          "thank you for reporting an item on toaster, we will get back to you shortly with our response to your report."
          );

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




    }
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

module.exports = {
    router:router,
};