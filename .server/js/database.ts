require('dotenv').config();
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { error } from "console";

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

export { databases }; //add database