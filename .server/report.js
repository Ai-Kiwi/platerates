const express = require('express');
const router = express.Router();
const { database } = require('./database');
const { testToken } = require('./userLogin');
const { generateRandomString } = require('./utilFunctions');



router.post('/report', async (req, res) => {
  console.log(" => user fetching profile")
  try{
    const token = req.body.token;
    const reportItem = req.body.reportItem;
    [validToken, userId] = await testToken(token,req.headers['x-forwarded-for']);
    const reportsCollection = database.collection('reports');

    if (validToken){

      var rootItem = {
        type: reportItem.type,
        data: reportItem.data
      }

      //test if item already reported
      const userReportItem = await reportsCollection.findOne({item : rootItem, reporterId : userId})
      if (userReportItem !== null) {
        return res.status(500).send("already reported that")
      }

      if (reportItem.type === "post"){
        const postsollection = database.collection('posts');

        const reportingItem =  await postsollection.findOne({postId : reportItem.data});

        if (reportingItem === null) {
          return res.status(500).send("item does not exist")
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
          }
        )

        if (response.acknowledged === true){
          return res.status(200).send("reported")
        }else{
          return res.status(500).send("failed creating report")
        }

         

      }else if (reportItem.type === "post_rating"){
        const postRatingsollection = database.collection('post_ratings');

        const reportingItem =  await postRatingsollection.findOne({ratingId : reportItem.data});

        if (reportingItem === null) {
          return res.status(500).send("item does not exist")
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
          }
        )

        if (response.acknowledged === true){
          return res.status(200).send("reported")
        }else{
          return res.status(500).send("failed creating report")
        }

      }else{
        return res.status(500).send("unkown type")
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