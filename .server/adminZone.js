const { createTestAccount } = require("nodemailer");
const { generateRandomString } = require("./utilFunctions");
const { createUser, banAccount } = require("./userAccounts");
const express = require('express');
const { testToken } = require("./userLogin");
const { database } = require("./database");
const { sendMail } = require("./mailsender");
const { testUsername } = require("./validInputTester");
const router = express.Router();


async function testUserAdmin(userId){
    try{
        var userDataCollectionollection = database.collection('user_data');
        var userData = await userDataCollectionollection.findOne({ userId: userId}); 

        if (userData === null){
            return false
        }else{
            if (userData.administrator === true){
                return true
            }else{
                return false
            }
        }
    }catch(err){
        return false
    }
}



router.post('/admin/createUser', async (req, res) => {
    console.log(" => admin creating user")
      try{
        const token = req.body.token;
        const newAccountEmail = req.body.email;
        const newAccountUsername = req.body.username;

        var vaildToken, userId;
        [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
      
        if (vaildToken) { // user token is valid

            var userDataCollection = database.collection('user_data');
            var userData = await userDataCollection.findOne({ userId: userId}); 

            if (userData.administrator !== true) {
                console.log("user not admin");
                return res.status(403).send("you are not an admin");
            }

            //test that username and email has a value
            if (newAccountEmail === null || newAccountEmail === undefined || newAccountEmail === "") {
                console.log("email empty");
                return res.status(400).send("email can't be nothing");   
            }
            if (newAccountUsername === null || newAccountUsername === undefined || newAccountUsername === "") {
                console.log("username empty");
                return res.status(400).send("username can't be nothing");   
            }

            //test username
            var usernameAllowed, usernameDeniedReason;
            [usernameAllowed, usernameDeniedReason] = await testUsername(newAccountUsername);
            if (usernameAllowed === false){
                console.log("username input in valid");
                return res.status(400).send(usernameDeniedReason);    
            }


            //create password and send email
            const NewUserPassword = generateRandomString(16)

            //add user to database
            const response = await createUser(newAccountEmail,NewUserPassword,newAccountUsername) 
            if (response === true) {
                const emailData = await sendMail(
                    '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
                    newAccountEmail,
                    "accepted into toaster beta",
                    `
Hi user,
We're excited to announce that you've been accepted into the beta for Toaster! Toaster is an app all about sharing and rating toast. You can share your own toast and get ratings from other users.

Your account has been created and you can log in at https://toaster.aikiwi.dev/. Your temporary password is ${NewUserPassword} please change this once logged in.

We ask to once again remind you this is a beta and that bugs and issues will happen. Please reach out to us by email describing any bugs or suggestions you have, it helps alot! You can help us at toaster@aikiwi.dev.

We hope you enjoy using Toaster! We're always looking for feedback, so please feel free to reach out to us with any questions or suggestions at toaster@aikiwi.dev.

Welcome to the Toaster community! We're a welcoming community and we expect all users to treat each other with respect. Please be kind and helpful to other users, and avoid any behaviour that could be considered offensive or harmful.

For any concerns about data handling you can find our privacy policy at https://toaster.aikiwi.dev/privacyPolicy and our data deletion instructions at https://toaster.aikiwi.dev/deleteData. 

Thanks,
The Toaster Team`);
                if (emailData) {
                    console.log("user created");
                    return res.status(200).send("user created");   
                }else{
                    console.log("failed sending email");
                    return res.status(500).send("failed to send email");
                }
            }else{
                console.log("failed creating user");
                return res.status(500).send("failed creating user");
            }



  


    
        }else{
          console.log("user token is invaild");
          return res.status(401).send("invaild token");
        }
      }catch(err){
        console.log(err);
        return res.status(500).send("server error")
      }
  })



router.post('/admin/banUser', async (req, res) => {
  console.log(" => admin creating user")
    try{
        const token = req.body.token;
        const userIdBanning = req.body.userId;
        const banReason = req.body.reason;
        const banTime = req.body.time;

        var vaildToken, userId;
        [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
      
        if (vaildToken) { // user token is valid

            var userDataCollection = database.collection('user_data');
            var userData = await userDataCollection.findOne({ userId: userId}); 

            if (userData.administrator !== true) {
                console.log("user not admin");
                return res.status(403).send("you are not an admin");
            }





            
            if (await banAccount(userIdBanning,parseInt(banTime),banReason)){
                console.log("user banned");
                return res.status(200).send("user banned");
            }else{
                console.log("user not banned");
                return res.status(400).send("user not banned");
            }


  


    
        }else{
          console.log("user token is invaild");
          return res.status(401).send("invaild token");
        }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
})

module.exports = {
    router:router,
    testUserAdmin:testUserAdmin,
};