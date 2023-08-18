import express from 'express';
const router = express.Router();
import { database } from './database';
import { testToken } from './userLogin';
import mongoDB from "mongodb";
import { Request, Response } from "express";



router.post('/search/users', async (req, res) => {
    console.log(" => user searching")
      try{
        const searchText = req.body.searchText;
        const token = req.body.token;
        const startPosPost = req.body.startPosPost;
        let startPosInfo: number = 100000000000000

        const userIpAddress : string = req.headers['x-forwarded-for'] as string;

        const result = await testToken(token,userIpAddress);
        const validToken : boolean = result.valid;
        const userId : string | undefined = result.userId;
      
        if (validToken) { // user token is valid
          let collection: mongoDB.Collection = database.collection('user_data');
    
          if (startPosPost) {
            if (startPosPost.type === "user" && !startPosPost.data){
              console.log("invaild start user")
              return res.status(400).send("invaild start user");
            }
  
            const startPosPostData = await collection.findOne({ userId: startPosPost.data })
            if (startPosPostData === null){
              console.log("invaild start user")
              return res.status(400).send("invaild start user");
            }
              
            startPosInfo = startPosPostData.creationDate;
          }
    
          const dataReturning = await collection.find({ shareMode: 'public', creationDate: { $lt: startPosInfo}}).sort({averagePostRating : -1}).limit(15).toArray();
          let returnData = {
            "items": [] as { type: string; data: string;}[]
          }
     
          if (dataReturning.length == 0) {
            console.log("nothing to fetch");
          }


          for (var i = 0; i < dataReturning.length; i++) {
            if (dataReturning[i].userId !== null) {
              returnData["items"].push({
                type : "user",
                data : dataReturning[i].userId,
              });
            }
          }
          
          console.log("returning users");
          return res.status(200).json(returnData);
    
        }else{
          console.log("invalid token");
          return res.status(401).send("invalid token");
        }
      }catch(err){
        console.log(err);
        return res.status(500).send("server error");
      }
  })
  
  
  
export {
  router,
};