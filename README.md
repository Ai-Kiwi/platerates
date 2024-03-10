# DON'T PUBLISH

This project should not be published and should be completely redone If i ever do decide to publish it, tokens have been leaked in here on past on accent.

# noticed files compromised
 - past mongodb admin login info  
 - firebase options file  
 - google-services.json
 - possibly email server login details

# notes to setup dev env

need to setup postgre server to use
need to serup blackblaze bucket to setup

needed .env variables (to be placed in ./.server/.env)
```
#settings for server
port = #whatever port you want I use 3030
loginKey = "login-key" #gets made and printed to console if you don't have any, used to verify user login tokenbs


# mongodb info will be replaced with switch to postgre
mongoDB_dataBase = ""
mongodb_url = ""

#can be made with firebase account
FIREBASE_PROJECT_ID=""
FIREBASE_PRIVATE_KEY=""
FIREBASE_CLIENT_EMAIL=""

# can be found when setting up blackblaze s2 bucket
BLACKBLAZE_KEYID=""
BLACKBLAZE_KEYNAME=""
BLACKBLAZE_KEY=""
BLACKBLAZE_BUCKET_NAME=""
BLACKBLAZE_BUCKETID=""

#pick whatever email host you want I use mailgun
MailHost=""
MailPort=
MailSecure=""
MailAuthUser=''
MailAuthPass=''





```