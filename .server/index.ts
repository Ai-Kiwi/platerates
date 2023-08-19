import { Request, Response } from "express";
import express from "express";
import { rateLimit} from 'express-rate-limit';
import path from "path";
import cors from 'cors';
import bodyParser from 'body-parser';

const limiter = rateLimit({
	windowMs: 3 * 60 * 1000, // 3 minutes
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
const clientVersion: string = "1.0.9+1";

//setup app
const app = express()
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

app.get("/deleteData", async (req : Request, res : Response) => {
  console.log(" => user delete data website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/deleteData.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

app.get('/privacyPolicy', async (req : Request, res : Response) => {
  console.log(" => user delete data website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/privacyPolicy.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

app.get('/changeLog', async (req : Request, res : Response) => {
  console.log(" => user delete data website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/changeLog.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})


app.get('/toaster.apk', async (req : Request, res : Response) => {
  console.log(" => user delete data website")
  try{
    return res.status(200).sendFile(__dirname + "/toaster.apk");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})





//createUser("demouser@aikiwi.dev","xZb2VQyvgBV8#24axwVLaOHwDHzKv@az","demo user")


import {router as userPostsRouter} from "./js/userPosts";
import {router as userAccountsRouter} from "./js/userAccounts";
import {router as userLoginRouter} from "./js/userLogin";
import {router as userPostRatingRouter} from "./js/userRating";
import {router as reportRouter} from "./js/report";
import {router as adminZoneRouter} from "./js/adminZone";
import {router as searchSystemRouter} from "./js/searchSystem";






app.use('/', limiter)
app.use('/', userPostsRouter);
app.use('/', userAccountsRouter);
app.use('/', userLoginRouter);
app.use('/', userPostRatingRouter);
app.use('/', reportRouter);
app.use('/', adminZoneRouter);
app.use('/', searchSystemRouter);

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
