import express from 'express';
const router = express.Router();
import { database } from './database';
import { testToken } from './userLogin';
import { generateRandomString } from './utilFunctions';
import sharp, { Sharp } from 'sharp';
import { userTimeout, userTimeoutTest } from './timeouts';
import { testUserAdmin } from './adminZone';
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { BlobOptions } from 'buffer';


router.post('/post/upload', async (req : Request, res : Response) => {
    console.log(" => user uploading post");
    try{
      const token = req.body.token;
      const title = req.body.title;
      const description = req.body.description;
      const base64Image = req.body.image;
      const shareMode = req.body.shareMode;
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const vaildToken : boolean = result.valid;
      const userId : string | undefined = result.userId;

      let postId : string;
  
      if (vaildToken) {
        var collection : mongoDB.Collection = database.collection('posts');
  
        //loop over making sure post Id is not used
        while (true){
          postId = generateRandomString(16);
  
          let postIdInUse = await collection.findOne({postId: postId});
          if (postIdInUse === null){
            break
          }
        }

        const userTimeoutTestResult = await userTimeoutTest(userId,"change_username");
        const timeoutActive : boolean = userTimeoutTestResult.active;
        const timeoutTime : string | undefined = userTimeoutTestResult.timeLeft;

        if (timeoutActive === true) {
          console.log("user is timed out for " + timeoutTime);
          return res.status(408).send('timed out for ' + timeoutTime);
        }
  
        //make sure title not to large or empty and isn't null or undefined
        if (title.length > 50) {
          console.log("title is to large");
          return res.status(400).send('title is to large.');
        }else if (title === null || title.match(/^ *$/) !== null || title === undefined) {
          console.log("title is empty");
          return res.status(400).send('title is empty.');
        }
  
        //make sure description not to large or empty and isn't null or undefined
        if (description.length > 250) {
          console.log("description is to large.");
          return res.status(400).send('description is to large');
        }else if (description === null || description.match(/^ *$/) !== null || description === undefined) {
          console.log("description is empty.");
          return res.status(400).send('description is empty.');
        }
  
        //make sure user has perms to view it
        if (shareMode === "public") {
        }else if (shareMode === "friends"){
        }else{
          console.log("invaild post share mode")
          return res.status(400).send('Invaild share mode.');
        }
  
        //upload image
        try{
          const imageData : Buffer = Buffer.from(base64Image, 'base64');
  
          //make sure image is right size
          const imageMetadata : sharp.Metadata = await sharp(imageData).metadata();
          const { width, height } = imageMetadata;
          const MAX_RESOLUTION = {
            width: 1080,
            height: 1080,
          };
          if ((width === MAX_RESOLUTION.width && height === MAX_RESOLUTION.height) === false) {
            console.log("image resolution incorrect")
            return res.status(400).send('Image resolution is incorrect.');
          }
  
  
        } catch (err) {
          console.log(err)
          return res.status(500).send('error saving image');
        }
  
        let response = await collection.insertOne(
          {
            posterUserId: userId,
            title: title,
            description: description,
            image: base64Image,
            postDate: Date.now(),
            shareMode: shareMode,
            postId: postId,
            rating: 0.0,
          }
        )
        
        if (response.acknowledged === true){
          userTimeout(userId,"post_upload", 60)
          console.log("post created");
          return res.status(201).send('created post');
        }else{
          console.log("failed to create post");
          return res.status(500).send('failed to create post');
        }
        
  
      }else{
        console.log("invaild token");
        return res.status(401).send("invaild token");
      }
    
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
  
})



router.post('/post/data', async (req : Request, res : Response) => {
  console.log(" => user fetching post data")
    try{
      const token = req.body.token;
      const postId = req.body.postId;
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const vaildToken : boolean = result.valid;
      const userId : string | undefined = result.userId;

      
    
      if (vaildToken) { // user token is valid
        var collection : mongoDB.Collection = database.collection('posts');
        var userDataCollection : mongoDB.Collection = database.collection('user_data');
        var itemData = await collection.findOne({postId: postId})
        const postRatingsCollection : mongoDB.Collection = database.collection('post_ratings');
  
        if (itemData === null) {
          console.log("invaild post");
          return res.status(404).send("invaild post");
        }
  
        if (itemData.shareMode !== 'public'){
          console.log("user can't view post");
          return res.status(403).send("can't view post");
        }



        const ratingsAmount = await postRatingsCollection.countDocuments({ "rootItem.data" : postId, "rootItem.type" : "post" });

        const userRatingData = await postRatingsCollection.findOne({ "rootItem.data" : postId, "rootItem.type" : "post", "ratingPosterId" : userId});
        let requesterHasRated : boolean = false;
        if (userRatingData != null) {
          requesterHasRated = true;
        }
        //say they have rated if they post
        if (userId === itemData.posterUserId) { 
          requesterHasRated = true;
        }

        console.log("sending post data");
        return res.status(200).json({
          title : itemData.title,
          description : itemData.description,
          rating : itemData.rating,
          ratingsAmount : `${ratingsAmount}`, // converts to string as client software pefers that
          requesterRated :`${requesterHasRated}`,
          postId : postId,
          imageData : itemData.image,
          posterId : itemData.posterUserId
        });
  
      }else{
        console.log("invaild token");
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
})



router.post('/post/delete', async (req, res) => {
  console.log(" => user deleteing post")
    try{
      const token = req.body.token;
      const postId = req.body.postId;
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const vaildToken : boolean = result.valid;
      const userId : string | undefined = result.userId;
    
      if (vaildToken) { // user token is valid
        let collection : mongoDB.Collection = database.collection('posts');
        let post = await collection.findOne({ postId: postId});

        if (post === null) {
          console.log("post not found")
          return res.status(404).send("post not found");
        }

        if (post.posterUserId === userId || await testUserAdmin(userId) === true) {
          let deletedResponse = await collection.deleteOne({ postId: postId});
  
          if (deletedResponse.acknowledged === true) {
            console.log("post deleted");
            return res.status(200).send("post deleted");
          }else{
            console.log("failed to delete post");
            return res.status(500).send("failed deleting post");
          }

        }else{
          console.log("user doesn't own post");
          return res.status(403).send("post not yours");
        }
  
      }else{
        console.log("user token is invaild");
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
})



router.post('/post/feed', async (req, res) => {
  console.log(" => user fetching feed")
    try{
      const token = req.body.token;
      const startPosPost = req.body.startPosPost;
      let startPosPostDate: number = 100000000000000
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;

      const result = await testToken(token,userIpAddress);
      const vaildToken : boolean = result.valid;
      const userId : string | undefined = result.userId;
    
      if (vaildToken) { // user token is valid
        let collection : mongoDB.Collection = database.collection('posts');
  
        if (startPosPost) {
          if (startPosPost.type === "post" && !startPosPost.data){
            console.log("invaild start post")
            return res.status(400).send("invaild start post");
          }

          const startPosPostData = await collection.findOne({ postId: startPosPost.data })
          if (!startPosPostData){
            console.log("invaild start post")
            return res.status(400).send("invaild start post");
          }
            
          startPosPostDate = startPosPostData.postDate;
        }
  
        const posts = await collection.find({ shareMode: 'public', postDate: { $lt: startPosPostDate}}).sort({postDate: -1}).limit(5).toArray();
        let returnData = {
          "items": [] as { type: string; data: string;}[]
        }
   
        if (posts.length == 0) {
          console.log("nothing to fetch");
        }
  
        for (var i = 0; i < posts.length; i++) {
          if (posts[i].userId !== null) {
            returnData["items"].push({
              type : "post",
              data : posts[i].postId,
            });
          }
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



export {
    router,
};