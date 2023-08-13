const express = require('express');
const router = express.Router();
const { database } = require('./database');
const { testToken } = require('./userLogin');




router.post('/search/users', async (req, res) => {
    console.log(" => user searching")
      try{
        const searchText = req.body.searchText;
        const token = req.body.token;
        const startPosPost = req.body.startPosPost;
        var startPosInfo = 100000000000000
        var vaildToken, userId;
    
        [vaildToken, userId] = await testToken(token,req.headers['x-forwarded-for'])
      
        if (vaildToken) { // user token is valid
          var collection = database.collection('user_data');
          var dataReturning;
    
          if (startPosPost) {
            if (startPosPost.type === "user" && !startPosPost.data){
              console.log("invaild start user")
              return res.status(400).send("invaild start user");
            }
  
            const startPosPostData = await collection.findOne({ userId: startPosPost.data })
            if (!startPosPostData){
              console.log("invaild start user")
              return res.status(400).send("invaild start user");
            }
              
            startPosInfo = startPosPostData.creationDate;
          }
    
          dataReturning = await collection.find({ shareMode: 'public', creationDate: { $lt: startPosInfo}}).sort({creationDate: -1}).limit(5).toArray();
          var returnData = {}
          returnData["items"] = []
     
          if (dataReturning.length == 0) {
            console.log("nothing to fetch");
          }
    
          for (var i = 0; i < dataReturning.length; i++) {
            returnData["items"].push({
              type : "user",
              data : dataReturning[i].userId,
              username : dataReturning[i].username,
            });
            //Do something
          }
          
          console.log("returning users");
          return res.status(200).json(returnData);
    
        }else{
          console.log("invaild token");
          return res.status(401).send("invaild token");
        }
      }catch(err){
        console.log(err);
        return res.status(500).send("server error");
      }
  })
  
  
  
  module.exports = {
      router:router,
  };