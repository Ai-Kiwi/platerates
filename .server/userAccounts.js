const express = require('express');
const router = express.Router();
const { database } = require('./database');
const { testToken } = require('./userLogin');
const { generateRandomString } = require('./utilFunctions');


router.post('/profile/data', async (req, res) => {
    console.log("user fetching profile")
    try{
      const token = req.body.token;
      const userId = req.body.userId;
      [validToken, requesterUserId] = await testToken(token,req.ip);
      const collection = database.collection('user_data');
  
      if (validToken === false){
        res.status(401).send("invaild token");
      }
  
  
      //if they dont supply any user just fetch themselves
      var fetchingUserId = requesterUserId
      if (req.query.userId) {
        fetchingUserId = req.query.userId;
      }
  
      const userData = await collection.findOne({ userId: userId })
      
      if (userData === undefined || userData === null){
        res.status(400).send("unkown user");
        console.log("failed unkown error");
      }
  
      res.status(200).json({
        username: userData.username,
        bio: userData.bio,
  
      });
      
    }catch(err){
      console.log(err);
      res.status(500).send("server error")
    }
})



router.post('/profile/posts', async (req, res) => {
  try{
    const token = req.body.token;
    const startPosPost = req.body.startPosPost;
    const fetchingUserId = req.body.userId;
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

      posts = await collection.find({posterUserId : fetchingUserId, shareMode: 'public', postDate: { $lt: startPosPostDate}}).sort({postDate: -1}).limit(5).toArray();
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
          accountBanned: false,
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
};