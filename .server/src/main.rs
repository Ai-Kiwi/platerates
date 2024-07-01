mod user_posts;
mod user_profiles;
mod user_ratings;
mod user_login;
mod utils;
mod reset_password;
mod licences;
mod pages;
mod notifications;
mod admin;

use std::{collections::HashMap, fs, vec};
use admin::post_ban_user;
use argon2::Argon2;
use axum::{
    routing::{get, post}, Router
};
use hyper::Method;
use jsonwebtoken::{DecodingKey, EncodingKey};
use lettre::{transport::smtp::authentication::Credentials, SmtpTransport};
use licences::post_licenses_update;
use notifications::{get_notifications_list, get_notifications_unread, post_mark_notification_read, post_update_notification_token, send_notification_to_user_id};
use pages::{get_page_community_guidelines, get_page_delete_data, get_page_privacy_policy, get_page_styles, get_page_terms_of_service};
use serde_json::Value;
use user_profiles::{post_setting_change, post_user_follow};
use user_ratings::post_like_rating;
use std::env;
use std::path::PathBuf;
use sqlx::{postgres::{PgPoolOptions, Postgres}, Any, Pool};
use rand::rngs::OsRng;
use rand::RngCore;
use crate::{licences::get_unaccepted_licenses, reset_password::{get_reset_password, post_create_reset_password_code, post_use_reset_password_code}, user_login::{post_logout, post_test_token}, user_posts::{get_post_data, get_post_feed, get_post_image_data, get_post_ratings, post_create_upload, post_delete_post}, user_profiles::{get_profile_avatar, get_profile_basic_data, get_profile_data, get_profile_posts, get_profile_ratings}, user_ratings::{post_create_rating, post_delete_rating_post}, utils::create_reset_code};
use crate::user_ratings::get_rating_data;
use crate::user_login::post_user_login;
use clap::Parser;
use gcp_auth::{CustomServiceAccount, TokenProvider};
use tower_http::cors::{AllowOrigin, CorsLayer};

use tower_http::{body, services::ServeDir};

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

    #[arg(long)]
    firebase_auth_file: String,

    #[arg(long)]
    firebase_project_id: String,
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
    firebase_token: std::sync::Arc<gcp_auth::Token>,
    firebase_project_id: String
}


#[tokio::main]
async fn main() {
    //load args
    let args: Args = Args::parse();
    let database_url: String = args.database_url;
    let smpt_host: String = args.smpt_host;
    let smpt_auth_user: String = args.smpt_auth_user;
    let smpt_auth_password: String = args.smpt_auth_password;
    let firebase_auth_file_path: String = args.firebase_auth_file;
    let firebase_project_id: String = args.firebase_project_id;


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

    // Open a remote connection to email
    let mailer: SmtpTransport = SmtpTransport::relay(&smpt_host)
        .unwrap()
        .credentials(creds)
        .build();

    //setup notifcation connection
    let credentials_path: PathBuf = PathBuf::from(firebase_auth_file_path);
    let service_account: CustomServiceAccount = CustomServiceAccount::from_file(credentials_path).expect("failed to load notifcation token file");
    let scopes: &[&str; 1] = &["https://www.googleapis.com/auth/cloud-platform"];
    let token: std::sync::Arc<gcp_auth::Token> = service_account.token(scopes).await.expect("failed to load notifcation token");

    let state: AppState = AppState { 
        database: database_pool, 
        jwt_encode_key: encoding_key,
        jwt_decode_key: decoding_key,
        argon2: argon2,
        mailer: mailer,
        firebase_token: token,
        firebase_project_id: firebase_project_id,
    };

    if STATIC_DATA_FOLDER_PATH.join("web").join("Platerates.apk").exists() == false {
        println!("Platerates.apk file not found");
        panic!()
    }

    let cors = if cfg!(debug_assertions) {
        // Debug/testing environment: Allow requests from all origins (not recommended for production)
        CorsLayer::new()       
        .allow_origin(AllowOrigin::predicate(|origin, _req| {
            // Allow all localhost origins or any other specific conditions
            origin.as_bytes().starts_with(b"http://localhost") || origin.as_bytes().starts_with(b"http://127.0.0.1") || origin.as_bytes().starts_with(b"http://192.168.0.")
        }))
        .allow_methods(vec![Method::GET, Method::POST, Method::PUT, Method::DELETE])
        .allow_headers(vec![
            "content-type".parse().unwrap(),
            "authorization".parse().unwrap(),
        ])
        .allow_credentials(true) // Allow credentials (e.g., cookies)
    } else {
        // Production environment: Allow requests only from the production domain
        CorsLayer::new()
            .allow_origin(AllowOrigin::predicate(|origin, _req| {
                // Allow all localhost origins or any other specific conditions
                origin.as_bytes().starts_with(b"https://platerates.com")
            }))
            .allow_methods(vec![Method::GET, Method::POST, Method::PUT, Method::DELETE])
            .allow_headers(vec![
                "content-type".parse().unwrap(),
                "authorization".parse().unwrap(),
            ])
            .allow_credentials(true) // Allow credentials (e.g., cookies)
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
        .route("/profile/follow", post(post_user_follow))
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
        .route("/notification/list", get(get_notifications_list))
        .route("/notification/updateDeviceToken", post(post_update_notification_token))
        .route("/notification/read", post(post_mark_notification_read))
        .route("/notification/unreadCount", get(get_notifications_unread))
        .route("/admin/banUser", post(post_ban_user))
        .route("/profile/settings/change", post(post_setting_change))
        .nest_service("/", ServeDir::new(STATIC_DATA_FOLDER_PATH.join("web"))) //host web dir
        .layer(cors)
        .with_state(state);

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3030").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

//   TODO 
//   
//    - report
//   TODO /report
//   TODO /report/list
//   TODO /report/accept
//   // // can decline or accept with parm
//   //custom admin screen menu with list of reported opens and link to open it
//   // //will list ammount of reports and tell you what everyone said
//   //when taken down it will have link to id and owner will be informed, reported will also be informed that it has been taken down. System will also alert all other users of it being taken down that have reviewed it
//   //when item is reported it will email person who reported it saying item has been reported and for further info contact support
//   
//    - searchSystem
//   TODO /search/users
//   
//    - userAccounts
//   TODO /use-create-account-code
//   TODO /createAccount

//make sure that after adding r# it is still working with sending link in email