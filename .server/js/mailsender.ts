import nodemailer from "nodemailer";
import { reportError } from "./errorHandler";
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: "smtp.mailgun.org",
  port: 587,
  secure: false,
  auth: {
    user: 'postmaster@noreply.aikiwi.dev',
    pass: 'cc0ddfe1bd8d417ac6d6eac05f08fa5f-c30053db-99090a01'
  }
});

// async..await is not allowed in global scope, must use a wrapper
async function sendMail(from : string,to : string,subject : string,text : string) {
    try{
        // send mail with defined transport object
        const info: nodemailer.SentMessageInfo = await transporter.sendMail({
          from: from, // sender address
          to: to, // list of receivers
          subject: subject, // Subject line
          text: text, // plain text body
        });

        console.log("Message sent: %s", info.messageId);
        return info;
    }catch (err){
        reportError(err);
        return null
    }
}

export {
  sendMail,
};