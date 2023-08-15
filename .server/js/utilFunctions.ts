import crypto from 'crypto';

function generateRandomString(length : number) {
    const chars : string = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result : string = '';
    for (let i = 0; i < length; i++) {
      const randomIndex = crypto.randomInt(0, chars.length);
      result += chars.charAt(randomIndex);
    }
    return result;
}

function millisecondsToTime(milliseconds : number){
  let time : string | number = milliseconds / 1000;

  if (time < 60) {
    return `${Math.round(time)} seconds` as string
  }

  time = time / 60

  if (time < 60) {
    return `${Math.round(time)} minutes` as string
  }

  time = time / 60

  if (time < 60) {
    return `${Math.round(time)} hours` as string
  }

  time = time / 24

  if (time < 24) {
    return `${Math.round(time)} days` as string
  }

  if (time < 360) {
    time = time / 360
    return `${Math.round(time)} years` as string
  }else{
    time = time / 30
    return `${Math.round(time)} months` as string
  }
}

//async function 

export { 
  generateRandomString, 
  millisecondsToTime 
};