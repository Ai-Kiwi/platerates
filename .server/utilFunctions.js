const crypto = require('crypto');

function generateRandomString(length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      const randomIndex = crypto.randomInt(0, chars.length);
      result += chars.charAt(randomIndex);
    }
    return result;
}

function millisecondsToTime(milliseconds){
  let time = milliseconds / 1000;

  if (time < 60) {
    return `${Math.floor(time)} seconds`
  }

  time = time / 60

  if (time < 60) {
    return `${Math.floor(time)} minutes`
  }

  time = time / 60

  if (time < 60) {
    return `${Math.floor(time)} hours`
  }

  time = time / 24

  if (time < 24) {
    return `${Math.floor(time)} days`
  }

  if (time < 300) {
    time = time / 360
    return `${Math.floor(time)} years`
  }else{
    time = time / 30
    return `${Math.floor(time)} months`
  }
}

module.exports = { 
  generateRandomString:generateRandomString, 
  millisecondsToTime:millisecondsToTime 
};