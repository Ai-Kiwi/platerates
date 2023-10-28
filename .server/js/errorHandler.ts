import { databases } from "./database";
import { sendNotificationToDevices } from "./notificationSystem";



async function reportError(error){
    console.log(`# error #\n${error}\n`)
    
    const adminUsers = await databases.user_data.find({ administrator : true }).toArray();

    adminUsers.forEach(element => {
        const userIdValue : String = element.userId;
        sendNotificationToDevices("server crash",`${error}`.toString(),"admin",[userIdValue],"undefined")
    });


}

export {
    reportError
}