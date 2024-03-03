require('dotenv').config();
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { error } from "console";
const B2 = require('backblaze-b2');

//https://www.npmjs.com/package/backblaze-b2

//mongodb

const { MongoClient } = require('mongodb');
const mongoDB_dataBase : string | undefined = process.env.mongoDB_dataBase;
const mongodb_url : string | undefined = process.env.mongodb_url;
if (mongoDB_dataBase === undefined || mongodb_url === undefined) {
  error("failed to fetch mongodb server settings")
}
const mongodb_client = new MongoClient(mongodb_url, {
  useNewUrlParser: true, 
  useUnifiedTopology: true, 
  serverSelectionTimeoutMS: 5000 
});
mongodb_client.connect()
const database = mongodb_client.db(mongoDB_dataBase);

const databases = {
  user_data : database.collection('user_data'),
  chat_rooms : database.collection('chat_rooms'),
  chat_messages : database.collection('chat_messages'),
  user_notifications : database.collection('user_notifications'),
  reports : database.collection('reports'),
  user_credentials : database.collection('user_credentials'),
  posts : database.collection('posts'),
  post_ratings : database.collection('post_ratings'),
  account_notices : database.collection('account_notices'),
  user_avatars : database.collection('user_avatars'),
  user_follows : database.collection('user_follows'),
  post_rating_likes : database.collection('post_rating_likes'),
  account_create_requests : database.collection('account_create_requests'),
}

//database.createCollection('account_create_requests');

//database.createCollection("post_rating_likes");
//database.dropCollection("user_rating_likes")

let b2_uploadUrl;
let b2_uploadAuthToken;

//fileStorage database
const b2 = new B2({
  applicationKeyId: process.env.BLACKBLAZE_KEYID, // or accountId: 'accountId'
  applicationKey: process.env.BLACKBLAZE_KEY, // or masterApplicationKey
});

async function GetBucket() {
  try {
    await b2.authorize(); // must authorize first (authorization lasts 24 hrs)
    let response = await b2.getBucket({ bucketName: process.env.BLACKBLAZE_BUCKET_NAME });
    let UploadUrlResponse = await b2.getUploadUrl({
      bucketId: process.env.BLACKBLAZE_BUCKETID
    })
    b2_uploadUrl = UploadUrlResponse['data']['uploadUrl']
    b2_uploadAuthToken = UploadUrlResponse['data']['authorizationToken']
    

  } catch (err) {
    console.log('Error getting bucket:', err);
    error("failed connecting to file bucket")
  }
}



export { databases, b2, GetBucket, b2_uploadUrl, b2_uploadAuthToken }; //add database