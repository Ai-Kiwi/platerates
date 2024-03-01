import nodemailer from "nodemailer";
import { reportError } from "./errorHandler";
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: "smtp.mailgun.org",
  port: 587,
  secure: false,
  auth: {
    user: 'postmaster@noreply.platerates.com',
    pass: '15fbe28a1a0ee074fcd02e751b18365e-b7b36bc2-268b9f45'
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