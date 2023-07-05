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

module.exports = { generateRandomString };