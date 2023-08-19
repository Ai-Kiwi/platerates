
import express from 'express';
const router = express.Router();
import { database } from './database';
import { testToken } from './userLogin';
import { generateRandomString } from './utilFunctions';
import { testUserAdmin } from './adminZone';
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { error } from 'console';


async function updatePostRating(rootItem : {data : string, type : string}){
  try{  
    var postRatingsCollection : mongoDB.Collection = database.collection('post_ratings');
    var postsCollection : mongoDB.Collection = database.collection('posts');
    var userDataCollection : mongoDB.Collection = database.collection('user_data');


    const ratings = await postRatingsCollection.find({ "rootItem.data" : rootItem.data, "rootItem.type" : rootItem.type }).toArray();

    var newRating : number = 0;

    for (var i = 0; i < ratings.length; i++) {
      newRating += ratings[i].rating;
    }

    if (ratings.length != 0) {
      newRating = newRating / ratings.length;
    }

    const response = await postsCollection.updateOne({postId : rootItem.data},{ $set: {rating : newRating}})

    //update user rating
    const perentPostInfo = await postsCollection.findOne({postId : rootItem.data})
    if (perentPostInfo !== null) {
      const userId : string = perentPostInfo.posterUserId;

      const userPosts = await postsCollection.find({ posterUserId : userId }).toArray();

      var userAvgRating : number = 0;

      for (var i = 0; i < userPosts.length; i++) {
        userAvgRating += userPosts[i].rating;
      }

      if (userPosts.length != 0) {
        userAvgRating = userAvgRating / userPosts.length;
      }
      const userDataResponse = await userDataCollection.updateOne({userId : userId},{ $set: {averagePostRating : userAvgRating}})
    }


    if (response.acknowledged === true) {
      return true;
    }else{
      return false;
    }
  }catch(err){
    return false;
  }
}



