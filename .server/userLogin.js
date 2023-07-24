const express = require('express');
const router = express.Router();
const fs = require('fs');
const safeCompare = require('safe-compare');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { database } = require('./database');
const { millisecondsToTime, generateRandomString } = require("./utilFunctions");
const { error } = require('console');
const { sendMail } = require('./mailsender');
const { userTimeout, userTimeoutTest } = require('./timeouts');


if (fs.existsSync('private.key') === false) {
  fs.writeFileSync('private.key',crypto.randomBytes(32))
}
const privateKey = fs.readFileSync('private.key'); 


async function updateUserPassword(email, newPassword) {
  try {
    // Retrieve the user document using the email
    const collection = database.collection("user_credentials");

    // Generate a new hashed password
    const passwordSalt = crypto.randomBytes(16).toString('hex');
    const hashedPassword = crypto.createHash("sha256")
    .update(newPassword)
    .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
    .digest("hex");

    const tokenNotExpiedCode = generateRandomString(16);
    // Update the user document with the new hashed password
    let collectionUpdate = await collection.updateOne(
      { email: email },
      { $set: {
        hashedPassword: hashedPassword,
        passwordSalt: passwordSalt,
        tokenNotExpiredCode: tokenNotExpiedCode,
      }}
      );
    
    if (collectionUpdate.acknowledged === true){
      return true;
    }else{
      return false;
    }

  } catch (error) {
    console.log('Error updating password:', error);
    return false;
  }
}

async function testToken(token,ipAddress){
  try{
    var decoded = "";
    try{
      decoded = jwt.verify(token, privateKey);
    }catch (err){
      console.log(err);
      return [false];
    }
    if (decoded == null){
      return [false]
    };

    const userId = decoded.userId;

    //get data from server
    var collection = database.collection('user_credentials');
    const userData = await collection.findOne({ userId: userId });

    //make sure user exists
    if (userData === null){
      console.log("user doesn't exist");
      return [false];
    }

    //make sure token is not invald bcause of password reset
    if(decoded.tokenNotExpiredCode !== userData.tokenNotExpiredCode){
      console.log("invaild tokenNotExpiredCode");
      return [false]; 
    };

    //another test to make sure it is the same ip address
    if(decoded.ipAddress !== ipAddress){
      console.log("invaild ip address");
      return [false];
    };

    return [true, userId];

  }catch(err){
    console.log(err);
    return [false];
  }
  
}




// POST method route
router.post('/login', async (req, res) => {
  console.log(" => user attempting login")
  try{

    const userEmail = req.body.email;
    const userPassword = req.body.password;
    const userIpAddress = req.headers['x-forwarded-for'];

    
    // get user info from database //
    const collection = database.collection('user_credentials');

    const userData = await collection.findOne({ email: userEmail });
    //make sure it is vaild account lol
    if (userData === null){
      console.log("invaild credentials enterd")
      return res.status(401).send("invalid login credentials"); //incorrect login
    }

    const hashedPassword = userData.hashedPassword;
    const passwordSalt = userData.passwordSalt;
    const userId = userData.userId;

    //look if account is banned
    if (userData.accountBanExpiryDate > Date.now()){
      console.log("account is banned")
      return res.status(403).send(`account banned ${ millisecondsToTime( userData.accountBanExpiryDate - Date.now() ) }`);
    }

    //the way this works is abit werid so ima explain it.
    //when a login it failed a counter storeing recent failed logins will increase, depending on how high this value is a time will be set for when the account will be unlocked out, worth noting when that time expires this counter will not go back down.
    //another counter is stored, which is when these login attempts will expire, each new failed login attempt will incresse this value, 
    //however there is a second counter which stores how long until the counter will be reset, this is much longer and this counter may still be running while you can still login.
    if (userData.failedLoginAttemptInfo[userIpAddress] === undefined){
      //make the info setup
      userData.failedLoginAttemptInfo[userIpAddress] = {
        recentAttemptNumber : 0,
        resetCounterTime : 0,
        lockoutTime : 0,
      }
    }
    
    //if the counter is greater than the time until the counter is reset, then the account is locked
    if(userData.failedLoginAttemptInfo[userIpAddress].recentAttemptNumber > 0){
      //if lockout time is still within the range of login
      if(userData.failedLoginAttemptInfo[userIpAddress].lockoutTime > Date.now()){
        console.log("login time out");
        return res.status(408).send("login timeout " + String(Math.ceil((userData.failedLoginAttemptInfo[userIpAddress].lockoutTime - Date.now()) / 1000)) + " seconds left")

      }else{
        //see counter is due to be reset
        if(userData.failedLoginAttemptInfo[userIpAddress].resetCounterTime > Date.now()){
          //reset all counters
          userData.failedLoginAttemptInfo[userIpAddress].recentAttemptNumber = 0;
          userData.failedLoginAttemptInfo[userIpAddress].resetCounterTime = 0;
          userData.failedLoginAttemptInfo[userIpAddress].lockoutTime = 0;
        }
      }
    }
      

    const hashedPasswordEntered = crypto.createHash("sha256")
    .update(userPassword)
    .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
    .digest("hex");

    //if the username and password is the same
    if(safeCompare(hashedPasswordEntered,hashedPassword)){
      //should add a system for when it fails to sign, then again probs not needed
      var token = jwt.sign({
        userId : userId,
        ipAddress : userIpAddress,
        //token not expired code, used to make sure that user has not done password reset or anything
        tokenNotExpiredCode: userData.tokenNotExpiredCode,
      }, privateKey, {expiresIn: '30d'});

      console.log("sent login info");
      res.status(200).json({
        token: token,
        userId: userId,
      });
      return;

    }else{
      //will count up ip address lockout time
      const recentAttemptNumber = userData.failedLoginAttemptInfo[userIpAddress].recentAttemptNumber + 1;
      //don't like theses numbers quite yet.
      const lockoutTime = Date.now() + (Math.pow(1.250,recentAttemptNumber) * 5)  * 1000;
      const resetCounterTime = Date.now() + (Math.pow(1.250,recentAttemptNumber) * 15)  * 1000;

      //save to mongodb
      let updatedTimeout = await collection.updateOne(
        { email: userEmail },
        { $set: {
          failedLoginAttemptInfo: {
            [userIpAddress]: {
              recentAttemptNumber : recentAttemptNumber,
              resetCounterTime: resetCounterTime,
              lockoutTime : lockoutTime,
              }
            }
          }
        }
      );

      if (updatedTimeout.acknowledged != true){
        Error("failed to add user timeout to database");
      }

      console.log("invaild login credentials");
      return res.status(401).send("invalid login credentials"); //incorrect login
    }
  }catch(err){
    console.log(err);
    return res.status(401).send("invalid login credentials");
  }
})

