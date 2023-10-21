import express, { NextFunction, Request, Response } from "express";
import { getAppCheck } from "firebase-admin/app-check";

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

//expressApp.get("/yourApiEndpoint", [appCheckVerification], (req, res) => {
//    // Handle request.
//});

export {
    appCheckVerification
}