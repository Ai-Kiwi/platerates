
import express from 'express';
const router = express.Router();
import { databases } from './database';
import { generateRandomString } from './utilFunctions';
import { testUserAdmin } from './adminZone';
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { error } from 'console';
import { sendNotification } from './notificationSystem';
import { confirmActiveAccount, confirmTokenValid } from './securityUtils';
import { reportError } from './errorHandler';


async function updatePostRating(rootItem : {data : string, type : string}){
  try{  
    const ratings = await databases.post_ratings.find({ "rootItem.data" : rootItem.data, "rootItem.type" : rootItem.type }).toArray();

    var newRating : number = 0;

    for (var i = 0; i < ratings.length; i++) {
      newRating += ratings[i].rating;
    }

    if (ratings.length != 0) {
      newRating = newRating / ratings.length;
    }

    const response = await databases.posts.updateOne({postId : rootItem.data},{ $set: {rating : newRating}})

    //update user rating
    const perentPostInfo = await databases.posts.findOne({postId : rootItem.data})
    if (perentPostInfo !== null) {
      const userId : string = perentPostInfo.posterUserId;

      const userPosts = await databases.posts.find({ posterUserId : userId }).toArray();

      var userAvgRating : number = 0;

      for (var i = 0; i < userPosts.length; i++) {
        userAvgRating += userPosts[i].rating;
      }

      if (userPosts.length != 0) {
        userAvgRating = userAvgRating / userPosts.length;
      }
      const userDataResponse = await databases.user_data.updateOne({userId : userId},{ $set: {averagePostRating : userAvgRating}})
    }


    if (response.acknowledged === true) {
      return true;
    }else{
      return false;
    }
  }catch(err){
    return false;
  }
}



router.post('/post/rating/delete', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching rating data")
    try{
      //const parentItem = req.body.parentItem; ------not yet added
      const ratingId = req.body.ratingId;
      const userId : string = req.body.tokenUserId;
  
      //fetch the post
      const ratingData = await databases.post_ratings.findOne({ ratingId :  ratingId})
      if (ratingData == null) {
        console.log("no post found");
        return res.status(404).send("no post found");
      }

      //test if comment is your's
      if (ratingData.ratingPosterId != userId && await testUserAdmin(userId) === false){
        console.log("post not yours");
        return res.status(403).send("post not yours");
      }

      const reponse = await databases.post_ratings.deleteOne({ratingId : ratingId})
      if (reponse.acknowledged === true){
        console.log("post deleted")
        updatePostRating(ratingData.rootItem);
        return res.status(200).send("post deleted");

      }else{
        console.log("failed to delete post");
        return res.status(500).send("failed to delete post");

      }
        
    }catch(err){
      reportError(err);
      return res.status(500).send("server error");
    }
})



router.post('/post/rating/data', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching rating data")
    try{
      //const parentItem = req.body.parentItem; ------not yet added
      const ratingId = req.body.ratingId;
      const shareMode = req.body.shareMode;
      const onlyUpdateChangeable = req.body.onlyUpdateChangeable;
      const userId : string = req.body.tokenUserId;
    
      //fetch the post
      const ratingData = await databases.post_ratings.findOne({ ratingId :  ratingId})
      if (ratingData == null) {
        console.log("failed to find post");
        return res.status(404).send("no post found");
      
      }

      //not needed, doesn't matter if root item is valid or not for getting rating data
      //const rootItem = ratingData.rootItem;
      //
      ////extract root item info
      //if (!rootItem) {
      //  console.log("no root item attached");
      //  return res.status(400).send("no root item");
      //}
      //let rootItemData;
      //if (rootItem.type === "post"){
      //  rootItemData = await databases.posts.findOne({ postId : rootItem.data })
      //}else if (rootItem.type === "rating"){
      //  rootItemData = await databases.post_ratings.findOne({ ratingId : rootItem.data })
      //}
      //if (!rootItemData){
      //  console.log("root item is invalid");
      //  return res.status(400).send("invalid root post");
      //}

      const childRatings = await databases.post_ratings.countDocuments({ "rootItem.data" : ratingId, "rootItem.type" : "rating" });
      const ratingLikes = await databases.post_rating_likes.countDocuments({ "ratingId" : ratingId, });

      let userLikeItem = await databases.post_rating_likes.findOne({ ratingId : ratingId, liker : userId})
      let userLiked = true;
      if (userLikeItem === null){
        userLiked = false;
      }

      console.log("response sent")
      if (onlyUpdateChangeable === true) {
        return res.status(200).json({
          childRatingsAmount: childRatings,
          ratingLikes : ratingLikes,
          relativeViewerData : {
            userLiked : userLiked,
          },
        });
      }
      return res.status(200).json({
        rating : ratingData.rating,
        text : ratingData.text,
        ratingPosterId : ratingData.ratingPosterId,
        rootItem: ratingData.rootItem,
        childRatingsAmount: childRatings,
        ratingLikes : ratingLikes,
        relativeViewerData : {
          userLiked : userLiked,
        },
      });

    }catch(err){
      reportError(err);
      return res.status(500).send("server error");
    }
})




