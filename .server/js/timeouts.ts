import { databases } from './database';
import { millisecondsToTime } from './utilFunctions';
import mongoDB from "mongodb";
import { Request, Response } from "express";

const ipAddressTimeouts = {}

async function ipAddressTimeout(ipAddress : string,timeoutAction : string,timeoutTime : number) {
    if (ipAddressTimeouts[ipAddress] === undefined){
        ipAddressTimeouts[ipAddress] = {}
    }
    ipAddressTimeouts[ipAddress][timeoutAction] = (timeoutTime * 1000) + Date.now();

}

async function IpAddressTimeoutTest(ipAddress : string,timeoutAction : string) {
    //user data doesn't exist
    if (ipAddressTimeouts[ipAddress] === undefined) {
        return {
            active : false
        };
    }

    //item not created yet
    if (ipAddressTimeouts[ipAddress][timeoutAction] === undefined){
        return {
            active : false
        };
    }

    const timeoutLeft = millisecondsToTime(ipAddressTimeouts[ipAddress][timeoutAction] - Date.now());
    //test if cooldown is active or not
    if ( ipAddressTimeouts[ipAddress][timeoutAction] >= Date.now() ) {
        console.log("user cooldown is active for " + timeoutLeft);
        return {
            active : true,
            timeLeft : timeoutLeft
        };
    }else{
        return {
            active : false
        };
    }

    

}


async function userTimeout(userId : string,timeoutAction : string,timeoutTime : number) {
    let updateQuery: Record<string, any> = {};
    updateQuery.cooldowns = {};
    updateQuery.cooldowns[timeoutAction] = (timeoutTime * 1000) + Date.now();


    let collectionUpdate = await databases.user_data.updateOne(
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
    let filterQuery : Record<string, any>  = {};
    filterQuery.userId = userId;
    filterQuery.cooldowns = {};
    filterQuery.cooldowns[timeoutAction] = {}
    filterQuery.cooldowns[timeoutAction]['$lt'] = (maxTimeoutTime * 1000) + Date.now();

    let updateQuery : Record<string, any> = {};
    updateQuery.cooldowns = {};
    updateQuery.cooldowns[timeoutAction] = (maxTimeoutTime * 1000) + Date.now();


    let collectionUpdate = await databases.user_data.updateOne(
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
    const userData = await databases.user_data.findOne({userId: userId});

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
            active : true,
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
    ipAddressTimeout,
    IpAddressTimeoutTest,
};