const express = require('express');
const router = express.Router();
const fs = require('fs');
const { database } = require('./database');
const { testToken } = require('./userLogin');
const { generateRandomString } = require('./utilFunctions');
const sharp = require('sharp');

router.post('/post/upload', async (req, res) => {
    console.log("user uploading post");
    try{
      const token = req.body.token;
      const title = req.body.title;
      const description = req.body.description;
      const base64Image = req.body.image;
      const shareMode = req.body.shareMode;
      var postId;
      
      var vaildToken = false;
      var userId = "";
      [vaildToken, userId] = await testToken(token,req.ip); //frankly I have no idea why you need the square brackets but it fixes it so eh
  
      if (vaildToken) {
        var collection = database.collection('posts');
  
        const image = req.file;
        var imageId = generateRandomString(16);
        while (fs.existsSync(imageId)) {
          imageId = generateRandomString(16);
        }
  
        //loop over making sure post Id is not used
        while (true){
          postId =  generateRandomString(16);
  
          let postIdInUse = await collection.findOne({postId: postId});
          if (postIdInUse === null){
            break
          }
        }
  
  
        //make sure title not to large or empty and isn't null or undefined
        if (title.length > 50) {
          return res.status(400).send('title is to large.');
        }else if (title === null || title.match(/^ *$/) !== null || title === undefined) {
          return res.status(400).send('title is empty.');
        }
  
        //make sure description not to large or empty and isn't null or undefined
        if (description.length > 250) {
          return res.status(400).send('description is to large');
        }else if (description === null || description.match(/^ *$/) !== null || description === undefined) {
          return res.status(400).send('description is empty.');
        }
  
        //make sure user has perms to view it
        if (shareMode === "public") {
        }else if (shareMode === "friends"){
        }else{
          return res.status(400).send('Invaild share mode.');
        }
  
        //upload image
        try{
          imageData = Buffer.from(base64Image, 'base64');
  
          //make sure image is right size
          const imageMetadata = await sharp(imageData).metadata();
          const { width, height } = imageMetadata;
          const MAX_RESOLUTION = {
            width: 1080,
            height: 1080,
          };
          if ((width === MAX_RESOLUTION.width && height === MAX_RESOLUTION.height) === false) {
            return res.status(400).send('Image resolution exceeds the allowed limit.');
          }
        
          fs.writeFileSync(`./images/${imageId}.jpg`, imageData);
  
  
        } catch (err) {
          console.log(err)
          return res.status(400).send('error saving image');
        }
  
        response = await collection.insertOne(
          {
            posterUserId: userId,
            title: title,
            description: description,
            image: imageId,
            postDate: Date.now(),
            shareMode: shareMode,
            postId: postId,
            reviews: {
  
            },
            rating:0.0,
          }
        )
  
        
        console.log("post deleted");
        return res.status(200).send('created post');
  
      }else{
        console.log("invaild token");
        return res.status(401).send("invaild token");
      }
    
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
  
})



router.post('/post/data', async (req, res) => {
  console.log("user fetching post data")
    try{
      console.log("user fetching post")
      const token = req.body.token;
      var vaildToken, userId;
  
      [vaildToken, userId] = await testToken(token,req.ip)
      const postId = req.body.postId;
    
      if (vaildToken) { // user token is valid
        var collection = database.collection('posts');
        var userDataCollection = database.collection('user_data');
        var itemData = await collection.findOne({postId: postId})
  
        if (itemData === null) {
          return res.status(404).send("invaild post");
        }
  
        if (itemData.shareMode !== 'public'){
          return res.status(403).send("can't view post");
        }
        
  
        let imageData = null;
        imageData = fs.readFileSync(`./images/${itemData.image}.jpg`);
        imageData = imageData.toString('base64');
  
  
        const posterUserData = await userDataCollection.findOne({ userId: itemData.posterUserId })
        if (posterUserData === undefined || posterUserData === null) {
          return res.status(400).send("unkown poster");
        }
  
        return res.status(200).json({
          title : itemData.title,
          description : itemData.description,
          rating : itemData.rating,
          postId : postId,
          imageData : imageData,
          posterData : {
            username : posterUserData.username,
            userId : itemData.posterUserId,
          },
        });
  
      }else{
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
    }
})



router.post('/post/delete', async (req, res) => {
  console.log("user deleteing post")
    try{
      const token = req.body.token;
      const postId = req.body.postId;
      var vaildToken, userId;
      [vaildToken, userId] = await testToken(token,req.ip)
    
      if (vaildToken) { // user token is valid
        var collection = database.collection('posts');
  
        var post = await collection.findOne({ postId: postId});

        if (post.posterUserId === userId) {

          await collection.deleteOne({ postId: postId});

          fs.rmSync(`./images/${post.image}.jpg`);

          return res.status(200).send("post deleted");

        }else{
          return res.status(403).send("post not yours");
        }
  
      }else{
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
    }
})



router.post('/post/feed', async (req, res) => {
  console.log("user fetching feed")
    try{
      const token = req.body.token;
      const startPosPost = req.body.startPosPost;
      var startPosPostDate = 100000000000000
      var vaildToken, userId;
  
      [vaildToken, userId] = await testToken(token,req.ip)
    
      if (vaildToken) { // user token is valid
        var collection = database.collection('posts');
        var posts;
  
        if (startPosPost) {
          const startPosPostData = await collection.findOne({ postId: startPosPost })
          if (!startPosPostData){
            return res.status(400).send("invaild start post");
          }else{
            startPosPostDate = startPosPostData.postDate;
          }
        }
  
        posts = await collection.find({ shareMode: 'public', postDate: { $lt: startPosPostDate}}).sort({postDate: -1}).limit(5).toArray();
        var returnData = {}
        returnData["posts"] = []
   
        if (posts.length == 0) {
          console.log("nothing to fetch");
        }
  
        for (var i = 0; i < posts.length; i++) {
          returnData["posts"].push(posts[i].postId);
          //Do something
        }
  
        return res.status(200).json(returnData);
  
      }else{
        return res.status(401).send("invaild token");
      }
    }catch(err){
      console.log(err);
    }
})



module.exports = {
    router:router,
};