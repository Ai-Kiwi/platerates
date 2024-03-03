import { Request, Response } from "express";
import express from "express";
import { rateLimit} from 'express-rate-limit';
import path from "path";
import cors from 'cors';
import bodyParser from 'body-parser';
import firebase, { database } from 'firebase-admin'

const isLocalhost = (req) => req.ip === '127.0.0.1' || req.ip === '::1';
//bench marking can be done with ->   artillery run test.yml

const limiter = rateLimit({
	windowMs: 10 * 60 * 1000, // 3 minutes
  //windowMs: 3 * 1000, // 3 seconds (bassicly disabled)
	max: 500, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
	standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
	legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: 'Too many requests, please try again later.',
  skip: (req) => isLocalhost(req), // Skip rate limiting for localhost
  keyGenerator: (req: Request) => {
    return req.headers['x-forwarded-for'] as string;
  },
})

require('dotenv').config();


const clientVersion: string = "2.0.0+1";
//make sure to update lisesnes on securityUtil file

//setup app
const app = express()
const expressWs = require('express-ws')(app);
const port: string = process.env.port || "3030";

app.use(bodyParser.json({ limit: '32mb' }))       // to support JSON-encoded bodies
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

app.get('/PlateRates.apk', async (req : Request, res : Response) => {
  console.log(" => user download app")
  try{
    return res.status(200).sendFile(__dirname + "/PlateRates.apk");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})


firebase.initializeApp({
  credential: firebase.credential.cert({
    projectId : process.env.FIREBASE_PROJECT_ID ,
    clientEmail : process.env.FIREBASE_CLIENT_EMAIL ,
    privateKey : process.env.FIREBASE_PRIVATE_KEY!.replace(/\\n/gm, "\n")
  }),
  projectId:  process.env.FIREBASE_PROJECT_ID,
});

//createUser("demouser@aikiwi.dev","xZb2VQyvgBV8#24axwVLaOHwDHzKv@az","demo user")

app.use('/', limiter)

import {router as pagesRouter} from "./pages";
app.use('/', pagesRouter)

import {router as userLoginRouter} from "./js/userLogins";
app.use('/', userLoginRouter);

import {router as licensesRouter} from "./js/licenses";
app.use('/', licensesRouter)

import {router as userPostsRouter} from "./js/userPosts";
app.use('/', userPostsRouter);

import {router as userAccountsRouter} from "./js/userAccounts";
app.use('/', userAccountsRouter);

import {router as userPostRatingRouter} from "./js/userRating";
app.use('/', userPostRatingRouter);

import {router as reportRouter} from "./js/report";
app.use('/', reportRouter);

import {router as adminZoneRouter} from "./js/adminZone";
app.use('/', adminZoneRouter);

import {router as searchSystemRouter} from "./js/searchSystem";
app.use('/', searchSystemRouter);

import {router as notificationSystem} from "./js/notificationSystem";
app.use('/', notificationSystem);

import {router as chatSystem} from "./js/chatSystem"; 
app.use('/', chatSystem);

import {GetBucket as GetBucket} from "./js/database"; 

console.log("connecting to file server...")
GetBucket().then(() => {
  app.listen(port, () => {
    console.log(`PlateRates server listening on port ${port}`)
  })
})