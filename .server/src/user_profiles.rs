use std::{collections::HashMap, fs, path::PathBuf};
use axum::extract::{Query, State};
use data_encoding::BASE64;
use hyper::StatusCode;
use serde::Deserialize;
use serde_json::Value;
use sqlx::{Pool, Postgres};

use crate::{user_posts::PostsJustPostId, user_ratings::RatingsJustId, AppState, DATA_IMAGE_AVATARS_FOLDER_PATH};

#[derive(Deserialize)]
pub struct GetUserInfoPaginator {
    user_id: String,
}

#[derive(sqlx::FromRow)]
pub struct UserBasicData { 
    user_id: String,
    username: String,
    avatar_id: Option<String>,
}

pub async fn get_profile_basic_data(pagination: Query<GetUserInfoPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user fetch basic profile data");
    let pagination: GetUserInfoPaginator = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let user_id: &String = &pagination.user_id;
    
    let user_data: UserBasicData = match sqlx::query_as::<_, UserBasicData>("SELECT user_id, username, avatar_id FROM user_data WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "No user found".to_string()),
    };

    let _ = user_data.user_id; //purely to get rid of unused warning lmao
    data_returning.insert("username".to_string(), Value::String(user_data.username));
    match user_data.avatar_id {
        Some(value) => data_returning.insert("avatar".to_string(), Value::String(value)),
        None => data_returning.insert("avatar".to_string(), Value::Null),
    };
    

    let value = match serde_json::to_string(&data_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert basic user data to json".to_string())
    };

    (StatusCode::OK, value)
}


#[derive(sqlx::FromRow)]
pub struct UserData { 
    pub user_id: String,
    pub username: String,
    pub bio: String,
    pub avatar_id: Option<String>,
    pub administrator : bool,
    pub post_count: i32,
    pub rating_count: i32,
    pub followers_count: i32,
    pub following_count: i32,
    pub creation_date: i64,
    pub licenses: sqlx::types::Json<HashMap<String,i32>>
}

pub async fn get_profile_data(pagination: Query<GetUserInfoPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user fetch profile data");
    let pagination: GetUserInfoPaginator = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let user_id: &String = &pagination.user_id;
    
    let user_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(err) => return (StatusCode::NOT_FOUND, "User not found".to_string() + &err.to_string()),
    };

    let _ = user_data.creation_date; //purely to get rid of unused warning lmao
    data_returning.insert("username".to_string(), Value::String(user_data.username));
    data_returning.insert("bio".to_string(), Value::String(user_data.bio));
    data_returning.insert("administrator".to_string(), Value::Bool(user_data.administrator));
    data_returning.insert("userId".to_string(), Value::String(user_data.user_id));
    data_returning.insert("followersCount".to_string(), Value::Number(user_data.followers_count.into()));
    data_returning.insert("followingCount".to_string(), Value::Number(user_data.following_count.into()));
    data_returning.insert("postCount".to_string(), Value::Number(user_data.post_count.into()));
    data_returning.insert("ratingCount".to_string(), Value::Number(user_data.rating_count.into()));
    data_returning.insert("requesterFollowing".to_string(), Value::Bool(false));
    match user_data.avatar_id {
        Some(value) => data_returning.insert("avatar".to_string(), Value::String(value)),
        None => data_returning.insert("avatar".to_string(), Value::Null),
    };
    

    let value = match serde_json::to_string(&data_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert basic user data to json".to_string())
    };


    (StatusCode::OK, value)
}

#[derive(Deserialize)]
pub struct GetUserAvatarPaginator {
    avatar_id: String,
}

pub async fn get_profile_avatar(pagination: Query<GetUserAvatarPaginator>) -> (StatusCode, String) {
    let pagination: GetUserAvatarPaginator = pagination.0;
    let avatar_id: String = pagination.avatar_id;
    //println!("{}", image_number);

    if avatar_id.contains(".") {
        return (StatusCode::BAD_REQUEST, "image number contains invalid char".to_string());
    }
    if avatar_id.contains("/") {
        return (StatusCode::BAD_REQUEST, "image number contains invalid char".to_string());
    }
    if avatar_id.contains("-") {
        return (StatusCode::BAD_REQUEST, "image number contains invalid char".to_string());
    }


    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let image_file_name = format!("{}.jpeg",avatar_id);
    
    let file_path: PathBuf = DATA_IMAGE_AVATARS_FOLDER_PATH.join(image_file_name);
    let image_data: Vec<u8> = match fs::read(file_path){
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "avatar image file not found".to_string()),
    };

    let base64_image_value: String = BASE64.encode(&image_data);


    data_returning.insert("imageData".to_string(), Value::String(base64_image_value));


    //make sure non contain dashs or slashs or dots

    //let current_path = env::current_dir().unwrap();

    let value = match serde_json::to_string(&data_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert avatar image data to json".to_string())
    };

    return (StatusCode::OK, value);
}


#[derive(Deserialize)]
pub struct GetProfilePosts {
    page : String,
    page_size : String,
    user_id : String,
}


pub async fn get_profile_posts(pagination: Query<GetProfilePosts>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {

    let pagination: GetProfilePosts = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.page_size.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };

    let user_id: String = match pagination.user_id.parse::<String>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "No user id added".to_string()),
    };
    
    let posts_data: Vec<PostsJustPostId> = match sqlx::query_as::<_, PostsJustPostId>("SELECT post_id FROM posts WHERE poster_user_id = $1 ORDER BY post_date DESC LIMIT $2 OFFSET $3")
    .bind(user_id)
    .bind(page_size)
    .bind(page_number * page_size)
    .fetch_all(&database_pool).await {
        Ok(value) => value,
        Err(err) => {
            println!("{}", err);
            return (StatusCode::NOT_FOUND, "Failed getting posts".to_string());
        },
    };

    let mut post_returning: Vec<HashMap<&str, &str>> = vec!();

    for post_item in &posts_data {
        let post_id = &post_item.post_id;

        post_returning.push(HashMap::from([
            ("type", "post"),
            ("data", &post_id),
        ]));
    }
    

    let value = match serde_json::to_string(&post_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert post data to json".to_string()),
    };

    (StatusCode::OK, value)
}


#[derive(Deserialize)]
pub struct GetProfileRatings {
    page : String,
    page_size : String,
    user_id : String,
}

pub async fn get_profile_ratings(pagination: Query<GetProfileRatings>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {

    let pagination: GetProfileRatings = pagination.0;
    let database_pool = app_state.database;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.page_size.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };

    let user_id: String = match pagination.user_id.parse::<String>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "No user id added".to_string()),
    };
    
    let ratings_data: Vec<RatingsJustId> = match sqlx::query_as::<_, RatingsJustId>("SELECT rating_id FROM post_ratings WHERE rating_creator = $1 ORDER BY creation_date DESC LIMIT $2 OFFSET $3")
    .bind(user_id)
    .bind(page_size)
    .bind(page_number * page_size)
    .fetch_all(&database_pool).await {
        Ok(value) => value,
        Err(err) => {
            println!("{}", err);
            return (StatusCode::NOT_FOUND, "Failed getting posts".to_string());
        },
    };

    let mut post_returning: Vec<HashMap<&str, &str>> = vec!();

    for rating_item in &ratings_data {
        let post_id = &rating_item.rating_id;

        post_returning.push(HashMap::from([
            ("type", "rating"),
            ("data", &post_id),
        ]));
    }
    

    let value = match serde_json::to_string(&post_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert post data to json".to_string()),
    };

    (StatusCode::OK, value)
}