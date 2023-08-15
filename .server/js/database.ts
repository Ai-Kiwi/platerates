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

export { database };