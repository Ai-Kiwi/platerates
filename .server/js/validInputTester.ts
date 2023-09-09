import { database } from './database';
import mongoDB from "mongodb";
import { Request, Response } from "express";
import { RegExpMatcher, TextCensor, englishDataset, englishRecommendedTransformers, } from 'obscenity';
import validator from 'validator';

async function testUsername(username : string){
  try{
    //const matcher = new RegExpMatcher({
    //  ...englishDataset.build(),
    //  ...englishRecommendedTransformers,
    //});


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

    //if (matcher.hasMatch( username ) === true) {
    //  return {
    //    valid: false,
    //    reason : "username inappropriate"
    //  };
    //}

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
  let finalEmail: string | false = email

  if (email === null){
    return null
  }
  if (email === undefined){
    return undefined
  }
  if (validator.isEmail(email))

  finalEmail = validator.normalizeEmail(email);
  if (finalEmail === false){
    return null
  }else{
    return finalEmail;
  }
}

export {
  testUsername,
  cleanEmailAddress,
};
