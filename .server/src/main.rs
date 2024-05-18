mod user_posts;
mod user_profiles;
mod user_ratings;
mod user_login;

use core::panic;
use std::{any, collections::HashMap, fs::{self, File}, hash::Hash, io::Read, iter::Map, ptr::null, string, sync::Arc, task::Poll, vec};

use argon2::Argon2;
use axum::{
    extract::{Path, Query, State}, http::StatusCode, response::IntoResponse, routing::{get, post}, Json, Router
};
use hyper::header;
use jsonwebtoken::{Algorithm, DecodingKey, EncodingKey, Header};
use serde::{de::value, Deserialize, Serialize};

use serde_json::{Number, Value};
use std::env;
use std::path::PathBuf;
use data_encoding::BASE64;
use sqlx::{postgres::{PgPoolOptions, Postgres}, Pool};
use rand::rngs::OsRng;
use rand::RngCore;
use tower::ServiceBuilder;

use crate::{user_login::{post_logout, post_test_token}, user_posts::{get_post_data, get_post_feed, get_post_image_data, get_post_ratings}, user_profiles::{get_profile_avatar, get_profile_basic_data, get_profile_data, get_profile_posts, get_profile_ratings}};
use crate::user_ratings::get_rating_data;
use crate::user_login::post_user_login;


#[macro_use]
extern crate lazy_static;

lazy_static! {
    static ref ARGS: Vec<String> = env::args().collect();

    static ref DATA_FOLDER_PATH: PathBuf = match ARGS.get(1){
        Some(value) => PathBuf::from(value),
        //nothing loaded by user so load the current work path
        None => env::current_dir().expect("failed to find data path").join("data"),
    };

    static ref DATA_IMAGE_FOLDER_PATH: PathBuf = DATA_FOLDER_PATH.to_owned().join("images");
    static ref DATA_IMAGE_POSTS_FOLDER_PATH: PathBuf = DATA_FOLDER_PATH.to_owned().join("images").join("posts");
    static ref DATA_IMAGE_AVATARS_FOLDER_PATH: PathBuf = DATA_FOLDER_PATH.to_owned().join("images").join("avatars");

    //static data is regular data but static!
    //its stuff like website builds, app downloads and jwt keys
    static ref STATIC_DATA_FOLDER_PATH: PathBuf = match ARGS.get(2){
        Some(value) => PathBuf::from(value),
        //nothing loaded by user so load the current work path
        None => env::current_dir().expect("failed to find static_data path").join("static_data"),
    };

    static ref PRIVATE_JWT_KEY_FILE: PathBuf = STATIC_DATA_FOLDER_PATH.to_owned().join("jwt.key");
}



const CLIENT_VERSION: &str = "2.0.0+1";



async fn get_latest_version() -> &'static str {
    CLIENT_VERSION
}

// basic handler that responds with a static string
async fn root() -> &'static str {
    "this is a root response return"
}


fn generate_hmac_secret_key(length: usize) -> Vec<u8> {
    let mut rng = OsRng;
    let mut key = vec![0; length];
    rng.fill_bytes(&mut key);
    key
}


#[derive(Clone)]
pub struct AppState<'a> {
    database : Pool<Postgres>,
    jwt_encode_key : EncodingKey,
    jwt_decode_key : DecodingKey,
    argon2 : Argon2<'a>
}


