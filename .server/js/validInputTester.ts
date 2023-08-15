import { database } from './database';
import mongoDB from "mongodb";
import { Request, Response } from "express";

async function testUsername(username : string){
  try{
    const allowedCharsPattern = /^[a-zA-Z0-9_.-]+$/;
    //spaces as well /[a-zA-Z0-9_.-]./;

    const allowed = allowedCharsPattern.test(username)

    if (allowed !== true) {
      return {
        valid: false,
        reason : "not allowed chars"
      };
    }

    if (username.length > 25) {
      return {
        valid: false,
        reason : "username to large"
      };
    }

    if (username.length < 3) {
      return {
        valid: false,
        reason : "username to small"
      };
    }

    const collection: mongoDB.Collection = database.collection('user_data');

    const usernameInUse = await collection.findOne({username : username})

    if (usernameInUse !== null) {
      return {
        valid: false,
        reason : "username already in use"
      };
    }

    return {
      valid: true,
      reason : "username valid"
    };

  }catch(err){
    console.log(err)
    return {
      valid: false,
      reason : "unkown error"
    };
  }
}

function cleanEmailAddress(email : string){
  let finalEmail: string = email

  if (email === null){
    return null
  }
  if (email === undefined){
    return undefined
  }

  finalEmail = finalEmail.toLowerCase();
  return finalEmail;
}

export {
  testUsername,
  cleanEmailAddress,
};
