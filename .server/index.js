const express = require('express')
var bodyParser = require('body-parser')


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
// //show past posts
// // //delete old posts
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
//indexing posts to be faster
//lisences
// //use AboutDialog to get lisences from packages
//privacy polocy
//post management 
// //3 dot button if it's your post
// // //delete post
//advanced logging
// //every function should have logging
// //logging should be annymous for final release

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
//device fingerprint to token
//login history
//late loading librarys
//api key that app uses


// - bugs to fix
//lack of post caching, scrolling spam regets from servers
// //maybe fetch for cache ahead of time, that way when you scroll loading doesn't happen
//add error checking for post item being added to documents in mongodb
//loading screen after take photo and upload photo
//delete old photos not needed when taking picture
//fix up login timeouts formula
//dark mode popups
//postion of take picture
//spam asks for new things when at end of feed
// //applies to both profile and feed, however only profile has log messages for it
//if connection closes mid data send it will crash the whole app

// - possible future features after release
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

// - low resolstion
//overflow on public or private post part
//overflow on login screen

// - plugins to use
//use image_cropper for user avatars
