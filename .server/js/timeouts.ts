import { database } from './database';
import { millisecondsToTime } from './utilFunctions';
import mongoDB from "mongodb";
import { Request, Response } from "express";



async function userTimeout(userId : string,timeoutAction : string,timeoutTime : number) {
    var collection : mongoDB.Collection = database.collection('user_data');

    let updateQuery: Record<string, any> = {};
    updateQuery.cooldowns = {};
    updateQuery.cooldowns[timeoutAction] = (timeoutTime * 1000) + Date.now();


    let collectionUpdate = await collection.updateOne(
        { userId: userId },
        { $set: updateQuery}
    );

    if (collectionUpdate.acknowledged === true){
        console.log("updated timeout");
        return true;
    }else{
        console.log("failed to update timeout");
        return false;
    }


}

async function userTimeoutLimit(userId : string,timeoutAction : string,maxTimeoutTime : number) {
    let collection : mongoDB.Collection = database.collection('user_data');


    let filterQuery : Record<string, any>  = {};
    filterQuery.userId = userId;
    filterQuery.cooldowns = {};
    filterQuery.cooldowns[timeoutAction] = {}
    filterQuery.cooldowns[timeoutAction]['$lt'] = (maxTimeoutTime * 1000) + Date.now();

    let updateQuery : Record<string, any> = {};
    updateQuery.cooldowns = {};
    updateQuery.cooldowns[timeoutAction] = (maxTimeoutTime * 1000) + Date.now();


    let collectionUpdate = await collection.updateOne(
        filterQuery,
        { $set: updateQuery},
    );

    if (collectionUpdate.acknowledged === true){
        console.log("updated timeout");
        return true;
    }else{
        console.log("failed to update timeout");
        return false;
    }

}

async function userTimeoutTest(userId : string,timeoutAction : string) {
    console.log("user timeout test");
    var collection = database.collection('user_data');

    const userData = await collection.findOne({userId: userId});

    //user data doesn't exist
    if (userData === null) {
        console.log("failed to get user data");
        return {
            active : false
        };
    }

    //item not created yet
    if (userData.cooldowns[timeoutAction] === undefined){
        console.log("timeout reason does not exist");
        return {
            active : false
        };
    }

    const timeoutLeft = millisecondsToTime(userData.cooldowns[timeoutAction]  - Date.now());
    //test if cooldown is active or not
    if ( userData.cooldowns[timeoutAction] >= Date.now() ) {
        console.log("user cooldown is active for " + timeoutLeft);
        return {
            active : false,
            timeLeft : timeoutLeft
        };
    }

    console.log("user cooldown is inactive");
    return {
        active : false
    };
    

}



export {
    userTimeout,
    userTimeoutTest,
    userTimeoutLimit,
};