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
const clientVersion = "1.0.0+2";

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
const report = require("./report.js")
const adminZone = require("./adminZone")

app.use('/', limiter)
app.use('/', report.router);
app.use('/', userPosts.router);
app.use('/', userPostRating.router);
app.use('/', userAccounts.router);
app.use('/', userLogin.router);
app.use('/', adminZone.router)

app.listen(port, () => {
  console.log(`Toaster server listening on port ${port}`)
})


// REMEMBER //
//anything done such as adding ads must be updated on privacy polocy and google play console
//all content must be ok for children
//when added reporting change rating of app
//when new features are added there should be a way for it to stick with deleted accounts
//all more data collected and what not should be checked on google play console

//web fix
//camera can't save to local on web (tested atleast on computer)

// - features to add before release
//allow low res photos
//camera settings like switching camera and flash mode
//add error reporting for why camera failed
//fix taking picture on website
//add password autofill
//make images that are more horonal work and not have errors, (crop work with more width as well instead of just more height)
//test caching is working on the website
//make lazy loading lib collect data not when drawing item
//display if you have or haven't rated a toast before clicking on it
//display ratings on your profile, either with posts or another tab
//add reasons for why posts were reported
//add cache for user profiles
//block users
//settings popups broken
//https://stackoverflow.com/questions/76527143/how-to-make-my-flutter-up-and-running-after-a-flutter-upgrade
//no way to go back on pages for web 
//admin delete posts and comments
//block swearing
//add rules for swearing
//test if email is valid
//make reset password more clear how it works.
//stop tokens randomly clearing themselves.

// - security to add
//hash reset password codes
//captcha for logins
//captcha for create accounts
//-server side
//block proxy's and vpns
//smarter rate limits
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
//can delete any posts as if they own the post
//have a custom flair on their name to show they are an admin
//make a function for testing if user is admin to make easier

// - bugs to fix
//for some reason somtimes username in profile page doesn't change correctly when chaning login
//loading screen after take photo and upload photo
//delete old photos not needed when taking picture
//fix up login timeouts formula
//dark mode popups
//if connection closes mid data send it will crash the whole app
//restart app when tokens go invalid
//on token error test token and restart app
//for popups like change bio, it should only remove menu after it succses instead of after failure to.
//web verison should say when using device wider then tall and say not to use on desktop

// - possible future features after release
//sign up other people incentive, like toaster premium, then tests if ip address or account has already been used for a code.
//clean up cache and make it much smarter, for instense split it up into different parts.
//add password autofill
//custom thing for users that allows you to click on them, should be custom libary, used for comments and posts
//redo system for chaning username and bio
// //custom page
// //auto puts in what currently is in use so typos can easily be fixed
// //doesn't delete everything after error
//way to delete account
//split popups into its own curom file and reuse that for ease of reading and creating code
//have toaster server dockerised
//notifcation when someone logins into your account
//update rating data only for posts
//system for when down for maintenance
//auto remove posts after alot of reports
//back buttons to all menus
//make it more clear that rating is clickable
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
//indexing posts so to be faster
//chat system
// //pair up with random people and anonymously chat, if like can add as friends.
//search menu
//nicer failed getting posts
//extra camera settings
// //add setting for not using flashlight
// //zoom for camera
//way to suggest features
//app that reports errors to server
// //ask for users consent before and add to privacy polocy and google app settings
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
//lazy loading pass revestion for post so can know if to update post data

// - low resolstion bugs
//overflow on public or private post part
//overflow on login screen
//overflow on username in profile
//overflow of username in rating


// - plugins to use
//use image_cropper for user avatars
//use https://stackoverflow.com/questions/45031499/how-to-get-unique-device-id-in-flutter for doing device id
