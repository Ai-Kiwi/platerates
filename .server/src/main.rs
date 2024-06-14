mod user_posts;
mod user_profiles;
mod user_ratings;
mod user_login;
mod utils;
mod reset_password;
mod licences;
mod pages;

use std::{collections::HashMap, fs, vec};
use argon2::Argon2;
use axum::{
    routing::{get, post}, Router
};
use jsonwebtoken::{DecodingKey, EncodingKey};
use lettre::{transport::smtp::authentication::Credentials, SmtpTransport};
use licences::post_licenses_update;
use pages::{get_page_community_guidelines, get_page_delete_data, get_page_privacy_policy, get_page_styles, get_page_terms_of_service};
use user_ratings::post_like_rating;
use std::env;
use std::path::PathBuf;
use sqlx::{postgres::{PgPoolOptions, Postgres}, Pool};
use rand::rngs::OsRng;
use rand::RngCore;
use crate::{licences::get_unaccepted_licenses, reset_password::{get_reset_password, post_create_reset_password_code, post_use_reset_password_code}, user_login::{post_logout, post_test_token}, user_posts::{get_post_data, get_post_feed, get_post_image_data, get_post_ratings, post_create_upload, post_delete_post}, user_profiles::{get_profile_avatar, get_profile_basic_data, get_profile_data, get_profile_posts, get_profile_ratings}, user_ratings::{post_create_rating, post_delete_rating_post}, utils::create_reset_code};
use crate::user_ratings::get_rating_data;
use crate::user_login::post_user_login;
use clap::Parser;

use tower_http::services::ServeDir;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(long)]
    database_url: String,

    #[arg(long)]
    smpt_host: String,

    #[arg(long)]
    smpt_auth_user: String,

    #[arg(long)]
    smpt_auth_password: String,
}


#[macro_use]
extern crate lazy_static;

lazy_static! {
    static ref ARGS: Vec<String> = env::args().collect();

    static ref DATA_FOLDER_PATH: PathBuf = env::current_dir().expect("failed to find data path").join("data");

    static ref DATA_IMAGE_FOLDER_PATH: PathBuf = DATA_FOLDER_PATH.to_owned().join("images");
    static ref DATA_IMAGE_POSTS_FOLDER_PATH: PathBuf = DATA_FOLDER_PATH.to_owned().join("images").join("posts");
    static ref DATA_IMAGE_AVATARS_FOLDER_PATH: PathBuf = DATA_FOLDER_PATH.to_owned().join("images").join("avatars");

    //static data is regular data but static!
    //its stuff like website builds, app downloads and jwt keys
    static ref STATIC_DATA_FOLDER_PATH: PathBuf = env::current_dir().expect("failed to find static_data path").join("static_data");

    static ref PRIVATE_JWT_KEY_FILE: PathBuf = STATIC_DATA_FOLDER_PATH.to_owned().join("jwt.key");

    static ref LICENSES: HashMap<String, i32> = {
        let mut m: HashMap<String, i32> = HashMap::new();
        m.insert("CommunityGuidelines".to_string(), 1);
        m.insert("deleteData".to_string(), 3);
        m.insert("privacyPolicy".to_string(), 3);
        m.insert("termsofService".to_string(), 1);
        m
    };

}



const CLIENT_VERSION: &str = "2.0.0+1";



async fn get_latest_version() -> &'static str {
    CLIENT_VERSION
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
    argon2 : Argon2<'a>,
    mailer : SmtpTransport,
}


#[tokio::main]
async fn main() {
    //load args
    let args: Args = Args::parse();
    let database_url: String = args.database_url;
    let smpt_host: String = args.smpt_host;
    let smpt_auth_user: String = args.smpt_auth_user;
    let smpt_auth_password: String = args.smpt_auth_password;

    println!("{}",create_reset_code());


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
    .connect(&database_url).await.expect("Failed to connect to postgres database");

    println!("connected to database");

    // initialize tracing
    tracing_subscriber::fmt::init();

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

    //setup email server
    let creds: Credentials = Credentials::new(smpt_auth_user, smpt_auth_password);

    // Open a remote connection to gmail
    let mailer: SmtpTransport = SmtpTransport::relay(&smpt_host)
        .unwrap()
        .credentials(creds)
        .build();

    let state: AppState = AppState { 
        database: database_pool, 
        jwt_encode_key: encoding_key,
        jwt_decode_key: decoding_key,
        argon2: argon2,
        mailer: mailer
    };

    // build our application with a route
    let app: Router = Router::new()
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
        .route("/post/delete", post(post_delete_post))
        .route("/post/rating/delete", post(post_delete_rating_post))
        .route("/post/upload", post(post_create_upload))
        .route("/post/rating/upload", post(post_create_rating))
        .route("/post/rating/like", post(post_like_rating))
        .route("/reset-password", get(get_reset_password))
        .route("/login/reset-password", post(post_create_reset_password_code))
        .route("/use-reset-password-code", post(post_use_reset_password_code))
        .route("/licenses/unaccepted", get(get_unaccepted_licenses))
        .route("/licenses/update", post(post_licenses_update))
        .route("/deleteData", get(get_page_delete_data))
        .route("/privacyPolicy", get(get_page_privacy_policy))
        .route("/CommunityGuidelines",get(get_page_community_guidelines))
        .route("/termsOfService", get(get_page_terms_of_service))
        .route("/styles.css", get(get_page_styles))
        .nest_service("/", ServeDir::new(STATIC_DATA_FOLDER_PATH.join("web"))) //host web dir
        .with_state(state);

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3030").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

//to test run
// cargo watch -x run

//   TODO 

//TODO

//    - adminZone
//   TODO /admin/banUser
//    add back admin users
//    allow to delete any post
//   
//    - notifcation system
//   TODO sendMailToDevice
//   TODO /notification/updateDeviceToken
//   TODO sendNotification
//   TODO /notification/list
//   TODO /notification/read
//   TODO /notification/unreadCount
//   //when respond to rating
//   
//    - report
//   TODO /report
//   //likly gonna redo and just completly remove links, this way its way more open to whatever
//   //also will add a browse thing to browse reported posts, from there can click ignore or remove or ban account. 
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

//test if flutter website has error with CORS
//bring over apk download link
//make sure log out all clears the list of tokens manuelly expired
//add back post feed for users you follow
//add get profile ratings, not sure if fully done and code is not used or code is half done
//test if display for if post is rated is working