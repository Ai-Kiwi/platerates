import express from 'express';
const router = express.Router();
import { databases } from './database';
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { confirmActiveAccount, confirmTokenValid } from './securityUtils';



router.post('/search/users', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
    console.log(" => user searching")
      try{
        const searchText = req.body.searchText;
        const startPosPost = req.body.startPosPost;
        let startPosInfo: number = 100000000000000
        const userId : string | undefined = req.body.tokenUserId;
      
        if (startPosPost) {
          if (startPosPost.type === "user" && !startPosPost.data){
            console.log("invalid start user")
            return res.status(400).send("invalid start user");
          }

          const startPosPostData = await databases.user_data.findOne({ userId: startPosPost.data })
          if (startPosPostData === null){
            console.log("invalid start user")
            return res.status(400).send("invalid start user");
          }
            
          startPosInfo = startPosPostData.creationDate;
        }
  
        const dataReturning = await databases.user_data.find({ creationDate: { $lt: startPosInfo}}).sort({creationDate : -1}).limit(15).toArray();
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
      }catch(err){
        console.log(err);
        return res.status(500).send("server error");
      }
  })
  
  
  
export {
  router,
};