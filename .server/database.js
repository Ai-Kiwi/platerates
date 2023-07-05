require('dotenv').config();

const { MongoClient } = require('mongodb');
const mongoDB_dataBase = process.env.mongoDB_dataBase;
const mongodb_url = process.env.mongodb_url;
const mongodb_client = new MongoClient(mongodb_url, {
  useNewUrlParser: true, 
  useUnifiedTopology: true, 
  serverSelectionTimeoutMS: 5000 
});
mongodb_client.connect()
const database = mongodb_client.db(mongoDB_dataBase);

module.exports = { database };