router.post('/post/rating/like', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user liking/unliking post")
  try{
    const tryingToLike = req.body.liking;
    const ratingId = req.body.ratingId;
    const userId : string | undefined = req.body.tokenUserId;
  
    let ratingData = await databases.post_ratings.findOne({ratingId : ratingId});
    if (ratingData === null){
      console.log("not valid rating")
      return res.status(404).send("not valid rating");
    }

    
    //make sure not trying to follow themselfs
    if (userId === ratingData.ratingPosterId){
      console.log("can't like your own rating")
      return res.status(409).send("can't like your own rating");
    }

    //add part to make sure user exists


    //look if already following
    let userFollowItem = await databases.post_rating_likes.findOne({ ratingId : ratingId, liker : userId})
    let alreadyLiked = false;
    if (userFollowItem !== null) {
      alreadyLiked = true;
    }

    //if you are trying to follow them or unfollow them
    if (tryingToLike == true){

      if (alreadyLiked === true){
        console.log("already liked")
        return res.status(409).send("already liked");
      }else{
        const response = await databases.post_rating_likes.insertOne({ ratingId : ratingId, liker : userId})
        if (response.acknowledged === true){
          console.log("liked rating");
          return res.status(200).send("liked rating")
        }else{
          console.log("failed to create item in database");
          return res.status(500).send("server error")
        }
      }


    }else{
      if (alreadyLiked === true){
        const response = await databases.post_rating_likes.deleteOne({ ratingId : ratingId, liker : userId})
        if (response.acknowledged === true){
          console.log("removed like");
          return res.status(200).send("removed like")
        }else{
          console.log("failed to create item in database");
          return res.status(500).send("server error")
        }
      }else{
        console.log("already not liked")
        return res.status(409).send("already not liked");
      }
    }

  }catch(err){
    reportError(err);
    return res.status(500).send("server error")
  }
})



