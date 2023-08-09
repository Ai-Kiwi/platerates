const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const { database } = require('./database');
const { testToken } = require('./userLogin');
const { generateRandomString } = require('./utilFunctions');
const { versions } = require('sharp');
const { userTimeout, userTimeoutTest } = require('./timeouts');
const { testUsername } = require('./validInputTester');
const { title } = require('process');

async function sendNoticeToAccount(userId, text, title){
  const collection = database.collection('account_notices');
  const response = await collection.insertOne({
    userId: userId,
    title: title,
    text: text,
  });

  if (response === true){
    return true;
  }else{
    return false;
  }
}

router.post('/profile/basicData', async (req, res) => {
  console.log(" => user fetching profile")
  try{
    const token = req.body.token;
    const userId = req.body.userId;
    var vaildToken;
    var requesterUserId;
    [vaildToken, requesterUserId] = await testToken(token,req.headers['x-forwarded-for']);
    const collection = database.collection('user_data');

    if (vaildToken) { // user token is valid
      const userData = await collection.findOne({ userId: userId })
      
      if (userData === undefined || userData === null){
        console.log("failed as invaild user");
        return res.status(404).send("unkown user");
      }

      console.log("sending basic data");
      res.status(200).json({
        username: userData.username,
        userAvatar : userData.avatar,
      });

    }else{
      console.log("returned invaild token");
      return res.status(401).send("invaild token");
    
    }
    
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})



router.post('/profile/settings/change', async (req, res) => {
  console.log(" => user profile setting change")
  try{
    const token = req.body.token;
    const setting = req.body.setting;
    const value = req.body.value;

    var vaildToken, userId;
    [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
  
    if (vaildToken) { // user token is valid

      if (setting === "username") {
        //test timeout
        const [timeoutActive, timeoutTime] = await userTimeoutTest(userId,"change_username")
        if (timeoutActive === true) {
          console.log("username timed out " + timeoutTime);
          return res.status(408).send("please wait " + timeoutTime + " to change username");
        }

        var usernameAllowed, usernameDeniedReason;
        [usernameAllowed, usernameDeniedReason] = await testUsername(value);

        if (usernameAllowed === false) {
          console.log(usernameDeniedReason)
          return res.status(400).send(usernameDeniedReason)
        }

        const collection = database.collection('user_data');

        const response = await collection.updateOne({userId: userId},{ $set: {username : value}}) 

        if (response.acknowledged === true) {
          //update username
          userTimeout(userId,"change_username", 60 * 60 * 24 * 7);
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
  
          const collection = database.collection('user_data');
  
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



router.post('/profile/data', async (req, res) => {
    console.log(" => user fetching profile")
    try{
      const token = req.body.token;
      var userId = req.body.userId;
      var validToken, requesterUserId;
      [validToken, requesterUserId] = await testToken(token,req.headers['x-forwarded-for']);
      const collection = database.collection('user_data');

      if (validToken){
        
        //if they dont supply any user just fetch themselves
        if (!userId) {
          userId = requesterUserId;
        }
      
        const userData = await collection.findOne({ userId: userId });

        if (userData === undefined || userData === null){
          console.log("failed as invaild user");
          return res.status(404).send("unkown user");
        }

        if (userData.shareMode != "public") {
          console.log("no perms to view profile");
          return res.status(403).send("no perms to view profile");
        }
      
        console.log("returning profile data");
        return res.status(200).json({
          username: userData.username,
          bio: userData.bio,
          administrator: userData.administrator,
          userId: userId,
        });

      }else{
        console.log("returned invaild token");
        return res.status(401).send("invaild token");
      }
      
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
})

router.post('/profile/posts', async (req, res) => {
  console.log(" => user fetching posts on profile")
  try{
    const token = req.body.token;
    const startPosPost = req.body.startPosPost;
    const fetchingUserId = req.body.userId;
    var startPosPostDate = 100000000000000

    var vaildToken, userId;
    [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
  
    if (vaildToken) { // user token is valid
      var collection = database.collection('posts');
      var posts;

      if (startPosPost) {
        if (startPosPost.type === "post" && !startPosPost.data){
          console.log("invalid start post");
          return res.status(400).send("invaild start post");
        }

        const startPosPostData = await collection.findOne({ postId: startPosPost.data })
        if (!startPosPostData){
          console.log("invalid start post");
          return res.status(400).send("invaild start post");
        }
          
        startPosPostDate = startPosPostData.postDate;
      }

      posts = await collection.find({posterUserId : fetchingUserId, shareMode: 'public', postDate: { $lt: startPosPostDate}}).sort({postDate: -1}).limit(5).toArray();
      var returnData = {}
      returnData["items"] = []
      
      if (posts.length == 0) {
        console.log("nothing to fetch");
      }

      for (var i = 0; i < posts.length; i++) {
        returnData["items"].push({
          type : "post",
          data : posts[i].postId
        });
        //Do something
      }

      console.log("returning posts");
      return res.status(200).json(returnData);

    }else{
      console.log("invaild token")
      return res.status(401).send("invaild token");
    }
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

async function banAccount(userId,time,reason) {
  try{
    const collection = database.collection("user_credentials");

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

async function createUser(email,password,username){
    try{
      const userCredentialsCollection = database.collection("user_credentials");
      const userDataCollection = database.collection("user_data");
      const passwordSalt = crypto.randomBytes(16).toString('hex');
      const hashedPassword = crypto.createHash("sha256")
      .update(password)
      .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
      .digest("hex");
  
      //make sure email is not in use
      var emailInUse = true;
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

      var usernameAllowed, usernameDeniedReason;
      [usernameAllowed, usernameDeniedReason] = await testUsername(username);

      if (usernameAllowed === false) {
        console.log(usernameDeniedReason)
        return res.status(400).send(usernameDeniedReason)
      }
  
      //create userId and make sure no one has it
      var userId = "";
      var invaildUserId = true;
      while(invaildUserId){
        userId = generateRandomString(16);
        try{
          const result = await userCredentialsCollection.findOne({ userId: userId })
          if (result === null){
            invaildUserId = false;
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
      }
  

    }catch (err){
      console.log(err);
      return false;
    }
    //phone number
  
}

module.exports = {
    router:router,
    banAccount:banAccount,
    createUser:createUser,
    sendNoticeToAccount:sendNoticeToAccount,
};