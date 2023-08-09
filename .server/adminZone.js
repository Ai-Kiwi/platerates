const { createTestAccount } = require("nodemailer");
const { generateRandomString } = require("./utilFunctions");
const { createUser } = require("./userAccounts");
const express = require('express');
const { testToken } = require("./userLogin");
const { database } = require("./database");
const { sendMail } = require("./mailsender");
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
        const postId = req.body.postId;
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
                return res.status(200).send("email can't be nothing");   
            }
            if (newAccountUsername === null || newAccountUsername === undefined || newAccountUsername === "") {
                console.log("username empty");
                return res.status(200).send("username can't be nothing");   
            }

            //create password and send email
            const NewUserPassword = generateRandomString(16)
            const emailData = await sendMail(
                '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
                newAccountEmail,
                "accepted into toaster beta",
                `you have been accepted into toaster beta and your user account password is ${NewUserPassword} please change this as soon as you get into your toaster account for your security`
            );
            if (emailData) {
                //add user to database
                const response = await createUser(newAccountEmail,NewUserPassword,newAccountUsername) 
                if (response === true) {
                    console.log("user created");
                    return res.status(200).send("user created");   
                }else{
                    console.log("failed creating user");
                    return res.status(500).send("failed creating user");
                }


            }else{
                console.log("failed sending email");
                return res.status(500).send("failed to send email");
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

        var vaildToken, userId;
        [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
      
        if (vaildToken) { // user token is valid

            var userDataCollection = database.collection('user_data');
            var userData = await userDataCollection.findOne({ userId: userId}); 

            if (userData.administrator !== true) {
                console.log("user not admin");
                return res.status(403).send("you are not an admin");
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