const express = require('express');
const router = express.Router();
const { database } = require('./database');
const { testToken } = require('./userLogin');
const { generateRandomString } = require('./utilFunctions');
const { versions } = require('sharp');



router.post('/profile/basicData', async (req, res) => {
  console.log(" => user fetching profile")
  try{
    const token = req.body.token;
    const userId = req.body.userId;
    [validToken, requesterUserId] = await testToken(token,req.headers['x-forwarded-for']);
    const collection = database.collection('user_data');

    if (validToken === false){
      console.log("returned invaild token");
      return res.status(401).send("invaild token");
    }




    const userData = await collection.findOne({ userId: userId })
    
    if (userData === undefined || userData === null){
      console.log("failed as invaild user");
      return res.status(400).send("unkown user");
    }

    res.status(200).json({
      username: userData.username,
      userAvatar : userData.avatar,
    });
    
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
        if (value.length > 25) {
          console.log("username to large")
          return res.status(400).send("username to large")
        }

        const collection = database.collection('user_data');

        const response = await collection.updateOne({userId: userId},{ $set: {username : value}}) 

        if (response.acknowledged === true) {
          console.log("updated username")
          return res.status(200).send("updated username")
        }else{
          console.log("failed to update username")
          return res.status(400).send("failed to update username")
        }


      }else{
        console.log("unkown setting")
        return res.status(400).send("unkown setting")
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
      [validToken, requesterUserId] = await testToken(token,req.headers['x-forwarded-for']);
      const collection = database.collection('user_data');
  
      if (validToken === false){
        console.log("returned invaild token");
        return res.status(401).send("invaild token");
      }
  
      //if they dont supply any user just fetch themselves
      if (!userId) {
        userId = requesterUserId;
      }
  
      const userData = await collection.findOne({ userId: userId });
      
      if (userData === undefined || userData === null){
        console.log("failed as invaild user");
        return res.status(400).send("unkown user");
      }

      if (userData.shareMode != "public") {
        console.log("no perms to view profile");
        return res.status(400).send("no perms to view profile");
      }
  
      console.log("returning output");
      return res.status(200).json({
        username: userData.username,
        bio: userData.bio,
      });
      
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
          return res.status(400).send("invaild start post");
        }

        const startPosPostData = await collection.findOne({ postId: startPosPost.data })
        if (!startPosPostData){
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

async function banAccount(userId,time) {
  try{
    const collection = database.collection("user_credentials");

    const result = await collection.updateOne(
      { userId: userId },
      { $set: {
        accountBanExpiryDate : Date.now() + time,
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
        return false;
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
          loginHistory: {},
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
        return true;
      }
  
      return false
    }catch (err){
      console.log(err);
      return false;
    }
    //phone number
  
}

module.exports = {
    router:router,
    banAccount:banAccount,
};