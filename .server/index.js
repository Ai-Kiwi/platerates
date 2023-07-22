const express = require('express')
var bodyParser = require('body-parser');
const { banAccount, createUser } = require('./userAccounts');
const { rateLimit } = require('express-rate-limit');
const userPostRatings = require('./userPostRating');

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
const clientVersion = "1.0.0+1";

//setup app
const app = express()
app.use(bodyParser.json({ limit: '2mb' }))       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
    extended: true
})); 


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
const report = require("./report.js")

app.use('/', limiter)
app.use('/', report.router);
app.use('/', userPosts.router);
app.use('/', userPostRating.router);
app.use('/', userAccounts.router);
app.use('/', userLogin.router);


// GET method route
app.get('/', (req, res) => {
  res.send(`nothing of value here`);
})

app.listen(port, () => {
  console.log(`Toaster server listening on port ${port}`)
})


// REMEMBER //
//anything done such as adding ads must be updated on privacy polocy and google play console
//all content must be ok for children
//when added reporting change rating of app
//when new features are added there should be a way for it to stick with deleted accounts
//all more data collected and what not should be checked on google play console

// - features to add before release
//add in app links to privacy policy 
//privacy policy
//make lazy loading lib collect data not when drawing item
//display if you have or haven't rated a toast before clicking on it
//display ratings on your profile, either with posts or another tab
//add reasons for why posts were reported
//admin zone todo things
//add cache for user profiles
//block users


// - security to add
//hash reset password codes
//captcha for logins
//captcha for create accounts
//-server side
//block proxy's and vpns
//-client side
//root detection etc, bans after login
//certificate pinning
//bans based on device fingerprint
// //login to another device with fingerprint will ban that account as well
// //login with same ip address within a few days of ban will ban that account as well
//add device fingerprint info to token
//login history
//late loading librarys
//api key that app uses
//per account rate limit, strictness depends of account account trust level
//verify with phone number possibly
//have to do email verify if different ip address or device
//add https://github.com/marketplace/actions/flutter-action

//admin page
//view reports
//view bans, ban user
//create account
//can delete any posts as if they own the post
//have a custom flair on their name to show they are an admin

// - bugs to fix
//loading screen after take photo and upload photo
//delete old photos not needed when taking picture
//fix up login timeouts formula
//dark mode popups
//if connection closes mid data send it will crash the whole app
//after deleting post scrolling down then back up glitchs you back down repeartivly
//clean up http status codes to be nicer
//http error responses
//naming system for mongodb
//on token error test token and restart app


//cache overhall
//ratings get removed from cache after restart and every now and again
//cache has expirey date
//cache is all cleard once a week or so

// - possible future features after release
//add password autofill
//custom thing for users that allows you to click on them, should be custom libary, used for comments and posts
//redo system for chaning username and bio
// //custom page
// //auto puts in what currently is in use so typos can easily be fixed
//way to delete account
//split popups into its own curom file and reuse that for ease of reading and creating code
//changelog
//create another branch for relase verison of toaster
//have toaster server dockerised
//notifcation when someone logins into your account
//update rating data only for posts
//system for when down for maintenance
//auto remove posts after alot of reports
//back buttons to all menus
//make it more clear that rating is clickable
//spam requests from account leads to account ban
//add option to use token forever
//look at changing token expire time
//change email address
//way to delete all user data
//ahead of time post downloading
//non picture related posts
//creating accounts
// //captcha
// //rate limit for making accounts
//adding as friend
//indexing posts to be faster
//chat system
//search menu
//nicer failed getting posts
//extra camera settings
// //add setting for not using flashlight
// //zoom for camera
//way to suggest features
//toaster leaderboards
//toaster streaks
//improve server error reporting
//sign in with google
//shareing toasts
// //toaster watermark
//how long ago post was uploaded
//able to click on user profile avatar and name to open them on posts
//block users
//private stuff
// //private accounts
// //private posts
//backup database
//look at better way to store images
//word censoring
//rate limiting per account basses
//paid verison that bypass rate limit
//lazy loading pass revestion for post so can know if to update post data
//random pair up with people to chay

// - low resolstion
//overflow on public or private post part
//overflow on login screen
//overflow on username in profile
//overflow of username in rating


// - plugins to use
//use image_cropper for user avatars
//use https://stackoverflow.com/questions/45031499/how-to-get-unique-device-id-in-flutter for doing device id
