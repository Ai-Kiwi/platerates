import express from 'express';
const router = express.Router();
import fs from 'fs';
import safeCompare from 'safe-compare';
import jwt, { JwtPayload } from 'jsonwebtoken';
import crypto, { privateEncrypt } from 'crypto';
import { databases } from './database';
import { millisecondsToTime, generateRandomString } from "./utilFunctions";
import { error } from 'console';
import { sendMail } from './mailsender';
import { userTimeout, userTimeoutTest } from './timeouts';
import { cleanEmailAddress } from './validInputTester';
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { Store } from 'express-rate-limit';
import { buffer } from 'stream/consumers';
import { confirmActiveAccount, confirmTokenValid } from './securityUtils';
import { reportError } from './errorHandler';

require('dotenv').config();

const privateKeyRaw = process.env.loginKey;
if (privateKeyRaw === undefined){
  console.log(crypto.randomBytes(512).toString('base64')) //128 bit keys
  error("no private key input")
}
const privateKey : Buffer = Buffer.from(privateKeyRaw as string, 'base64');


async function updateUserPassword(rawEmail : string, newPassword : string) {
  try {
    const email : string = cleanEmailAddress(rawEmail) as string;
    // Retrieve the user document using the email

    // Generate a new hashed password
    const passwordSalt : string = crypto.randomBytes(16).toString('hex');
    const hashedPassword : string = crypto.createHash("sha256")
    .update(newPassword)
    .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
    .digest("hex");

    const tokenNotExpiedCode : string = generateRandomString(16);
    // Update the user document with the new hashed password
    let collectionUpdate = await databases.user_credentials.updateOne(
      { email: email },
      { $set: {
        hashedPassword: hashedPassword,
        passwordSalt: passwordSalt,
        tokenNotExpiredCode: tokenNotExpiedCode,
        deviceNotificationTokens : []
      }}
      );
    
    if (collectionUpdate.acknowledged === true){
      return true;
    }else{
      return false;
    }

  } catch (err) {
    reportError(err);
    return false;
  }
}

async function testTokenValid(token : string,ipAddress : string){
  try{
    let decoded;
    try{
      decoded = jwt.verify(token, privateKey) as { userId: string, tokenNotExpiredCode: string, ipAddress: string } ;
    }catch (err){
      return {
        valid: false,
        userId: "",
      };
    }
    if (decoded == null){
      console.log("decoded is null");
      return {
        valid: false,
        userId: "",
      };
    };

    const userId : string = decoded.userId;

    //get data from server
    const userData = await databases.user_credentials.findOne({ userId: userId });

    //make sure user exists
    if (userData === null){
      console.log("user doesn't exist");
      return {
        valid: false,
        userId: "",
      };
    }

    //make sure token is not invald bcause of password reset
    if(decoded.tokenNotExpiredCode !== userData.tokenNotExpiredCode){
      console.log("invalid tokenNotExpiredCode");
      return {
        valid: false,
        userId: "",
      };
    };

    //another test to make sure it is the same ip address
    //if(decoded.ipAddress !== ipAddress){
    //  console.log("invalid ip address");
    //  return {
    //    valid: false,
    //    userId: "",
    //  };
    //};

    return {
      valid: true,
      userId : userId
    };

  }catch(err){
    reportError(err);
    return {      
      valid: false,
      userId: "",
    };
  }
  
}




