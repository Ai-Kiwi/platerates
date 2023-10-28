import express from 'express';
const router = express.Router();
import { Request, Response } from "express";
import { Licenses, appCheckVerification, confirmActiveAccount, confirmTokenValid } from './securityUtils';
import nodemailer from "nodemailer";
import { sendMail } from './mailsender';
import mongoDB from "mongodb";
import { databases } from "./database";
import { reportError } from './errorHandler';



router.post('/licenses/unaccepted', [confirmTokenValid], async (req : Request, res : Response) => {
    console.log(" => user fetching unread licenses")
    try{
        const userId = req.body.tokenUserId;

        const userData = await databases.user_data.findOne({ userId : userId })
    
        if (userData === null){
            console.log("user id from token invalid")
            res.status(404).send(`user id from token invalid`);
            return;
        }

        var LicensesToUpdate = {}
    
        for (const key in Licenses) {
            if (userData.licenseAccepted === null || userData.licenseAccepted === undefined){
                LicensesToUpdate[key] = Licenses[key];
            }else{
                if (Licenses[key] != userData.licenseAccepted[key]){
                    LicensesToUpdate[key] = Licenses[key];
                }
            }
        }

        console.log("send unaccepted licenses")
        return res.status(200).send(JSON.stringify(LicensesToUpdate))
      
    }catch(err){
    reportError(err);
      return res.status(500).send("server error")
    }
})



router.post('/licenses/update', [confirmTokenValid], async (req : Request, res : Response) => {
    console.log(" => user updating licenses")
    try{
        const userId = req.body.tokenUserId;
        const licensesUserAccepted = req.body.licenses;

        const userData = await databases.user_data.findOne({ userId : userId })
    
        if (userData === null){
            console.log("user id from token invalid")
            res.status(404).send(`user id from token invalid`);
            return;
        }

        if (userData.licenseAccepted === null || userData.licenseAccepted === undefined){
            await databases.user_data.updateOne(
                { userId: userId },
                { $set:
                   {
                        licenseAccepted : {},
                   }
                }
            )
        }
        

        const updateObject = {};
        for (const key in licensesUserAccepted) {
            
            if (Licenses[key] == licensesUserAccepted[key]){
                updateObject[`licenseAccepted.${key}`] = licensesUserAccepted[key];

            }
        }
        
        const response = await databases.user_data.updateOne(
            { userId: userId },
            { $set:
               updateObject
            }
        )

        if (response.acknowledged == true){
            console.log("updated licenses")
            return res.status(200).send("updated licenses")
        }else{
            console.log("failed to update licenses")
            return res.status(500).send("failed to update licenses")
        }




      
    }catch(err){
        reportError(err);
        return res.status(500).send("server error")
    }
})








export {
    router,
}