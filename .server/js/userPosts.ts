import express from 'express';
const router = express.Router();
import { b2, b2_uploadAuthToken, b2_uploadUrl, databases } from './database';
import { generateRandomString } from './utilFunctions';
import sharp, { Sharp } from 'sharp';
import { userTimeout, userTimeoutTest } from './timeouts';
import { testUserAdmin } from './adminZone';
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { confirmActiveAccount, confirmTokenValid } from './securityUtils';
import { reportError } from './errorHandler';


router.post('/post/upload', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
    console.log(" => user uploading post");
    try{
      const title = req.body.title;
      const description = req.body.description;
      const base64Images = req.body.images;
      var imagesData = [];
      const shareMode = req.body.shareMode;
      const userId : string = req.body.tokenUserId;

      let postId : string;
  
      //loop over making sure post Id is not used
      while (true){
        postId = generateRandomString(16);

        let postIdInUse = await databases.posts.findOne({postId: postId});
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

      if (base64Images.length < 1){
        console.log("image is needed to upload")
        return res.status(400).send('Image is needed to upload');
      }

      if (base64Images.length > 8){
        console.log("To many images")
        return res.status(400).send('To many images');
      }

      for (var i = 0; i < base64Images.length; i++) {
        //upload image
        try{
          imagesData[i] = Buffer.from(base64Images[i], 'base64');

          //make sure image is right size
          const imageMetadata : sharp.Metadata = await sharp(imagesData[i]).metadata();
          const { width, height } = imageMetadata;
          const MAX_RESOLUTION = {
            width: 1080,
            height: 1080,
          };
          if ((width === MAX_RESOLUTION.width && height === MAX_RESOLUTION.height) === false) {
            console.log("image resolution incorrect")
            return res.status(400).send('Image resolution is incorrect.');
          }

          if (imagesData[i].length * 3 / 4 > 1000000) {
            console.log("Image file size to large at " + (imagesData[i].length * 3 / 4) / 1000000 + "MB")
            return res.status(400).send('Image file size to large');
          }


        } catch (err) {
          reportError(err);
          return res.status(500).send('error saving image');
        }
      }

      let uploadedFileids = [];

      for (var i = 0; i < base64Images.length; i++) {
        console.log(b2_uploadUrl)
        let fileUploadResponse = await b2.uploadFile({ 
          uploadUrl: b2_uploadUrl,
          uploadAuthToken: b2_uploadAuthToken,
          fileName: `postImage-${i}-${postId}`,
          //contentLength: 0, // optional data length, will default to data.byteLength or data.length if not provided
          //mime: '', // optional mime type, will default to 'b2/x-auto' if not provided
          data: imagesData[i], // this is expecting a Buffer, not an encoded string
          //hash: 'sha1-hash', // optional data hash, will use sha1(data) if not provided
          //info: {
          //    // optional info headers, prepended with X-Bz-Info- when sent, throws error if more than 10 keys set
          //    // valid characters should be a-z, A-Z and '-', all other characters will cause an error to be thrown
          //    key1: 'value',
          //    key2: 'value'
          //},
          onUploadProgress: (event) => {}, // progress monitoring
          // ...common arguments (optional)
        });  // returns promise
        if (fileUploadResponse.status != 200) {
          console.log("Failed uploading ")
          return res.status(400).send('Failed uploading image');
        }
        uploadedFileids.push(fileUploadResponse['data']['fileId'])

      }

      let response = await databases.posts.insertOne(
        {
          posterUserId: userId,
          title: title,
          description: description,
          images: uploadedFileids,
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
    
    }catch(err){
      reportError(err);
      return res.status(500).send("server error")
    }
  
})



router.post('/post/data', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching post data")
    try{
      const postId = req.body.postId;
      const onlyUpdateChangeable = req.body.onlyUpdateChangeable;
      const userId : string = req.body.tokenUserId;

      
    

      var itemData = await databases.posts.findOne({postId: postId})

      if (itemData === null) {
        console.log("invalid post");
        return res.status(404).send("invalid post");
      }



      const ratingsAmount = await databases.post_ratings.countDocuments({ "rootItem.data" : postId, "rootItem.type" : "post" });

      const userRatingData = await databases.post_ratings.findOne({ "rootItem.data" : postId, "rootItem.type" : "post", "ratingPosterId" : userId});
      let requesterHasRated : boolean = false;
      if (userRatingData != null) {
        requesterHasRated = true;
      }
      //say they have rated if they post
      if (userId === itemData.posterUserId) { 
        requesterHasRated = true;
      }

      const viewerIsCreator = (userId == itemData.posterUserId);
      
      var imageCount = 1
      if (itemData.image != undefined) {
        imageCount = 1
      }else{
        imageCount = (itemData.images).length
      }


      console.log("sending post data");
      if (onlyUpdateChangeable === true) {
        return res.status(200).json({
          rating : itemData.rating,
          ratingsAmount : `${ratingsAmount}`, // converts to string as client software pefers that
          requesterRated :`${requesterHasRated}`,
          relativeViewerData : {
            viewerIsCreator : viewerIsCreator,
          },
        });
      }
      return res.status(200).json({
        title : itemData.title,
        description : itemData.description,
        rating : itemData.rating,
        postDate : itemData.postDate,
        ratingsAmount : `${ratingsAmount}`, // converts to string as client software pefers that
        requesterRated :`${requesterHasRated}`,
        postId : postId,
        imageCount : imageCount,
        posterId : itemData.posterUserId,
        relativeViewerData : {
          viewerIsCreator : viewerIsCreator,
        },
      });
    }catch(err){
      reportError(err);
      return res.status(500).send("server error")
    }
})


router.post('/post/image', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching post image data")
    try{
      const postId = req.body.postId;
      const imageNumber : number = req.body.imageNumber;
      const userId : string = req.body.tokenUserId;

      
      //Buffer.from(base64Images[i], 'base64');
      

      var itemData = await databases.posts.findOne({postId: postId})

      if (itemData === null) {
        console.log("invalid post");
        return res.status(404).send("invalid post");
      }

      var imageData;

      if (itemData.image != undefined){
        imageData = itemData.image
      }else{

        let fileDownloadResponse = await b2.downloadFileById({
          fileId: itemData.images[imageNumber],
          responseType: 'arraybuffer', // options are as in axios: 'arraybuffer', 'blob', 'document', 'json', 'text', 'stream'
          onDownloadProgress: (event) => {} // progress monitoring
          // ...common arguments (optional)
        });
        imageData = Buffer.from(fileDownloadResponse['data']).toString("base64")

        console.log(imageData)
        
      }


      console.log("sending post image data");
      return res.status(200).json({
        imageData : imageData,
      });
    }catch(err){
      reportError(err);
      return res.status(500).send("server error")
    }
})

