const express = require('express')
var bodyParser = require('body-parser');
const { banAccount, createUser } = require('./userAccounts');
const { rateLimit } = require('express-rate-limit');
const userPostRatings = require('./userPostRating');
const path = require("path")
const cors = require('cors');

const limiter = rateLimit({
	windowMs: 3 * 60 * 1000, // 3 minutes
	max: 100, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
	standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
	legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: 'Too many requests, please try again later.',
  keyGenerator: (req) => {
    return req.headers['x-forwarded-for'];
  },
})

require('dotenv').config();

const port = process.env.port;
const clientVersion = "1.0.4+1";

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
app.post("/latestVersion", async (req, res) => {
  console.log(" => user fetching profile")
  try{
    return res.status(200).send(clientVersion)
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

app.get("/deleteData", async (req, res) => {
  console.log(" => user delete data website")
  try{
    return res.status(200).sendFile(__dirname + "/deleteData.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

app.get('/privacyPolicy', async (req, res) => {
  console.log(" => user delete data website")
  try{
    return res.status(200).sendFile(__dirname + "/privacyPolicy.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})



//createUser("demouser@aikiwi.dev","xZb2VQyvgBV8#24axwVLaOHwDHzKv@az","demo user")


const userPosts = require("./userPosts");
const userAccounts = require("./userAccounts");
const userLogin = require("./userLogin");
const userPostRating = require("./userPostRating");
const report = require("./report.js");
const adminZone = require("./adminZone");
const search = require("./searchSystem");

app.use('/', limiter)
app.use('/', report.router);
app.use('/', userPosts.router);
app.use('/', userPostRating.router);
app.use('/', userAccounts.router);
app.use('/', userLogin.router);
app.use('/', adminZone.router);
app.use('/', search.router);

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
