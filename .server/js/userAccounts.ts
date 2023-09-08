import express from 'express';
const router = express.Router();
import crypto from 'crypto';
import { database } from './database';
import { testToken } from './userLogin';
import { generateRandomString } from './utilFunctions';
import sharp, { Sharp } from 'sharp';
import { userTimeout, userTimeoutTest } from './timeouts';
import { cleanEmailAddress, testUsername } from './validInputTester';
import { title } from 'process';
import mongoDB from "mongodb";
import { Request, Response } from "express";

async function sendNoticeToAccount(userId : string, text : string, title : string){
  const collection: mongoDB.Collection = database.collection('account_notices');
  const response = await collection.insertOne({
    userId: userId,
    title: title,
    text: text,
  });

  if (response.acknowledged === true){
    return true;
  }else{
    return false;
  }
}

router.post('/profile/basicData', async (req : Request, res : Response) => {
  console.log(" => user fetching profile")
  try{
    const token = req.body.token;
    const userId = req.body.userId;
    const collection: mongoDB.Collection = database.collection('user_data');
    const userIpAddress : string = req.headers['x-forwarded-for'] as string;
    const onlyUpdateChangeable = req.body.onlyUpdateChangeable;

    const result = await testToken(token,userIpAddress);
    const validToken : boolean = result.valid;
    const requesterUserId : string | undefined = result.userId;

    if (validToken) { // user token is valid
      const userData = await collection.findOne({ userId: userId })
      
      if (userData === null){
        console.log("failed as invalid user");
        return res.status(404).send("unkown user");
      }

      console.log("sending basic data");
      if (onlyUpdateChangeable === true) {
        return res.status(200).json({
          username: userData.username,
          avatar : userData.avatar,
          averagePostRating : userData.averagePostRating | 0,
        });
      }
      res.status(200).json({
        username: userData.username,
        avatar : userData.avatar,
        averagePostRating : userData.averagePostRating | 0,
      });

    }else{
      console.log("returned invalid token");
      return res.status(401).send("invalid token");
    
    }
    
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})



router.post('/profile/settings/change', async (req : Request, res : Response) => {
  console.log(" => user profile setting change")
  try{
    const token = req.body.token;
    const setting = req.body.setting;
    const value = req.body.value;

    const userIpAddress : string = req.headers['x-forwarded-for'] as string;

    const result = await testToken(token,userIpAddress);
    const validToken : boolean = result.valid;
    const userId : string | undefined = result.userId;
  
    if (validToken) { // user token is valid

      if (setting === "username") {
        //test timeout
        //const userTimeoutTestResult = await userTimeoutTest(userId,"change_username");
        //const timeoutActive : boolean = userTimeoutTestResult.active;
        //const timeoutTime : string | undefined = userTimeoutTestResult.timeLeft;
        //
        //if (timeoutActive === true) {
        //  console.log("username timed out " + timeoutTime);
        //  return res.status(408).send("please wait " + timeoutTime + " to change username");
        //}

        const testUsernameResult = await testUsername(value);
        const usernameAllowed : boolean = testUsernameResult.valid;
        const usernameDeniedReason : string = testUsernameResult.reason;

        if (usernameAllowed === false) {
          console.log(usernameDeniedReason)
          return res.status(400).send(usernameDeniedReason)
        }

        const collection: mongoDB.Collection = database.collection('user_data');

        const response = await collection.updateOne({userId: userId},{ $set: {username : value}}) 

        if (response.acknowledged === true) {
          //update username
          //userTimeout(userId,"change_username", 60 * 60 * 24 * 7);
          console.log("updated username");
          return res.status(200).send("updated username");
          

        }else{
          console.log("failed to update username")
          return res.status(500).send("failed to update username")

        }

        } else if (setting === "bio") {
  
          if (value.length > 500) {
            console.log("bio to large")
            return res.status(400).send("bio to large")
          }
  
          const collection: mongoDB.Collection = database.collection('user_data');
  
          const response = await collection.updateOne({userId: userId},{ $set: {bio : value}}) 
  
          if (response.acknowledged === true) {
            //update username
            console.log("updated bio");
            return res.status(200).send("updated bio");
  
          }else{
            console.log("failed to update bio")
            return res.status(500).send("failed to update bio")
  
          }

      } else if (setting === "avatar") {
        //stored on user data is the code to there avatar
        //the code links to document in avatar data collection
        //cache doesn't have update function as codes change not update already exist data on a code

        //get data about image
        try{
          const imageData : Buffer = Buffer.from(value, 'base64');
  
          //make sure image is right size
          const imageMetadata : sharp.Metadata = await sharp(imageData).metadata();
          const { width, height } = imageMetadata;
          const MAX_RESOLUTION = {
            width: 1080,
            height: 1080,
          };
          if ((width === MAX_RESOLUTION.width && height === MAX_RESOLUTION.height) === false) {
            console.log("Avatar image resolution incorrect")
            return res.status(400).send('avatar image resolution is incorrect.');
          }
  
  
        } catch (err) {
          console.log(err)
          return res.status(500).send('error saving avatar image');
        }

        var avatarsCollection : mongoDB.Collection = database.collection('user_avatars');
        let avatarId: string | null = null;
        while (true){
          avatarId = generateRandomString(16);
  
          let avatarIdInUse = await avatarsCollection.findOne({avatarId: avatarId});
          if (avatarIdInUse === null){
            break
          }
        }

        const userDataCollection: mongoDB.Collection = database.collection('user_data');
        const userData = await userDataCollection.findOne({userId : userId})
        if (userData){
          avatarsCollection.deleteOne({avatarId : userData["avatar"]})
        }

        let response = await avatarsCollection.insertOne(
          {
            avatarId : avatarId,
            imageData : value
          }
        )

        if (response.acknowledged === true) {
          let response = await userDataCollection.updateOne(
            {userId : userId},
            { $set: {
              avatar : avatarId
            }}
            )


          if (response.acknowledged === true) {
            console.log("updated avatar");
            return res.status(200).send("updated avatar");
          }else{
            console.log("failed to update avatar")
            return res.status(500).send("failed to update avatar")
          }
        }else{
          console.log("failed to update avatar")
          return res.status(500).send("failed to update avatar")
        }

      }else{
        console.log("unkown setting")
        return res.status(404).send("unkown setting")

      }
    }
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})



router.post('/profile/data', async (req : Request, res : Response) => {
    console.log(" => user fetching profile")
    try{
      const token = req.body.token;
      let userId = req.body.userId;
      const collection: mongoDB.Collection = database.collection('user_data');
      const userIpAddress : string = req.headers['x-forwarded-for'] as string;
      const onlyUpdateChangeable = req.body.onlyUpdateChangeable;

      const result = await testToken(token,userIpAddress);
      const validToken : boolean = result.valid;
      const requesterUserId : string | undefined = result.userId;

      

      if (validToken){
        
        //if they dont supply any user just fetch themselves
        if (!userId) {
          userId = requesterUserId;
        }
      
        const userData = await collection.findOne({ userId: userId });

        if (userData === null){
          console.log("failed as invalid user");
          return res.status(404).send("unkown user");
        }

        if (userData.shareMode != "public") {
          console.log("no perms to view profile");
          return res.status(403).send("no perms to view profile");
        }
      
        console.log("returning profile data");
        if (onlyUpdateChangeable === true) {
          return res.status(200).json({
            username: userData.username,
            bio: userData.bio,
            administrator: userData.administrator,
            avatar : userData.avatar,
            averagePostRating : userData.averagePostRating | 0,
          });
        }
        return res.status(200).json({
          username: userData.username,
          bio: userData.bio,
          administrator: userData.administrator,
          avatar : userData.avatar,
          userId: userId,
          averagePostRating : userData.averagePostRating | 0,
        });

      }else{
        console.log("returned invalid token");
        return res.status(401).send("invalid token");
      }
      
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
})

router.post('/profile/avatar', async (req : Request, res : Response) => {
  console.log(" => user fetching avatar")
  try{
    const token = req.body.token;
    const avatarId = req.body.avatarId;

    if (avatarId === null){
      console.log("no value no user");
      return res.status(200).send("no user no value");
    }
    
    const collection: mongoDB.Collection = database.collection('user_avatars');
    const userIpAddress : string = req.headers['x-forwarded-for'] as string;
    
    const avatarData = await collection.findOne({ avatarId: avatarId });
    console.table(avatarData)
    if (avatarData === null){
      console.log("failed as invalid avatar");
      return res.status(404).send("unkown user");
    }
    
    console.log("returning profile data");
    return res.status(200).json({
      avatarId: avatarId,
      imageData: avatarData.imageData,
    });
    
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

router.post('/profile/posts', async (req : Request, res : Response) => {
  console.log(" => user fetching posts on profile")
  try{
    const token = req.body.token;
    const startPosPost = req.body.startPosPost;
    const fetchingUserId = req.body.userId;
    let startPosPostDate = 100000000000000

    const userIpAddress : string = req.headers['x-forwarded-for'] as string;

    const result = await testToken(token,userIpAddress);
    const validToken : boolean = result.valid;
    const userId : string | undefined = result.userId;
  
    if (validToken) { // user token is valid
      let collection = database.collection('posts');

      if (startPosPost) {
        if (startPosPost.type === "post" && !startPosPost.data){
          console.log("invalid start post");
          return res.status(400).send("invalid start post");
        }

        const startPosPostData = await collection.findOne({ postId: startPosPost.data })
        if (!startPosPostData){
          console.log("invalid start post");
          return res.status(400).send("invalid start post");
        }
          
        startPosPostDate = startPosPostData.postDate;
      }

      const posts = await collection.find({posterUserId : fetchingUserId, shareMode: 'public', postDate: { $lt: startPosPostDate}}).sort({postDate: -1}).limit(5).toArray();
      var returnData = {
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
      console.log("invalid token")
      return res.status(401).send("invalid token");
    }
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

async function banAccount(userId : string,time : number,reason : string) {
  try{
    const collection : mongoDB.Collection = database.collection("user_credentials");

    const result = await collection.updateOne(
      { userId: userId },
      { $set: {
        accountBanExpiryDate : Date.now() + (time * 1000),
        accountBanReason : reason,
        tokenNotExpiredCode : generateRandomString(16),
        }
      }
    );


    if (result.acknowledged === true) {
      return true
    }else{
      return false
    }
    
  }catch(err){
    console.log(err);
    return false
  }
}

async function createUser(rawEmail : string,password : string, username : string){
    try{
      const email = cleanEmailAddress(rawEmail);
      const userCredentialsCollection = database.collection("user_credentials");
      const userDataCollection = database.collection("user_data");
      const passwordSalt : string = crypto.randomBytes(16).toString('hex');
      const hashedPassword : string = crypto.createHash("sha256")
      .update(password)
      .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
      .digest("hex");
  
      //make sure email is not in use
      let emailInUse : boolean = true;
      try{
        const result = await userCredentialsCollection.findOne({ email: email })
        if (result === null){
          emailInUse = false;
        }
      }catch(err){
        console.log(err);
      }
  
      if(emailInUse===true){
        console.log("email already in use")
        return false;
      }

      const testUsernameResult = await testUsername(username);
      const usernameAllowed : boolean = testUsernameResult.valid;
      const usernameDeniedReason : string = testUsernameResult.reason;

      if (usernameAllowed === false) {
        console.log(usernameDeniedReason)
        //return res.status(400).send(usernameDeniedReason)
        return false
      }
  
      //create userId and make sure no one has it
      let userId : string = "";
      let invalidUserId : boolean = true;
      while(invalidUserId){
        userId = generateRandomString(16);
        try{
          const result = await userCredentialsCollection.findOne({ userId: userId })
          if (result === null){
            invalidUserId = false;
          }
        }catch(err){
          console.log(err);
        }
      }
     
      var tokenNotExpiredCode = generateRandomString(16);
  
      const userCredentialsOutput = await userCredentialsCollection.insertOne(
        {
          userId: userId,
          email: email,
          hashedPassword: hashedPassword,
          passwordSalt: passwordSalt,
          accountBanReason: "",
          accountBanExpiryDate: 0,
          failedLoginAttemptInfo: {},
          tokenNotExpiedCode: tokenNotExpiredCode,
        }
      )
      const userDataOutput = await userDataCollection.insertOne(
        {
          userId: userId,
          username: username,
          bio: "",
          avatar: null,
          cooldowns: {},
          administrator: false,
          creationDate: Date.now(),
          privateAccount: false,
          shareMode: "public",
        }
      )
      if (userCredentialsOutput.acknowledged === true && userDataOutput.acknowledged === true){
        console.log("created account")
        return true;
      }else{
        console.log("failed creating account")
        return false
      }
  

    }catch (err){
      console.log(err);
      return false;
    }
    //phone number
  
}

export {
    router,
    banAccount,
    createUser,
    sendNoticeToAccount,
};

