async function testUsername(username){
  try{
    const allowedCharsPattern = /^[a-zA-Z0-9_.-]+$/;
    //spaces as well /[a-zA-Z0-9_.-]./;

    const allowed = allowedCharsPattern.test(username)

    if (allowed !== true) {
      return [false, "not allowed chars"]
    }

    if (username.length > 25) {
      return [false,"username to large"]
    }

    if (username.length < 3) {
      return [false,"username to small"]
    }



    const collection = database.collection('user_data');

    const usernameInUse = await collection.findOne({username : username})

    if (usernameInUse !== null) {
      return [false,"username already in use"]
    }


    return [true]

  }catch(err){
    console.log(err)
    return [false, "unkown error"]
  }
}

module.exports = {
  testUsername:testUsername,
};