router.post('/post/rating/delete', async (req, res) => {
  console.log(" => user fetching rating data")
    try{
      const token = req.body.token;
      //const parentItem = req.body.parentItem; ------not yet added
      const ratingId = req.body.ratingId;
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const validToken : boolean = result.valid;
      const userId : string | undefined = result.userId;
    
      if (validToken) { // user token is valid
        var postsCollection = database.collection('posts');
        var postRatingsCollection = database.collection('post_ratings');

        //fetch the post
        const ratingData = await postRatingsCollection.findOne({ ratingId :  ratingId})
        if (ratingData == null) {
          console.log("no post found");
          return res.status(404).send("no post found");
        }

        //test if comment is your's
        if (ratingData.ratingPosterId != userId && await testUserAdmin(userId) === false){
          console.log("post not yours");
          return res.status(403).send("post not yours");
        }

        const reponse = await postRatingsCollection.deleteOne({ratingId : ratingId})
        if (reponse.acknowledged === true){
          console.log("post deleted")
          updatePostRating(ratingData.rootItem);
          return res.status(200).send("post deleted");

        }else{
          console.log("failed to delete post");
          return res.status(500).send("failed to delete post");

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



router.post('/post/rating/data', async (req, res) => {
  console.log(" => user fetching rating data")
    try{
      const token = req.body.token;
      //const parentItem = req.body.parentItem; ------not yet added
      const ratingId = req.body.ratingId;
      const shareMode = req.body.shareMode;
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const validToken : boolean = result.valid;
      const userId : string | undefined = result.userId;
    
      if (validToken) { // user token is valid
        const postsCollection : mongoDB.Collection = database.collection('posts');
        const postRatingsCollection : mongoDB.Collection = database.collection('post_ratings');

        //fetch the post
        const ratingData = await postRatingsCollection.findOne({ ratingId :  ratingId})
        if (ratingData == null) {
          console.log("failed to find post");
          return res.status(404).send("no post found");
        
        }
        const rootItem = ratingData.rootItem;

        //extract root item info
        if (!rootItem) {
          console.log("no root item attached");
          return res.status(400).send("no root item");
        }
        let rootItemData;
        if (rootItem.type === "post"){
          rootItemData = await postsCollection.findOne({ postId : rootItem.data })
        }else if (rootItem.type === "rating"){
          rootItemData = await postRatingsCollection.findOne({ ratingId : rootItem.data })
        }
        if (!rootItemData){
          console.log("root item is invalid");
          return res.status(400).send("invalid root post");
        }
        if (rootItemData.shareMode != "public") {
          console.log("post is not public")
          return res.status(400).send("root post not shared to you");
        }

        if (ratingData.shareMode != "public") {
          console.log("rating is not public")
          return res.status(400).send("rating not shared to you");
        }

        const childRatings = await postRatingsCollection.countDocuments({ "rootItem.data" : ratingId, "rootItem.type" : "rating" });



        updatePostRating(rootItem);
        console.log("response sent")
        return res.status(200).json({
          rating : ratingData.rating,
          text : ratingData.text,
          ratingPosterId : ratingData.ratingPosterId,
          rootItem: ratingData.rootItem,
          childRatingsAmount: childRatings,
        });



        
  
      }else{
        console.log("invalid token");
        return res.status(401).send("invalid token");
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
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const validToken : boolean = result.valid;
      const userId : string | undefined = result.userId;
    
      if (validToken) { // user token is valid
        const postsCollection : mongoDB.Collection = database.collection('posts');
        const postRatingsCollection : mongoDB.Collection = database.collection('post_ratings');


        

        //extract root item info
        if (!rootItem) {
          console.log("no root item");
          return res.status(400).send("no root item");
        }


        if (!text) {
          console.log("had no text attached")
          return res.status(400).send("no text provided");
        }
        if (text.length > 500) {
          console.log("text was to large")
          return res.status(400).send("text to large");
        }

        //upload id
        let ratingId : string;
        while (true){
          ratingId = generateRandomString(16);
        
          let ratingIdInUse = await postRatingsCollection.findOne({ratingId: ratingId});
          if (ratingIdInUse === null){
            break
          }
        }

        //report error if shareMode is nothing
        if (!shareMode) {
          console.log("had no share mode");
          return res.status(400).send("share mode can't be nothing");
        }


        if (rootItem.type === "post"){
          console.log("root is post");
          const rootItemData = await postsCollection.findOne({ postId : rootItem.data })
          if (!rootItemData){
            console.log("invalid root item");
            return res.status(400).send("invalid root post");
          }
          if (rootItemData.shareMode != "public") {
            console.log("root post not shared with user");
            return res.status(400).send("root post not shared to you");
          }

          //test if they have already commented
          const alreadyExistComment = await postRatingsCollection.findOne({ ratingPosterId :  userId, rootItem : {type: rootItem.type, data: rootItem.data},})
          if (alreadyExistComment) {
            console.log("you have already rated");
            return res.status(400).send("you have already rated");
          }

          if (rootItemData.posterUserId === userId) {
            console.log("you can't rate on your own post");
            return res.status(400).send("you can not rate your own post");
          }

          //test that text and rating values are correct
          if (rating === null || rating === undefined) {
            console.log("had no rating");
            return res.status(400).send("no rating provided");
          }
          if (rating < 0 || rating > 5) {
            console.log("had out of range rating")
            return res.status(400).send("invalid rating");
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
            console.log("rating uploaded");
            return res.status(201).send("rating uploaded");

          }else{
            console.log("failed uploading rating");
            return res.status(500).send("failed uploading rating");

          }


        }else if (rootItem.type === "rating"){
          console.log("root is rating");
          const rootItemData = await postRatingsCollection.findOne({ ratingId : rootItem.data })
          if (!rootItemData){
            console.log("invalid root item");
            return res.status(400).send("invalid root post");
          }
          if (rootItemData.shareMode != "public") {
            console.log("root post not shared with user");
            return res.status(400).send("root post not shared to you");
          }

          const postResponse = await postRatingsCollection.insertOne({
            rootItem : {"type": rootItem.type, "data": rootItem.data},
            ratingId: ratingId,
            text: text,
            creationDate: Date.now(),
            ratingPosterId: userId,
            shareMode: shareMode,
          })

          if (postResponse.acknowledged === true) {
            updatePostRating(rootItem);
            console.log("rating uploaded");
            return res.status(201).send("rating uploaded");

          }else{
            console.log("failed uploading rating");
            return res.status(500).send("failed uploading rating");

          }



        }else{
          console.log("invalid root item");
          return res.status(400).send("invalid root post");
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



router.post('/post/ratings', async (req, res) => {
  console.log(" => user fetching post ratings")
    try{
      const token = req.body.token;
      //const parentItem = req.body.parentItem; ------not yet added
      const rootItem = req.body.rootItem;
      const startPosPost = req.body.startPosPost;
      var startPosPostDate = 100000000000000
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const validToken : boolean = result.valid;
      const userId : string | undefined = result.userId;
    
      if (validToken) { // user token is valid
        var postsCollection = database.collection('posts');
        var postRatingsCollection = database.collection('post_ratings');
  
        //extract start item data
        if (startPosPost) {
          if (startPosPost.type === "rating" && !startPosPost.data){
            console.log("invalid start item")
            return res.status(400).send("invalid start item");
          }

          const startPosPostData = await postRatingsCollection.findOne({ ratingId: startPosPost.data, rootItem : rootItem })
          if (!startPosPostData){
            console.log("invalid start item")
            return res.status(400).send("invalid start item");
          }
            
          startPosPostDate = startPosPostData.creationDate;
        }

        //extract root item info
        if (!rootItem) {
          console.log("no root item");
          return res.status(400).send("no root item");
        }

        let rootItemData;
        console.log(rootItem.type)
        if (rootItem.type === "post") {
          rootItemData = await postsCollection.findOne({ postId : rootItem.data })
        }else if (rootItem.type === "rating") {
          rootItemData = await postRatingsCollection.findOne({ ratingId : rootItem.data })
          console.log(rootItem.data)
        }else{
          console.log("unknown root item type");
          return res.status(400).send("unknown root item type");
        }

        if (!rootItemData){
          console.log("invalid root item");
          return res.status(400).send("invalid root post");
        }
        if (rootItemData.shareMode != "public") {
          console.log("root item not shared with you")
          return res.status(403).send("root item not shared to you");
        }
        const dataReturning = await postRatingsCollection.find({ shareMode: 'public', creationDate: { $lt: startPosPostDate}, "rootItem.data" : rootItem.data, "rootItem.type" : rootItem.type }).sort({creationDate: -1}).limit(5).toArray();
        let returnData = {
          "items": [] as { type: string; data: string;}[]
        }
   
        if (dataReturning.length == 0) {
          console.log("nothing to fetch");
        }


        for (var i = 0; i < dataReturning.length; i++) {
          if (dataReturning[i].userId !== null) {
            returnData["items"].push({
              type : "rating",
              data : dataReturning[i].ratingId,
            });
          }
        }
        
        console.log("returning items");
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

  
export {
    router,
};