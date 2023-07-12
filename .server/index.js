const express = require('express')
var bodyParser = require('body-parser');
const { banAccount } = require('./userAccounts');
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


const app = express()
app.use(bodyParser.json({ limit: '2mb' }))       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
    extended: true
})); 

userPosts = require("./userPosts");
userAccounts = require("./userAccounts");
userLogin = require("./userLogin");
userPostRating = require("./userPostRating");

app.use('/', limiter)
app.use('/', userPosts.router);
app.use('/', userPostRating.router);
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
//finish reset password
//report feature
//lisences
// //use AboutDialog to get lisences from packages
// //privacy policy
//profile pictures to post and ratings
//make lazy loading lib collect data not when drawing item
//back buttons to all menus
//post limit
// //post timeout
// //rate timeout
// //reset password
// //create account
//add returning to everything for post ratings in console print
//add user avatar
//display if you have or haven't rated a toast before clicking on it
//display ratings on your profile
//remove the dumb jokes I added in text feilds
//make when no posts it be cleaner
//fix up error status messages

// - security to add
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


// - possible future features after release
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
//move rating to another section & move report to 3 dots for posts
//lazy loading pass revestion for post so can know if to update post data

// - low resolstion
//overflow on public or private post part
//overflow on login screen
//overflow on username in profile
//overflow of username in rating

// - plugins to use
//use image_cropper for user avatars
//use https://stackoverflow.com/questions/45031499/how-to-get-unique-device-id-in-flutter for doing device id