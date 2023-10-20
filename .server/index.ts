import { Request, Response } from "express";
import express from "express";
import { rateLimit} from 'express-rate-limit';
import path from "path";
import cors from 'cors';
import bodyParser from 'body-parser';
import firebase from 'firebase-admin'

const limiter = rateLimit({
	//windowMs: 3 * 60 * 1000, // 3 minutes
  windowMs: 3 * 1000, // 3 seconds (bassicly disabled)
	max: 100, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
	standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
	legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: 'Too many requests, please try again later.',
  keyGenerator: (req: Request) => {
    return req.headers['x-forwarded-for'] as string;
  },
})

require('dotenv').config();

const port: string = process.env.port || "3030";
const clientVersion: string = "1.1.0+3";

//setup app
const app = express()
const expressWs = require('express-ws')(app);

app.use(bodyParser.json({ limit: '2mb' }))       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
    extended: true
})); 

// Enable CORS for all routes
app.use(cors());

app.use(express.static(path.join(__dirname, 'web/')))


//post for latest verison
app.post("/latestVersion", async (req : Request, res : Response) => {
  console.log(" => user fetching profile")
  try{
    return res.status(200).send(clientVersion)
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

app.get('/toaster.apk', async (req : Request, res : Response) => {
  console.log(" => user download app")
  try{
    return res.status(200).sendFile(__dirname + "/toaster.apk");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})


//add to .env following this guide : https://dev.to/wilsonparson/how-to-securely-use-google-apis-service-account-credentials-in-a-public-repo-4k65
firebase.initializeApp({
  credential: firebase.credential.cert({
    projectId : process.env.FIREBASE_PROJECT_ID ,
    clientEmail : process.env.FIREBASE_CLIENT_EMAIL ,
    privateKey : process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/gm, "\n")
  }),
  projectId:  process.env.FIREBASE_PROJECT_ID,
});

//createUser("demouser@aikiwi.dev","xZb2VQyvgBV8#24axwVLaOHwDHzKv@az","demo user")

import {router as pagesRouter} from "./pages";
import {router as userPostsRouter} from "./js/userPosts";
import {router as userAccountsRouter} from "./js/userAccounts";
import {router as userLoginRouter} from "./js/userLogin";
import {router as userPostRatingRouter} from "./js/userRating";
import {router as reportRouter} from "./js/report";
import {router as adminZoneRouter} from "./js/adminZone";
import {router as searchSystemRouter} from "./js/searchSystem";
import {router as notificationSystem} from "./js/notificationSystem";
import {router as chatSystem} from "./js/chatSystem"; 


app.use('/', pagesRouter)
app.use('/', limiter)
app.use('/', userPostsRouter);
app.use('/', userAccountsRouter);
app.use('/', userLoginRouter);
app.use('/', userPostRatingRouter);
app.use('/', reportRouter);
app.use('/', adminZoneRouter);
app.use('/', searchSystemRouter);
app.use('/', notificationSystem);
app.use('/', chatSystem);


app.listen(port, () => {
  console.log(`Toaster server listening on port ${port}`)
})


// REMEMBER //
//anything done such as adding ads must be updated on privacy polocy and google play console
//all content must be ok for children
//when added reporting change rating of app
//when new features are added there should be a way for it to stick with deleted accounts
//all more data collected and what not should be checked on google play console


// - plugins to use
//use image_cropper for user avatars
//use https://stackoverflow.com/questions/45031499/how-to-get-unique-device-id-in-flutter for doing device id
