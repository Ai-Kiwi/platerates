const { database } = require('./database');
const { millisecondsToTime } = require('./utilFunctions');




async function userTimeout(userId,timeoutAction,timeoutTime) {
    var collection = database.collection('user_data');

    var updateQuery = {};
    updateQuery.cooldowns = {};
    updateQuery.cooldowns[timeoutAction] = (timeoutTime * 1000) + Date.now();


    let collectionUpdate = await collection.updateOne(
        { userId: userId },
        { $set: updateQuery}
    );

    if (collectionUpdate.acknowledged === true){
        console.log("updated timeout");
        return [true];
    }else{
        console.log("failed to update timeout");
        return [false];
    }


}


async function userTimeoutTest(userId,timeoutAction) {
    console.log("user timeout test");
    var collection = database.collection('user_data');

    const userData = await collection.findOne({userId: userId});

    //user data doesn't exist
    if (userData === null) {
        console.log("failed to get user data");
        return [false];
    }

    console.log(userData);
    console.table(userData);
    //item not created yet
    if (userData.cooldowns[timeoutAction] === undefined){
        console.log("timeout reason does not exist");
        return [false];
    }

    const timeoutLeft = millisecondsToTime(userData.cooldowns[timeoutAction]  - Date.now());
    //test if cooldown is active or not
    if ( userData.cooldowns[timeoutAction] >= Date.now() ) {
        console.log("user cooldown is active for " + timeoutLeft);
        return [true, timeoutLeft ];
    }else{
        console.log("user cooldown is inactive");
        return [false];
    }

}



module.exports = {
    userTimeout:userTimeout,
    userTimeoutTest:userTimeoutTest,
};