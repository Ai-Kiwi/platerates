import express, { NextFunction, Request, Response } from "express";
import { getAppCheck } from "firebase-admin/app-check";
import { testTokenValid } from "./userLogins";
import { databases } from "./database";
import { millisecondsToTime } from "./utilFunctions";

const Licenses = {
    "CommunityGuidelines" : 1,
    "deleteData" : 3,
    "privacyPolicy" : 3,
    "termsofService" : 1,
} 

const appCheckVerification = async (req : Request, res : Response, next : NextFunction) => {
    const appCheckToken = req.header("X-Firebase-AppCheck");

    if (!appCheckToken) {
        res.status(401);
        return res.send("Unauthorized");
    }

    try {
        const appCheckClaims = await getAppCheck().verifyToken(appCheckToken);

        // If verifyToken() succeeds, continue with the next middleware
        // function in the stack.
        return next();
    } catch (err) {
        res.status(401);
        return res.send("Unauthorized");
    }
}


async function confirmTokenValid(req : Request, res : Response, next : NextFunction) {
    //console.log("testing token before function")
    const userToken = req.body.token;
    const userIpAddress : string = req.headers['x-forwarded-for'] as string;

    if (!userToken) {
        console.log("invalid token");
        res.status(401).send("invalid token");
        
    }else{
        const result = await testTokenValid(userToken,userIpAddress);
        const vaildToken : boolean = result.valid;
        const userId : string | undefined = result.userId;
        
        if (vaildToken === true){
            req.body.tokenUserId = userId;
            next();

        }else{
            console.log("invalid token");
            res.status(401).send("invalid token");
        }
    }

}

async function confirmActiveAccount(req : Request, res : Response, next : NextFunction) {
    //console.log("testing active account before function")
    const userId = req.body.tokenUserId;

    const userData = await databases.user_data.findOne({ userId : userId })
    const userDataCredentials = await databases.user_credentials.findOne({ userId : userId })

    if (userData == null || userDataCredentials == null){
        console.log("user id from token invalid")
        res.status(404).send(`user id from token invalid`);
        return;
    }

    //test if account is banned
    if (userDataCredentials.accountBanExpiryDate > Date.now()){
        console.log("account is banned")
        res.status(403).send(`account banned`);
        return;
        //return res.status(403).send(`account banned for ${ millisecondsToTime( userData.accountBanExpiryDate - Date.now() ) }\nReason: ${userData.accountBanReason}`);
    }

    //test if any lisesnes have been accepted
    if (userData.licenseAccepted === null || userData.licenseAccepted === undefined){
        console.log("user must agree to licenses")
        res.status(400).send(`not accepted licenses`);
        return;
    }

    for (const key in Licenses) {
        if (Licenses[key] != userData.licenseAccepted[key]){
            console.log("user must agree to a licenses")
            res.status(400).send(`not accepted licenses`);
            return;
        }
        //const value = Licenses[key];
        //console.log(`Key: ${key}, Value: ${value}`);
    }


    next()
    
}



//expressApp.get("/yourApiEndpoint", [appCheckVerification], (req, res) => {
//    // Handle request.
//});

export {
    appCheckVerification,
    confirmTokenValid,
    confirmActiveAccount,
    Licenses
}