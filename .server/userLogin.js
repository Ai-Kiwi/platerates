const express = require('express');
const router = express.Router();
const fs = require('fs');
const safeCompare = require('safe-compare');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { database } = require('./database');



//fs.writeFileSync('private.key',crypto.randomBytes(32))
const privateKey = fs.readFileSync('private.key'); 


async function updateUserPassword(email, newPassword) {
    try {
      // Retrieve the user document using the email
      const collection = database.collection("user_credentials");
  
      const user = collection.findOne({ email:email })
  
      if (!user) {
        throw new Error('User not found');
      }
  
      // Generate a new hashed password
      const passwordSalt = crypto.randomBytes(16).toString('hex');
      const hashedPassword = crypto.createHash("sha256")
      .update(newPassword)
      .update(crypto.createHash("sha256").update(passwordSalt, "utf8").digest("hex"))
      .digest("hex");
  
  
      // Update the user document with the new hashed password
      await collection.updateOne(
        { _id: user._id },
        { $set: {
          hashedPassword: hashedPassword,
          passwordSalt: passwordSalt,
        }}
        );
    } catch (error) {
      console.log('Error updating password:', error);
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
  
      //make sure token is not invald bcause of password reset
      if(decoded.tokenNotExpiredCode !== userData.tokenNotExpiredCode){
        return [false]; 
      };
  
      //another test to make sure it is the same ip address
      if(decoded.ipAddress !== ipAddress){
        return [false];
      };
  
      //another test to make sure device header informastion is the same as before
  
  
      //make sure to test if the token time is out of date
      //look into soon think its auto done
      return [true, userId];
      
  
    }catch(err){
      console.log(err);
      return [false];
    }
  
}


// POST method route
router.post('/login', async (req, res) => {
    try{
      console.log("user login")
      //add rate limitng
      //add system to see if the same ip address is making alot of requests
      //add system to make sure account is not locked with all ip's, that ip or anything
      //add system to make sure account is not banned
      //MAKE SURE WHEN SETTING UP NGINX TO SEE THAT IT FORWARDS IP ADDRESSES
      //make sure they are not in global ip addresses banned
      //add to login history
      //add a system that locks out ip addresses for along time instead of just alittle bit.
  
      const userEmail = req.body.email;
      const userPassword = req.body.password;
      const userIpAddress = req.ip;
  
      //https://www.npmjs.com/package/jsonwebtoken
      //bind info like ip address and stuff to token as well
      //bind when it was made to token
  
      
      // get user info from database //
      const collection = database.collection('user_credentials');
  
      const userData = await collection.findOne({ email: userEmail });
      //make sure it is vaild account lol
      if (userData === null){
        res.status(401).send("invalid login credentials"); //incorrect login
        return;
      }
      const hashedPassword = userData.hashedPassword;
      const passwordSalt = userData.passwordSalt;
      const userId = userData.userId;
      
      //   tests to run   //
      //login cooldown
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
          res.status(408).send("login timeout " + String(Math.ceil((userData.failedLoginAttemptInfo[userIpAddress].lockoutTime - Date.now()) / 1000)) + " seconds left")
  
  
          return;
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
        await collection.updateOne(
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
        res.status(401).send("invalid login credentials"); //incorrect login
        return;
      }
  
      //res.send('POST request to the homepage')
    }catch(err){
      res.status(401).send("invalid login credentials");
      console.log(err);
      return;
    }
})


router.post('/testToken', async (req, res) => {
    console.log("user testing token")
    const token = req.body.token;
    var tokenVaild, userId;
    [tokenVaild, userId] = await testToken(token,req.ip)
  
    if(tokenVaild){
      console.log("vaild token");
      res.status(200).send();
    }else{
      console.log("invaild token");
      res.status(401).send();
    }
  
})



module.exports = {
    router: router,
    testToken: testToken,
};