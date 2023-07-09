const express = require('express')
var bodyParser = require('body-parser');
const { banAccount } = require('./userAccounts');
const { rateLimit } = require('express-rate-limit');

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


const app = express()
app.use(bodyParser.json({ limit: '2mb' }))       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
    extended: true
})); 

userPosts = require("./userPosts");
userAccounts = require("./userAccounts");
userLogin = require("./userLogin");

app.use(limiter)
app.use('/', userPosts.router);
app.use('/', userAccounts.router);
app.use('/', userLogin.router);


// GET method route
app.get('/', (req, res) => {
  res.send(`nothing ${req.headers['x-forwarded-for']}`);
})

app.listen(port, () => {
  console.log(`Toaster server listening on port ${port}`)
})



// - features to add before release
//profile's
// //reset password
// //change username
// //change email
// //logout current or all devices
// //private accounts
// //delete all data
//report feature
//rating posts
//lisences
// //use AboutDialog to get lisences from packages
// //privacy policy


// - security to add
//captcha for logins
//captcha for create accounts
//-server side
//rate limiting
// //posts
// //ading frineds
//block proxy's and vpns
//-client side
//root detection etc, bans after login
//certificate pinning
//bans based on device fingerprint
//add device fingerprint info to token
//login history
//late loading librarys
//api key that app uses


// - bugs to fix
//lack of post caching, scrolling spam regets from servers
// //maybe fetch for cache ahead of time, that way when you scroll loading doesn't happen
//loading screen after take photo and upload photo
//delete old photos not needed when taking picture
//fix up login timeouts formula
//dark mode popups
//if connection closes mid data send it will crash the whole app


// - possible future features after release
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
//reached end of your feed
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

// - low resolstion
//overflow on public or private post part
//overflow on login screen
//overflow on username

// - plugins to use
//use image_cropper for user avatars
