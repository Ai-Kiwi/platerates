import express, { Request, Response } from 'express';
const router = express.Router();

router.get("/deleteData", async (req : Request, res : Response) => {
  console.log(" => user delete data website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/deleteData.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

router.get('/privacyPolicy', async (req : Request, res : Response) => {
  console.log(" => user delete data website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/privacyPolicy.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

router.get('/changeLog', async (req : Request, res : Response) => {
  console.log(" => user changelog website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/changeLog.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

router.get('/CommunityGuidelines', async (req : Request, res : Response) => {
  console.log(" => user changelog website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/CommunityGuidelines.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

router.get('/termsOfService', async (req : Request, res : Response) => {
  console.log(" => user changelog website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/termsOfService.html");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

router.get('/styles.css', async (req : Request, res : Response) => {
  console.log(" => user changelog website")
  try{
    return res.status(200).sendFile(__dirname + "/pages/styles.css");
  }catch(err){
    console.log(err);
    return res.status(500).send("server error")
  }
})

export {
    router
}