router.post('/post/delete', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user deleteing post")
    try{
      const postId = req.body.postId;
      const userId : string = req.body.tokenUserId;
    
      let post = await databases.posts.findOne({ postId: postId});

      if (post === null) {
        console.log("post not found")
        return res.status(404).send("post not found");
      }

      if (post.posterUserId === userId || await testUserAdmin(userId) === true) {
        let deletedResponse = await databases.posts.deleteOne({ postId: postId});

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
  
    }catch(err){
      reportError(err);
      return res.status(500).send("server error")
    }
})



router.post('/post/feed', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching feed")
    try{
      const startPosPost = req.body.startPosPost;
      const pageFetching = req.body.pageFetching;
      let startPosPostDate: number = 100000000000000
      const userId : string | undefined = req.body.tokenUserId;
    
      if (startPosPost) {
        if (startPosPost.type === "post" && !startPosPost.data){
          console.log("invalid start post")
          return res.status(400).send("invalid start post");
        }

        const startPosPostData = await databases.posts.findOne({ postId: startPosPost.data })
        if (!startPosPostData){
          console.log("invalid start post")
          return res.status(400).send("invalid start post");
        }
          
        startPosPostDate = startPosPostData.postDate;
      }




      let posts : any[] = [];
      if (pageFetching === "popular"){
        posts = await databases.posts.find({ postDate: { $lt: startPosPostDate}}).sort({postDate: -1}).limit(5).toArray();

      }else if (pageFetching === "followers"){
        const usersData = await databases.user_follows.find({follower: userId}).toArray();
        console.log(usersData)
        const usersFollowing = [];

        for(var i = 0; i < usersData.length; i++) {
          var userData = usersData[i];
          usersFollowing.push(userData.followee);
          
        }

        posts = await databases.posts.find({ postDate: { $lt: startPosPostDate}, posterUserId : {$in : usersFollowing}}).sort({postDate: -1}).limit(5).toArray();

      }else{
        console.log("no page to fetch")
        return res.status(400).send("no page to fetch");

      }
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
      
    }catch(err){
      reportError(err);
      return res.status(500).send("server error");
    }
})



export {
    router,
};