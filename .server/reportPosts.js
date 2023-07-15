const express = require('express');
const router = express.Router();
const { database } = require('./database');
const { testToken } = require('./userLogin');
const { generateRandomString } = require('./utilFunctions');
const { versions } = require('sharp');



router.post('/report', async (req, res) => {
  console.log(" => user fetching profile")
  try{
    const token = req.body.token;
    const userId = req.body.userId;
    [validToken, requesterUserId] = await testToken(token,req.headers['x-forwarded-for']);
    const collection = database.collection('user_data');

    if (validToken === false){

    
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

module.exports = {
    router:router,
};