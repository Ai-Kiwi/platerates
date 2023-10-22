import mongoDB from "mongodb";
import { cleanEmailAddress } from "./validInputTester";
import { Request, Response } from "express";

import nodemailer from "nodemailer";
import { generateRandomString } from "./utilFunctions";
import { createUser, banAccount } from "./userAccounts";
import express from 'express';
import { databases } from "./database";
import { sendMail } from "./mailsender";
import { testUsername } from "./validInputTester";
import { BlobOptions } from "buffer";
import { confirmTokenValid } from "./securityUtils";
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



router.post('/admin/banUser', confirmTokenValid, async (req, res) => {
  console.log(" => admin creating user")
    try{
        const userIdBanning = req.body.userId;
        const banReason = req.body.reason;
        const banTime = req.body.time;
        const userId : string | undefined = req.body.tokenUserId;

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
    }catch(err){
      console.log(err);
      return res.status(500).send("server error")
    }
})

export {
    router,
    testUserAdmin,
};