router.post('/post/rating/upload', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching post ratings")
    try{
      //const parentItem = req.body.parentItem; ------not yet added
      const rootItem = req.body.rootItem;
      const rating = req.body.rating;
      const text = req.body.text;
      const shareMode = req.body.shareMode;

      const userId : string = req.body.tokenUserId;
    
      //extract root item info
      if (!rootItem) {
        console.log("no root item");
        return res.status(400).send("no root item");
      }


      if (!text) {
        console.log("had no text attached")
        return res.status(400).send("no text provided");
      }
      if (text.length > 500) {
        console.log("text was to large")
        return res.status(400).send("text to large");
      }

      //upload id
      let ratingId : string;
      while (true){
        ratingId = generateRandomString(16);
      
        let ratingIdInUse = await databases.post_ratings.findOne({ratingId: ratingId});
        if (ratingIdInUse === null){
          break
        }
      }

      //report error if shareMode is nothing
      if (!shareMode) {
        console.log("had no share mode");
        return res.status(400).send("share mode can't be nothing");
      }


      if (rootItem.type === "post"){
        console.log("root is post");
        const rootItemData = await databases.posts.findOne({ postId : rootItem.data })
        if (!rootItemData){
          console.log("invalid root item");
          return res.status(400).send("invalid root post");
        }

        //test if they have already commented
        const alreadyExistComment = await databases.post_ratings.findOne({ ratingPosterId :  userId, rootItem : {type: rootItem.type, data: rootItem.data},})
        if (alreadyExistComment) {
          console.log("you have already rated");
          return res.status(400).send("you have already rated");
        }

        if (rootItemData.posterUserId === userId) {
          console.log("you can't rate on your own post");
          return res.status(400).send("you can not rate your own post");
        }

        //test that text and rating values are correct
        if (rating === null || rating === undefined) {
          console.log("had no rating");
          return res.status(400).send("no rating provided");
        }
        if (rating < 0 || rating > 5) {
          console.log("had out of range rating")
          return res.status(400).send("invalid rating");
        }

        sendNotification({
          receiverId : rootItemData.posterUserId,
          userId : userId,
          itemId : ratingId,
          action : "user_rated_post"
        });

        const postResponse = await databases.post_ratings.insertOne({
          rootItem : {"type": rootItem.type, "data": rootItem.data},
          ratingId: ratingId,
          text: text,
          creationDate: Date.now(),
          ratingPosterId: userId,
          rating: rating,
          shareMode: shareMode,

        })

        if (postResponse.acknowledged === true) {
          updatePostRating(rootItem);
          console.log("rating uploaded");
          return res.status(201).send("rating uploaded");

        }else{
          console.log("failed uploading rating");
          return res.status(500).send("failed uploading rating");

        }


      }else if (rootItem.type === "rating"){
        console.log("root is rating");
        const rootItemData = await databases.post_ratings.findOne({ ratingId : rootItem.data })
        if (!rootItemData){
          console.log("invalid root item");
          return res.status(400).send("invalid root post");
        }

        sendNotification({
          receiverId : rootItemData.ratingPosterId,
          userId : userId,
          itemId : ratingId,
          action : "user_reply_post_rating"
        });

        const postResponse = await databases.post_ratings.insertOne({
          rootItem : {"type": rootItem.type, "data": rootItem.data},
          ratingId: ratingId,
          text: text,
          creationDate: Date.now(),
          ratingPosterId: userId,
          shareMode: shareMode,
        })

        if (postResponse.acknowledged === true) {
          updatePostRating(rootItem);
          console.log("rating uploaded");
          return res.status(201).send("rating uploaded");

        }else{
          console.log("failed uploading rating");
          return res.status(500).send("failed uploading rating");

        }



      }else{
        console.log("invalid root item");
        return res.status(400).send("invalid root post");
      }

    }catch(err){
      reportError(err);
      return res.status(500).send("server error");
    }
})



router.post('/post/ratings', [confirmTokenValid, confirmActiveAccount], async (req : Request, res : Response) => {
  console.log(" => user fetching post ratings")
    try{
      //const parentItem = req.body.parentItem; ------not yet added
      const rootItem = req.body.rootItem;
      const startPosPost = req.body.startPosPost;
      var startPosPostDate = 100000000000000
      const userId : string = req.body.tokenUserId;
    
      //extract start item data
      if (startPosPost) {
        if (startPosPost.type === "rating" && !startPosPost.data){
          console.log("invalid start item")
          return res.status(400).send("invalid start item");
        }

        const startPosPostData = await databases.post_ratings.findOne({ ratingId: startPosPost.data, rootItem : rootItem })
        if (!startPosPostData){
          console.log("invalid start item")
          return res.status(400).send("invalid start item");
        }
          
        startPosPostDate = startPosPostData.creationDate;
      }

      //extract root item info
      if (!rootItem) {
        console.log("no root item");
        return res.status(400).send("no root item");
      }

      let rootItemData;
      if (rootItem.type === "post") {
        rootItemData = await databases.posts.findOne({ postId : rootItem.data })
      }else if (rootItem.type === "rating") {
        rootItemData = await databases.post_ratings.findOne({ ratingId : rootItem.data })
      }else{
        console.log("unknown root item type");
        return res.status(400).send("unknown root item type");
      }

      if (!rootItemData){
        console.log("invalid root item");
        return res.status(400).send("invalid root post");
      }
      const dataReturning = await databases.post_ratings.find({ creationDate: { $lt: startPosPostDate}, "rootItem.data" : rootItem.data, "rootItem.type" : rootItem.type }).sort({creationDate: -1}).limit(5).toArray();
      let returnData = {
        "items": [] as { type: string; data: string;}[]
      }
  
      if (dataReturning.length == 0) {
        console.log("nothing to fetch");
      }


      for (var i = 0; i < dataReturning.length; i++) {
        if (dataReturning[i].userId !== null) {
          returnData["items"].push({
            type : "rating",
            data : dataReturning[i].ratingId,
          });
        }
      }
      
      console.log("returning items");
      return res.status(200).json(returnData);

    }catch(err){
      reportError(err);
      return res.status(500).send("server error");
    }
})

  
export {
    router,
};