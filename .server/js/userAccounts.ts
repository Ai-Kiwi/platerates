import express from 'express';
const router = express.Router();
import crypto, { checkPrimeSync } from 'crypto';
import { databases } from './database';
import { generateRandomString } from './utilFunctions';
import sharp, { Sharp } from 'sharp';
import { userTimeout, userTimeoutTest } from './timeouts';
import { cleanEmailAddress, testUsername } from './validInputTester';
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { appCheckVerification, confirmActiveAccount, confirmTokenValid } from './securityUtils';
import nodemailer from "nodemailer";
import { sendMail } from './mailsender';

async function sendNoticeToAccount(userId : string, text : string, title : string){
  const collection: mongoDB.Collection = databases.account_notices.collection('account_notices');
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

router.post('/profile/basicData', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching profile")
  try{
    const userId = req.body.userId;
    const onlyUpdateChangeable = req.body.onlyUpdateChangeable;

    const requesterUserId : string | undefined = req.body.tokenUserId

    const userData = await databases.user_data.findOne({ userId: userId })
    
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
    
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})



router.post('/profile/settings/change', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user profile setting change")
  try{
    const setting = req.body.setting;
    const value = req.body.value;
    const userId : string | undefined = req.body.tokenUserId;
  

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

      const response = await databases.user_data.updateOne({userId: userId},{ $set: {username : value}}) 

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

        const response = await databases.user_data.updateOne({userId: userId},{ $set: {bio : value}}) 

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

      let avatarId: string | null = null;
      while (true){
        avatarId = generateRandomString(16);

        let avatarIdInUse = await databases.user_avatars.findOne({avatarId: avatarId});
        if (avatarIdInUse === null){
          break
        }
      }

      const userData = await databases.user_data.findOne({userId : userId})
      if (userData){
        await databases.user_avatars.deleteOne({avatarId : userData["avatar"]})
      }

      let response = await databases.user_avatars.insertOne(
        {
          avatarId : avatarId,
          imageData : value
        }
      )

      if (response.acknowledged === true) {
        let response = await databases.user_data.updateOne(
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
    
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})



router.post('/profile/data', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
    console.log(" => user fetching profile")
    try{
      let userId = req.body.userId;
      const onlyUpdateChangeable = req.body.onlyUpdateChangeable;
      const requesterUserId : string | undefined = req.body.tokenUserId;

    
        
      //if they dont supply any user just fetch themselves
      if (!userId) {
        userId = requesterUserId;
      }
    
      const userData = await databases.user_data.findOne({ userId: userId });

      if (userData === null){
        console.log("failed as invalid user");
        return res.status(404).send("unkown user");
      }

      //test if following
      var followData = await databases.user_follows.findOne({follower : requesterUserId, followee : userId})
      var followingUser = false
      if (followData != null) {
        followingUser = true;
      }
      const followersCount = await databases.user_follows.countDocuments({ followee : userId })
      const followingCount = await databases.user_follows.countDocuments({ follower : userId })
      const postCount = await databases.posts.countDocuments({ posterUserId : userId })
      const ratingCount = await databases.post_ratings.countDocuments({ratingPosterId : userId })
    
      console.log("returning profile data");
      if (onlyUpdateChangeable === true) {
        return res.status(200).json({
          username: userData.username,
          bio: userData.bio,
          administrator: userData.administrator,
          avatar : userData.avatar,
          averagePostRating : userData.averagePostRating | 0,
          followersCount : followersCount,
          followingCount : followingCount,  
          postCount : postCount,  
          ratingCount : ratingCount,
          relativeViewerData : {
            following : followingUser,
          },

        });
      }
      return res.status(200).json({
        username: userData.username,
        bio: userData.bio,
        administrator: userData.administrator,
        avatar : userData.avatar,
        userId: userId,
        averagePostRating : userData.averagePostRating | 0,
        followersCount : followersCount,
        followingCount : followingCount,  
        postCount : postCount,  
        ratingCount : ratingCount,
        relativeViewerData : {
          following : followingUser,
        },
      });
      
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
})

router.post('/profile/avatar', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching avatar")
  try{
    const avatarId = req.body.avatarId;

    if (avatarId === null){
      console.log("no value no user");
      return res.status(200).send("no user no value");
    }
        
    const avatarData = await databases.user_avatars.findOne({ avatarId: avatarId });
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

router.post('/profile/posts', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching posts on profile")
  try{
    const startPosPost = req.body.startPosPost;
    const fetchingUserId = req.body.userId;
    let startPosPostDate = 100000000000000
    const userId : string | undefined = req.body.tokenUserId;
  
    if (startPosPost) {
      if (startPosPost.type === "post" && !startPosPost.data){
        console.log("invalid start post");
        return res.status(400).send("invalid start post");
      }

      const startPosPostData = await databases.posts.findOne({ postId: startPosPost.data })
      if (!startPosPostData){
        console.log("invalid start post");
        return res.status(400).send("invalid start post");
      }
        
      startPosPostDate = startPosPostData.postDate;
    }

    const posts = await databases.posts.find({posterUserId : fetchingUserId, postDate: { $lt: startPosPostDate}}).sort({postDate: -1}).limit(5).toArray();
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

  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

router.post('/profile/follow', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user following/unfollowing user")
  try{
    const tryingToFollow = req.body.following;
    const followingUserId = req.body.userId;
    const userId : string | undefined = req.body.tokenUserId
        
    //make sure not trying to follow themselfs
    if (userId === followingUserId){
      console.log("can't follow yourselfs")
      return res.status(409).send("can't follow yourselfs");
    }

    //add part to make sure user exists


    //look if already following
    let userFollowItem = await databases.user_follows.findOne({ followee : followingUserId, follower :  userId})
    let alreadyFollowing = false;
    if (userFollowItem !== null) {
      alreadyFollowing = true;
    }

    //if you are trying to follow them or unfollow them
    if (tryingToFollow == true){

      if (alreadyFollowing === true){
        console.log("already following")
        return res.status(409).send("already following");
      }else{
        const response = await databases.user_follows.insertOne({ 
          followee : followingUserId, 
          follower :  userId
        })
        if (response.acknowledged === true){
          console.log("started following");
          return res.status(200).send("started following")
        }else{
          console.log("failed to create item in database");
          return res.status(500).send("server error")
        }
      }


    }else{
      if (alreadyFollowing === true){
        const response = await databases.user_follows.deleteOne({ 
          followee : followingUserId, 
          follower :  userId
        })
        if (response.acknowledged === true){
          console.log("removed follow");
          return res.status(200).send("removed follow")
        }else{
          console.log("failed to create item in database");
          return res.status(500).send("server error")
        }
      }else{
        console.log("already not following")
        return res.status(409).send("already not following");
      }
    }
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

async function banAccount(userId : string,time : number,reason : string) {
  try{
    const result = await databases.user_credentials.updateOne(
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




router.get('/use-create-account-code', async (req : Request, res : Response) => {
  const requestId = req.query.requestId;
  const ipAddress = req.headers['x-forwarded-for'];
  console.log("user using account create code")
  try{

    const accountCreateRequestItem = await databases.account_create_requests.findOne({requestId: requestId});
    
    //test if code is valid
    if (accountCreateRequestItem === null) {
      console.log("code invalid");
      return res.status(400).send("code invalid");
    }
    //test if code is expired
    if (accountCreateRequestItem.creationDate <= Date.now() - (1000 * 60 * 60 * 24 * 16)) { // expires after 16 days
      console.log("code expired");
      return res.status(410).send("code expired");
    }

    const newAccountUsername = accountCreateRequestItem.username;
    const newAccountEmail = accountCreateRequestItem.email;



    const testUsernameResult = await testUsername(newAccountUsername);
    const usernameAllowed : boolean = testUsernameResult.valid;
    const usernameDeniedReason : string = testUsernameResult.reason;

    if (usernameAllowed === false){
        console.log("username input invalid");
        return res.status(400).send(`invalid username : ${usernameDeniedReason}`);    
    }

    //create password and send email
    const NewUserPassword : string = generateRandomString(16)

    //add user to database
    const response: boolean = await createUser(newAccountEmail,NewUserPassword,newAccountUsername) 
    if (response === true) {
        const emailData: nodemailer.SentMessageInfo = await sendMail(
            '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
            newAccountEmail,
            "Toaster account created",
            `
Hi user,
Your account has been created and you can log in at https://toaster.aikiwi.dev/. Your temporary password is below please change this once logged in using reset password on login page.

Login email address : ${newAccountEmail}
Temporary password : ${NewUserPassword}

We hope you enjoy using Toaster! We're always looking for feedback, so please feel free to reach out to us with any questions or suggestions at toaster@aikiwi.dev.

Welcome to the Toaster community! We're a welcoming community and we expect all users to follow our community guidelines at https://toaster.aikiwi.dev/CommunityGuidelines and terms of service at https://toaster.aikiwi.dev/termsofService

For any concerns about data handling you can find our privacy policy at https://toaster.aikiwi.dev/privacyPolicy and our data deletion instructions at https://toaster.aikiwi.dev/deleteData. 

Thanks,
The Toaster Team`);
      if (emailData) {
          await databases.account_create_requests.deleteOne({requestId : requestId}) 

          console.log("account created");
          return res.status(200).send("user created");   
      }else{
          console.log("failed sending email");
          return res.status(500).send("failed to send email");
      }
    }else{
        console.log("failed creating user");
        return res.status(500).send("failed creating user");
    }

    



  }catch(err){
    console.log(err);
    return res.status(500).send("server error");
  }
})



router.post('/createAccount', [appCheckVerification] , async (req : Request, res : Response) => {
  console.log(" => user creating account request code")
  try{
    const token = req.body.token;
    const newAccountEmail = cleanEmailAddress(req.body.email);
    const newAccountUsername = req.body.username;
    const userIpAddress : string = req.headers['x-forwarded-for'] as string;
    
    //add ip blocking
    //add strict rate limiting
    //add device id limits

    //test that username and email has a value

    

    if (newAccountEmail === null || newAccountEmail === undefined || newAccountEmail === "") {
      console.log("email empty");
      return res.status(400).send("email can't be nothing");   
    }
    if (newAccountUsername === null || newAccountUsername === undefined || newAccountUsername === "") {
      console.log("username empty");
      return res.status(400).send("username can't be nothing");   
    }

    var requestId : string;
    while (true){
      requestId = generateRandomString(128);

      let requestIdInUse = await databases.account_create_requests.findOne({requestId: requestId});
      if (requestIdInUse === null){
        break
      }
    }

    //make sure username is valid
    var userNameValid = await testUsername(newAccountUsername)
    if (userNameValid.valid === false){
      console.log(`username invalid : ${userNameValid.reason}`);
      return res.status(400).send(`username invalid : ${userNameValid.reason}`);   
    }

    var accountResult;

    accountResult = await databases.user_credentials.findOne({email : newAccountEmail});
    if (accountResult != null){
      console.log("email already in use");
      return res.status(400).send("email already in use");   
    }
    
    const response = await databases.account_create_requests.insertOne({
      requestId : requestId,
      username : newAccountUsername,
      email : newAccountEmail,
      creationDate : Date.now()
    })

    if (response.acknowledged === true){

            const emailData: nodemailer.SentMessageInfo = await sendMail(
          '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
          newAccountEmail,
          "Toaster account creation verification",
          `
Your account can be activated by going to the following link below

https://toaster.aikiwi.dev/use-create-account-code?requestId=${requestId}

If you need any help with this or someone is spamming you with these you can reach out to us at toaster@aikiwi.dev `);
      if (emailData) {
        console.log("created request");
        return res.status(200).send("created request");   
      }else{
        console.log("failed sending email");
        return res.status(500).send("failed to send email");
      }

    }else{
      console.log("server error create request");
      return res.status(500).send("server error create request");   

    }

  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})


async function createUser(rawEmail : string,password : string, username : string){
    try{
      const email = cleanEmailAddress(rawEmail);
      const passwordSalt : string = crypto.randomBytes(16).toString('hex');
      const hashedPassword : string = crypto.createHash("sha256")
      .update(password)
      .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
      .digest("hex");
  
      //make sure email is not in use
      let emailInUse : boolean = true;
      try{
        const result = await databases.user_credentials.findOne({ email: email })
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
          const result = await databases.user_credentials.findOne({ userId: userId })
          if (result === null){
            invalidUserId = false;
          }
        }catch(err){
          console.log(err);
        }
      }
     
      var tokenNotExpiredCode = generateRandomString(16);
  
      const userCredentialsOutput = await databases.user_credentials.insertOne(
        {
          userId: userId,
          email: email,
          hashedPassword: hashedPassword,
          passwordSalt: passwordSalt,
          accountBanReason: "",
          accountBanExpiryDate: 0,
          failedLoginAttemptInfo: {},
          tokenNotExpiedCode: tokenNotExpiredCode,
          hasLoggedIn : false
        }
      )
      const userDataOutput = await databases.user_data.insertOne(
        {
          userId: userId,
          username: username,
          bio: "",
          avatar: null,
          cooldowns: {},
          administrator: false,
          creationDate: Date.now(),
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