// POST method route
router.post('/login', async (req : Request, res : Response) => {
  console.log(" => user attempting login")
  try{

    const userEmail = cleanEmailAddress(req.body.email);
    const userPassword = req.body.password;
    const userIpAddress : string = req.headers['x-forwarded-for'] as string;

    
    // get user info from database //
    const userData = await databases.user_credentials.findOne({ email: userEmail });
    //make sure it is vaild account lol
    if (userData === null){
      console.log("invalid credentials enterd")
      return res.status(401).send("invalid login credentials"); //incorrect login
    }

    const hashedPassword : string = userData.hashedPassword;
    const passwordSalt : string = userData.passwordSalt;
    const userId : string = userData.userId;

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
      

    const hashedPasswordEntered : string = crypto.createHash("sha256")
    .update(userPassword)
    .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
    .digest("hex");

    //if the username and password is the same
    if(safeCompare(hashedPasswordEntered,hashedPassword)){
      //should add a system for when it fails to sign, then again probs not needed
      let token : string = jwt.sign({
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

      //set account so that it has been logged into
      await databases.user_credentials.updateOne(
        { email: userEmail },
        { $set: {
          hasLoggedIn : true
        }
      }
      );
      return;

    }else{
      //will count up ip address lockout time
      const recentAttemptNumber = userData.failedLoginAttemptInfo[userIpAddress].recentAttemptNumber + 1;
      //don't like theses numbers quite yet.
      const lockoutTime = Date.now() + (Math.pow(1.250,recentAttemptNumber) * 5)  * 1000;
      const resetCounterTime = Date.now() + (Math.pow(1.250,recentAttemptNumber) * 15)  * 1000;

      //save to mongodb
      let updatedTimeout = await databases.user_credentials.updateOne(
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

      console.log("invalid login credentials");
      return res.status(401).send("invalid login credentials"); //incorrect login
    }
  }catch(err){
    reportError(err);
    return res.status(401).send("invalid login credentials");
  }
})

router.post('/login/logout', [confirmTokenValid], async (req : Request, res : Response) => {
  console.log(" => user log out")
    try{
      const userId : string | undefined = req.body.tokenUserId;
      
      
      //fetch the user credentials
      const userCreds = await databases.user_credentials.findOne({ userId :  userId})
      if (userCreds === null) {
        console.log("no user found");
        return res.status(404).send("no user found");
      
      }

      const newTokenNotExpiredCode : string = await generateRandomString(16);
      const reponse = await databases.user_credentials.updateOne({userId : userId}, { $set: {tokenNotExpiredCode : newTokenNotExpiredCode, deviceNotificationTokens : []}})
      if (reponse.acknowledged === true){
        console.log("user logged out")
        return res.status(200).send("user logged out");
      }else{
        console.log("failed to logout user");
        return res.status(500).send("failed to logout user");
      }

    }catch(err){
      reportError(err);
      return res.status(500).send("server error");
    }
})


router.post('/testToken', confirmTokenValid, async (req, res) => {
  console.log(" => user testing token")

  console.log("vaild token");
  return res.status(200).send("vaild token");

  
})

router.post('/login/reset-password', async (req, res) => {
  console.log(" => user creating reset password code");
  try{
    const email = cleanEmailAddress(req.body.email);
    const newPassword = req.body.newPassword;
    const token = req.body.token;
    const ipAddress : string = req.headers['x-forwarded-for'] as string;
    
    //const testTokenResult = await testToken(token,ipAddress);
    //const vaildToken : boolean = testTokenResult.valid;
    //const userId = testTokenResult.userId;
    
    //fetch user data
    const userCredentials = await databases.user_credentials.findOne({email: email});
    if (userCredentials === null){
      console.log("failed to find user");
      return res.status(404).send("user not found");
    }

    //test if password is nothing
    if (newPassword === null){
      console.log("password is nothing");
      return res.status(400).send("password is nothing");
    }

    //test for timeouts
    const TimeoutTestresult = await userTimeoutTest(userCredentials.userId,"reset-password");
    const timeoutActive : boolean = TimeoutTestresult.active;
    const timeoutTime : string | undefined = TimeoutTestresult.timeLeft;

    if (timeoutActive === true) {
      //test if user is logged in as them, if they are lower timeout to 10 minutes
      //if (userCredentials.userId === userId && vaildToken) {
      //  userTimeoutLimit(userCredentials.userId,"reset-password",60 * 10)
      //}
      console.log("reset password for user is timed out " + timeoutTime);
      return res.status(408).send("please wait " + timeoutTime + " to reset password");
      
    }

    //test if password is invalid
    if (newPassword.length === 0 || newPassword.length > 64) {
      console.log("password size invalid");
      return res.status(400).send("password size invalid");
    }


    const resetPasswordCode : string = generateRandomString(64);
    const resetPasswordUrl : string = `https://toaster.aikiwi.dev/reset-password?userId=${userCredentials.userId}&resetCode=${resetPasswordCode}`

    //send reset password
    console.log("sending email data")
    const emailData = await sendMail(
      '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
      email as string,
      "Password reset for toaster",
      "Your reset password request from ip address " + ipAddress + "\nclick on this link to reset password : " + resetPasswordUrl + "\nIf this wasn't you then you can safely ignore it, if someone keeps sending these requests to you, please contact toaster support for help in app."
    
    );
    if (emailData) {
      const passwordSalt : string = crypto.randomBytes(16).toString('hex');
      const hashedPassword : string = crypto.createHash("sha256")
      .update(newPassword)
      .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
      .digest("hex");
  
      const tokenNotExpiedCode : string = generateRandomString(16);


      const expireTime : number = Date.now() + (1000 * 60 * 15) // expires in 15m 
      const response = await databases.user_credentials.updateOne(
        { userId: userCredentials.userId },
        { $set: {
          resetPassword : {
            code : resetPasswordCode,
            newPassword : hashedPassword,
            newPasswordSalt :passwordSalt,
            newTokenNotExpiredCode : tokenNotExpiedCode,
            expireTime : expireTime,
          }
          }
        }
      );

      if (response.acknowledged === true) {
        userTimeout(userCredentials.userId,"reset-password",60 * 60 * 3); //timeout for a day
        return res.status(200).send("email reset password sent");
      }else{
        return res.status(500).send("server error");
      } 

    }else{
      console.log("failed sending email data");
      return res.status(500).send("server error");
    }
  }catch(err){
    reportError(err);
    return res.status(500).send("server error");
  }
})

router.get('/reset-password', async (req, res) => {
  const userId = req.query.userId;
  const resetCode = req.query.resetCode;
  const ipAddress = req.headers['x-forwarded-for'];

  try{
    const userCredentials = await databases.user_credentials.findOne({userId: userId});
    if (userCredentials === null){
      console.log("failed to find user");
      return res.status(404).send("user not found");
    }

    //test if code is valid
    if (userCredentials.resetPassword.code !== resetCode) {
      console.log("code invalid");
      return res.status(400).send("code invalid");
    }

    //test if code is expired
    if (userCredentials.resetPassword.expireTime <= Date.now()) {
      console.log("code expired");
      return res.status(410).send("code expired");
    }

    //update password
    const response = await databases.user_credentials.updateOne(
      { userId: userCredentials.userId },
        { $set: {
          hashedPassword : userCredentials.resetPassword.newPassword,
          passwordSalt : userCredentials.resetPassword.newPasswordSalt,
          tokenNotExpiredCode : userCredentials.resetPassword.newTokenNotExpiredCode,
          deviceNotificationTokens : []
          }
        }
    );
    if (response.acknowledged === true) {
      //expire code
      const response = await databases.user_credentials.updateOne(
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
      return res.status(200).send("password changed\nYou can now close this page and login to your account");

    }else{
      console.log("failed to change password");
      return res.status(500).send("failed to change password");

    }

    



  }catch(err){
    reportError(err);
    return res.status(500).send("server error");
  }
})

export {
  router,
  testTokenValid,
  updateUserPassword,
};