import mongoDB from "mongodb";
import { cleanEmailAddress } from "./validInputTester";
import { Request, Response } from "express";

import nodemailer from "nodemailer";
import { generateRandomString } from "./utilFunctions";
import { createUser, banAccount } from "./userAccounts";
import express from 'express';
import { testToken } from "./userLogin";
import { database } from "./database";
import { sendMail } from "./mailsender";
import { testUsername } from "./validInputTester";
import { BlobOptions } from "buffer";
const router: express.Router = express.Router();


async function testUserAdmin(userId: string){
    try{
        const userDataCollectionollection: mongoDB.Collection = database.collection('user_data');
        const userData = await userDataCollectionollection.findOne({ userId: userId}); 

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



router.post('/admin/createUser', async (req : Request, res : Response) => {
    console.log(" => admin creating user")
    try{
        const token = req.body.token;
        const newAccountEmail = cleanEmailAddress(req.body.email);
        const newAccountUsername = req.body.username;

        const userIpAddress : string = req.headers['x-forwarded-for'] as string;

        const result = await testToken(token,userIpAddress);
        const validToken : boolean = result.valid;
        const userId : string | undefined = result.userId;

        if (validToken) { // user token is valid

            let userDataCollection: mongoDB.Collection = database.collection('user_data');
            let userData = await userDataCollection.findOne({ userId: userId}); 

            if (userData === null) {
                console.log("tokens user not found");
                return res.status(500).send("tokens user not found");
            }

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
            const testUsernameResult = await testUsername(newAccountUsername);
            const usernameAllowed : boolean = testUsernameResult.valid;
            const usernameDeniedReason : string = testUsernameResult.reason;



            if (usernameAllowed === false){
                console.log("username input in valid");
                return res.status(400).send(usernameDeniedReason);    
            }


            //create password and send email
            const NewUserPassword : string = generateRandomString(16)

            //add user to database
            const response: boolean = await createUser(newAccountEmail,NewUserPassword,newAccountUsername) 
            if (response === true) {
                const emailData: nodemailer.SentMessageInfo = await sendMail(
                    '"no-reply toaster" <toaster@noreply.aikiwi.dev>',
                    newAccountEmail,
                    "accepted into toaster beta",
                    `
Hi user,
We're excited to announce that you've been accepted into the beta for Toaster! Toaster is an app all about sharing and rating toast. You can share your own toast and get ratings from other users.

Your account has been created and you can log in at https://toaster.aikiwi.dev/. Your temporary password is below please change this once logged in using reset password.

   login email address : ${newAccountEmail}
   temporary password : ${NewUserPassword}

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
            return res.status(401).send("invalid token");
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

        const userIpAddress : string = req.headers['x-forwarded-for'] as string;

        const result = await testToken(token,userIpAddress);
        const validToken : boolean = result.valid;
        const userId : string | undefined = result.userId;
      
        if (validToken) { // user token is valid

            var userDataCollection: mongoDB.Collection = database.collection('user_data');
            var userData = await userDataCollection.findOne({ userId: userId}); 

            if (userData === null) {
                console.log("tokens user not found");
                return res.status(500).send("tokens user not found");
            }

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
          return res.status(401).send("invalid token");
        }
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
})

export {
    router,
    testUserAdmin,
};