const nodemailer = require("nodemailer");
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: "smtp.mailgun.org",
  port: 587,
  secure: false,
  auth: {
    user: 'postmaster@aikiwi.dev',
    pass: 'e8a939036393ef0ed129ce66aa832325-262b213e-9d20ad13'
  }
});

// async..await is not allowed in global scope, must use a wrapper
async function sendMail(from,to,subject,text) {
    try{
        // send mail with defined transport object
        const info = await transporter.sendMail({
          from: from, // sender address
          to: to, // list of receivers
          subject: subject, // Subject line
          text: text, // plain text body
        });

        console.log("Message sent: %s", info.messageId);
        return info;
    }catch (err){
        console.log(err);
        return null
    }
}

module.exports = {
  sendMail:sendMail,
};