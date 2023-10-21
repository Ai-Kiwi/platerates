import mongoDB from "mongodb";
import { cleanEmailAddress } from "./validInputTester";
import { Request, Response } from "express";

import nodemailer from "nodemailer";
import { generateRandomString } from "./utilFunctions";
import { createUser, banAccount } from "./userAccounts";
import express from 'express';
import { testToken } from "./userLogin";
import { databases } from "./database";
import { sendMail } from "./mailsender";
import { testUsername } from "./validInputTester";
import { BlobOptions } from "buffer";
const router: express.Router = express.Router();


async function testUserAdmin(userId: string){
    try{
        const userData = await databases.user_data.findOne({ userId: userId}); 

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

            var userData = await databases.user_data.findOne({ userId: userId}); 

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
          console.log("user token is invalid");
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