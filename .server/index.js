const express = require('express')
var bodyParser = require('body-parser');
const { banAccount } = require('./userAccounts');


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


app.use('/', userPosts.router);
app.use('/', userAccounts.router);
app.use('/', userLogin.router);


// GET method route
app.get('/', (req, res) => {
  res.send("nothing");
})

app.listen(port, () => {
  console.log(`Toaster server listening on port ${port}`)
})



// - features to add before release
//reset password
//profile's
// //reset password
// //change username
// //change email
// //logout current or all devices
// //private accounts
// //delete all data
//report feature
//adding as friend
//rating posts
//account banning, and prompt for login
// //prompt on app login
// //don't let login
// //expire all current login tokens
// //system to remember past bans, formula for ban time based on this
//lisences
// //use AboutDialog to get lisences from packages
//privacy policy
//advanced logging
// //every function should have logging
// //logging should be annymous for final release
//public release verison
// //look at better way to store images
// //make sure nginx forwards ip address informastion
// //look at if certbot could instead be on server

// - security to add
////captcha for alota logins
//-server side
//rate limiting
// //posts
// //searching for things
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
//postion of text to take picture for post
//spam asks for new things when at end of feed
// //applies to both profile and feed, however only profile has log messages for it
//if connection closes mid data send it will crash the whole app

// - possible future features after release
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

// - low resolstion
//overflow on public or private post part
//overflow on login screen

// - plugins to use
//use image_cropper for user avatars
