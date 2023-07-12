
const express = require('express');
const router = express.Router();
const { database } = require('./database');
const { testToken } = require('./userLogin');
const { generateRandomString } = require('./utilFunctions');






async function updatePostRating(rootItem){
  var postRatingsCollection = database.collection('post_ratings');
  var postsCollection = database.collection('posts');


  const ratings = await postRatingsCollection.find({ "rootItem.data" : rootItem.data, "rootItem.type" : rootItem.type }).toArray();

  var newRating = 0;

  for (var i = 0; i < ratings.length; i++) {
    newRating += ratings[i].rating;
  }

  if (ratings.length != 0) {
    newRating = newRating / ratings.length;
  }

  const response = await postsCollection.updateOne({postId : rootItem.data},{ $set: {rating : newRating}})

  if (response.acknowledged === true) {
    return true;
  }else{
    return false;
  }

}



router.post('/post/rating/delete', async (req, res) => {
  console.log(" => user fetching rating data")
    try{
      const token = req.body.token;
      //const parentItem = req.body.parentItem; ------not yet added
      const ratingId = req.body.ratingId;
      var vaildToken, userId;
  
      [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
    
      if (vaildToken) { // user token is valid
        var postsCollection = database.collection('posts');
        var postRatingsCollection = database.collection('post_ratings');
        var posts;

        //fetch the post
        const ratingData = await postRatingsCollection.findOne({ ratingId :  ratingId})
        if (ratingData == null) {
          console.log("no post found");
          return res.status(400).send("no post found");
        
        }

        //test if comment is your's
        if (ratingData.ratingPosterId != userId){
          console.log("post not yours");
          return res.status(400).send("post not yours");
        }




        const reponse = await postRatingsCollection.deleteOne({ratingId : ratingId})
        if (reponse.acknowledged === true){
          console.log("post deleted")
          updatePostRating(ratingData.rootItem);
          return res.status(200).send("post deleted");
        }else{
          console.log("failed to delete post");
          return res.status(400).send("failed to delete post");
        }
        
        




        
  
      }else{
        console.log("invaild token");
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error");
    }
})



router.post('/post/rating/data', async (req, res) => {
  console.log(" => user fetching rating data")
    try{
      const token = req.body.token;
      //const parentItem = req.body.parentItem; ------not yet added
      const ratingId = req.body.ratingId;
      const shareMode = req.body.shareMode;
      var vaildToken, userId;
  
      [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
    
      if (vaildToken) { // user token is valid
        var postsCollection = database.collection('posts');
        var postRatingsCollection = database.collection('post_ratings');
        var posts;

        //fetch the post
        const ratingData = await postRatingsCollection.findOne({ ratingId :  ratingId})
        if (ratingData == null) {
          return res.status(400).send("no post found");
        
        }
        const rootItem = ratingData.rootItem;

        //extract root item info
        if (!rootItem) {
          return res.status(400).send("no root item");
        }
        const rootItemData = await postsCollection.findOne({ postId : rootItem.data })
        if (!rootItemData){
          return res.status(400).send("invaild root post");
        }
        if (rootItemData.shareMode != "public") {
          return res.status(400).send("root post not shared to you");
        }

        if (ratingData.shareMode != "public") {
          return res.status(400).send("rating not shared to you");
        }

        updatePostRating(rootItem);
        //test if they have already commented
        return res.status(200).json({
          rating : ratingData.rating,
          text : ratingData.text,
          ratingPosterId : ratingData.ratingPosterId,
          rootItem: ratingData.rootItem,
        });



        
  
      }else{
        console.log("invaild token");
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error");
    }
})



router.post('/post/rating/upload', async (req, res) => {
  console.log(" => user fetching post ratings")
    try{
      const token = req.body.token;
      //const parentItem = req.body.parentItem; ------not yet added
      const rootItem = req.body.rootItem;
      const rating = req.body.rating;
      const text = req.body.text;
      const shareMode = req.body.shareMode;
      var vaildToken, userId;
  
      [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
    
      if (vaildToken) { // user token is valid
        var postsCollection = database.collection('posts');
        var postRatingsCollection = database.collection('post_ratings');
        var posts;

        //extract root item info
        if (!rootItem) {
          return res.status(400).send("no root item");
        }
        const rootItemData = await postsCollection.findOne({ postId : rootItem.data })
        if (!rootItemData){
          return res.status(400).send("invaild root post");
        }
        if (rootItemData.shareMode != "public") {
          return res.status(400).send("root post not shared to you");
        }

        //test if they have already commented
        const alreadyExistComment = await postRatingsCollection.findOne({ ratingPosterId :  userId, rootItem : {type: rootItem.type, data: rootItem.data},})
        if (alreadyExistComment) {
          return res.status(400).send("you have already rated");
        }

        //report error if shareMode is public
        if (!shareMode) {
          return res.status(400).send("share mode can't be nothing");
        }

        //test that text and rating values are correct
        if (!rating) {
          return res.status(400).send("no rating provided");
        }
        if (rating < 0 || rating > 5) {
          return res.status(400).send("invaild rating");
        }
        if (!text) {
          return res.status(400).send("no text provided");
        }
        if (text.length > 500) {
          return res.status(400).send("text to large");
        }

        //upload id
        var ratingId;
        while (true){
          ratingId =  generateRandomString(16);
  
          let ratingIdInUse = await postRatingsCollection.findOne({ratingId: ratingId});
          if (ratingIdInUse === null){
            break
          }
        }
  
        
        const postResponse = await postRatingsCollection.insertOne({
          rootItem : {"type": rootItem.type, "data": rootItem.data},
          ratingId: ratingId,
          text: text,
          creationDate: Date.now(),
          ratingPosterId: userId,
          rating: rating,
          shareMode: shareMode,

        })

        if (postResponse.acknowledged === true) {
          updatePostRating(rootItem);
          console.log("post uploaded");
          return res.status(200).send("post uploaded");

        }else{
          console.log("failed uploading rating");
          return res.status(401).send("failed uploading rating");

        }
        
  
      }else{
        console.log("invaild token");
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error");
    }
})



router.post('/post/ratings', async (req, res) => {
  console.log(" => user fetching post ratings")
    try{
      const token = req.body.token;
      //const parentItem = req.body.parentItem; ------not yet added
      const rootItem = req.body.rootItem;
      const startPosPost = req.body.startPosPost;
      var startPosPostDate = 100000000000000
      var vaildToken, userId;
  
      [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
    
      if (vaildToken) { // user token is valid
        var postsCollection = database.collection('posts');
        var postRatingsCollection = database.collection('post_ratings');
  
        //extract start item data
        if (startPosPost) {
          if (startPosPost.type === "rating" && !startPosPost.data){
            return res.status(400).send("invaild start post");
          }

          const startPosPostData = await postsCollection.findOne({ ratingId: startPosPost.data, rootItem : rootItem })
          if (!startPosPostData){
            return res.status(400).send("invaild start post");
          }
            
          startPosPostDate = startPosPostData.postDate;
        }

        //extract root item info
        if (!rootItem) {
          return res.status(400).send("no root item");
        }
        const rootItemData = await postsCollection.findOne({ postId : rootItem.data })
        if (!rootItemData){
          return res.status(400).send("invaild root post");
        }
        if (rootItemData.shareMode != "public") {
          return res.status(400).send("root post not shared to you");
        }

        const posts = await postRatingsCollection.find({ shareMode: 'public', creationDate: { $lt: startPosPostDate}, "rootItem.data" : rootItem.data, "rootItem.type" : rootItem.type }).sort({postDate: -1}).limit(5).toArray();

        var returnData = {}
        returnData["items"] = []
   
        if (posts.length == 0) {
          console.log("nothing to fetch");
        }
  
        for (var i = 0; i < posts.length; i++) {
          returnData["items"].push({
            type : "rating",
            data : posts[i].ratingId
          });
          //Do something
        }
        
        console.log("returning posts");
        return res.status(200).json(returnData);
  
      }else{
        console.log("invaild token");
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error");
    }
})

  
module.exports = {
    router:router,
};