#[tokio::main]
async fn main() {
    //creates needed data storage data
    let _ = fs::create_dir_all(&*DATA_IMAGE_FOLDER_PATH).expect("failed to create data dir");
    let _ = fs::create_dir_all(&*DATA_IMAGE_POSTS_FOLDER_PATH).expect("failed to create data image dir");
    let _ = fs::create_dir_all(&*DATA_IMAGE_AVATARS_FOLDER_PATH).expect("failed to create data avatar image dir");

    let _ = fs::create_dir_all(&*STATIC_DATA_FOLDER_PATH).expect("failed to create static data dir");

    // /home/aikiwi/Projects/phoneApps/toaster/
    println!("loaded path {}",&DATA_FOLDER_PATH.to_string_lossy());
 
    println!("connecting to database");
    let database_pool: Pool<Postgres> = PgPoolOptions::new()
    .max_connections(5)
    //don't bother trying to be sneaky this is my test server info
    .connect("postgres://toasteruser:X4F0p7Q95dbXjNJ8fu80Ompl4CxREfrtr2T62eVUdJrrI0w8v16uymNFMiIacKyw@127.0.0.1/toasterdev").await.expect("Failed to connect to postgres database");

    println!("connected to database");

    // initialize tracing
    tracing_subscriber::fmt::init();

    //setup jsonwebtokens
    let mut header = Header::new(Algorithm::HS512);

    let example_hmac_secret_key = generate_hmac_secret_key(32); //256 bits

    println!("loading jwt token key");

    if *&PRIVATE_JWT_KEY_FILE.exists() == false {
        println!("no jwt key found making one");
        let _ = fs::write(PRIVATE_JWT_KEY_FILE.clone(), example_hmac_secret_key);
    }
    let key_data: Vec<u8> = fs::read(PRIVATE_JWT_KEY_FILE.to_owned()).expect("failed to load key data");
    let encoding_key: EncodingKey = EncodingKey::from_secret(&key_data);
    let decoding_key: DecodingKey = DecodingKey::from_secret(&key_data);
    println!("loaded jwt key");

    //setup Argon2
    //if I change Algorithm in here it needs to be changed in test token part too
    let argon2: Argon2 = Argon2::default();
    

    let state: AppState = AppState { 
        database: database_pool, 
        jwt_encode_key: encoding_key,
        jwt_decode_key: decoding_key,
        argon2: argon2,
    };

    // build our application with a route
    let app: Router = Router::new()
        // `GET /` goes to `root`
        .route("/", get(root))
        // `POST /users` goes to `create_user`
        .route("/latestVersion", get(get_latest_version))
        .route("/profile/basicData", get(get_profile_basic_data))
        .route("/profile/data", get(get_profile_data))
        .route("/post/feed", get(get_post_feed))
        .route("/post/data", get(get_post_data))
        .route("/post/image", get(get_post_image_data))
        .route("/post/ratings", get(get_post_ratings))
        .route("/profile/posts", get(get_profile_posts))
        .route("/profile/ratings", get(get_profile_ratings))
        .route("/post/rating/data", get(get_rating_data))
        .route("/profile/avatar", get(get_profile_avatar))
        .route("/login", post(post_user_login))
        .route("/testToken", post(post_test_token))
        .route("/login/logout", post(post_logout))
        .with_state(state);

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3030").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

//to test run
// cargo watch -x run



//TODO

//    - adminZone
//   TODO /admin/banUser
//   
//    - chatSystem
//   TODO all of it
//   
//    - lisences
//   TODO /licenses/unaccepted
//   TODO /licenses/update
//   
//    - mailsender
//   TODO sendMail
//   
//    - notifcation system
//   TODO sendMailToDevice
//   TODO /notification/updateDeviceToken
//   TODO sendNotification
//   TODO /notification/list
//   TODO /notification/read
//   TODO /notification/unreadCount
//   
//    - report
//   TODO /report
//   
//    - searchSystem
//   TODO /search/users
//   
//    - userAccounts
//   TODO /profile/settings/change
//   TODO /profile/ratings
//   TODO /profile/follow
//   TODO /use-create-account-code
//   TODO /createAccount
//   
//    - userLogins 
//   TODO /login/reset-password
//   TODO /reset-password
//   
//    - posts
//   TODO /post/upload
//   TODO /post/delete
//   
//    - ratings
//   TODO /post/rating/delete
//   TODO /post/rating/like
//   TODO /post/rating/upload

//make program for loading .env
// //postgresql connection
// //folder for data
// //extra like hosting info folder
// //mail info
//bring over flutter website host part
//bring over apk download
//bring over tos websites info
//test if number of comment replys is working as it seems to show 1 when there is non
//add logout one user
//move system over to refresh tokens instead
//make sure log out all clears the list of tokens manuelly expired