router.post('/login/logout', async (req, res) => {
  console.log(" => user log out")
    try{
      const token = req.body.token;
      var vaildToken, userId;
  
      [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
    
      if (vaildToken) { // user token is valid
        var collection = database.collection('user_credentials');
        var posts;

        //fetch the user credentials
        const userCreds = await collection.findOne({ userId :  userId})
        if (userCreds === null) {
          console.log("no user found");
          return res.status(404).send("no user found");
        
        }

        const newTokenNotExpiredCode = await generateRandomString(16);
        const reponse = await collection.updateOne({userId : userId}, { $set: {tokenNotExpiredCode : newTokenNotExpiredCode}})
        if (reponse.acknowledged === true){
          console.log("user logged out")
          return res.status(200).send("user logged out");
        }else{
          console.log("failed to logout user");
          return res.status(500).send("failed to logout user");
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


router.post('/testToken', async (req, res) => {
  console.log(" => user testing token")
  const token = req.body.token;
  var tokenVaild, userId;
  [tokenVaild, userId] = await testToken(token,req.headers['x-forwarded-for'])

  if(tokenVaild){
    console.log("vaild token");
    return res.status(200).send("vaild token");
  }else{
    console.log("invaild token");
    return res.status(401).send("invaild token");
  }
  
})

router.post('/login/reset-password', async (req, res) => {
  console.log(" => user creating reset password code");
  try{
    const email = req.body.email;
    const newPassword = req.body.newPassword;
    const resetCode = req.body.resetCode;
    const ipAddress = req.headers['x-forwarded-for'];
    const userCredentialsCollection = database.collection("user_credentials");
    
    //fetch user data
    const userCredentials = await userCredentialsCollection.findOne({email: email});
    if (userCredentials === null){
      console.log("failed to find user");
      return res.status(404).send("user not found");
    }


    //if it has a value then it must be 2nd request which is using code
    //if it doesn't have a value then they must be 
    if (resetCode) {
      //test if code is valid
      if (userCredentials.resetPassword.code !== resetCode) {
        console.log("code invalid");
        return res.status(400).send("code invalid");
      }

      //test if password is nothing
      if (newPassword === null){
        console.log("password is nothing");
        return res.status(400).send("password is nothing");
      }
      

      //test if code is expired
      if (userCredentials.resetPassword.expireTime <= Date.now()) {
        console.log("code expired");
        return res.status(410).send("code expired");
      }

      //test if password is invalid
      if (newPassword.length === 0 || newPassword.length > 32) {
        console.log("password size invalid");
        return res.status(400).send("password size invalid");
      }
      console.log(email)
      console.log(newPassword)
      //update password
      const response = await updateUserPassword(email,newPassword);
      if (response === true) {
        //expire code
        const response = await userCredentialsCollection.updateOne(
          { userId: userCredentials.userId },
          { $set: {
            resetPassword : {
              expireTime : 0,
            }
            }
          }
        );
        if (response.acknowledged === false){
          console.log("failed to remove code from usable");
        }

        console.log("changed password");
        return res.status(200).send("password changed");

      }else{
        console.log("failed to change password");
        return res.status(500).send("failed to change password");

      }
      
    }else{
      //test for timeouts
      const [timeoutActive, timeoutTime] = await userTimeoutTest(userCredentials.userId,"create-reset-password-code");
      if (timeoutActive === true) {
        console.log("reset password for user is timed out " + timeoutTime);
        return res.status(408).send("please wait " + timeoutTime + " to reset password");
      }


      const resetPasswordCode = generateRandomString(8);

      //send reset password
      console.log("sending email data")
      const emailData = await sendMail(
        '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
        email,
        "Password reset code for toaster",
        "Your one time toaster account password reset code from ip address " + ipAddress + " is " + resetPasswordCode + "\nIf this wasn't you then you can safely ignore it, if someone keeps sending these requests to you, please contact toaster support for help in app."

      );
      if (emailData) {
        const expireTime = Date.now() + (1000 * 60 * 15) // expires in 15m 
        const response = await userCredentialsCollection.updateOne(
          { userId: userCredentials.userId },
          { $set: {
            resetPassword : {
              code : resetPasswordCode,
              expireTime : expireTime,
            }
            }
          }
        );

        if (response.acknowledged === true) {
          userTimeout(userCredentials.userId,"create-reset-password-code",60 * 60 * 24);
          return res.status(200).send("created password reset code");

        }else{
          return res.status(500).send("server error");
        } 

      }else{
        console.log("failed sending email data");
        return res.status(500).send("server error");
      }
    }

}catch(err){
  console.log(err);
  return res.status(500).send("server error");
}
  
})

module.exports = {
    router: router,
    testToken: testToken,
    updateUserPassword: updateUserPassword,
};