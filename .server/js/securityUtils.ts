import express, { NextFunction, Request, Response } from "express";
import { getAppCheck } from "firebase-admin/app-check";
import { testTokenValid } from "./userLogins";

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



//expressApp.get("/yourApiEndpoint", [appCheckVerification], (req, res) => {
//    // Handle request.
//});

export {
    appCheckVerification,
    confirmTokenValid
}