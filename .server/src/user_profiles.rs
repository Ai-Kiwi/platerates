use std::{collections::HashMap, fs, path::PathBuf};
use axum::{extract::{Query, State}, routing::get, Router};
use data_encoding::BASE64;
use hyper::StatusCode;
use serde::{de::value, Deserialize};
use serde_json::Value;
use sqlx::{database, Pool, Postgres};

use crate::{user_posts::posts_just_post_id, user_ratings::ratings_just_id, AppState, DATA_IMAGE_AVATARS_FOLDER_PATH, DATA_IMAGE_POSTS_FOLDER_PATH};

#[derive(Deserialize)]
pub struct GetUserInfoPaginator {
    userId: String,
}

#[derive(sqlx::FromRow)]
pub struct userBasicData { 
    user_id: String,
    username: String,
    avatar_id: Option<String>,
}

pub async fn get_profile_basic_data(pagination: Query<GetUserInfoPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user fetch basic profile data");
    let pagination: GetUserInfoPaginator = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let user_id: &String = &pagination.userId;
    
    let user_data: userBasicData = match sqlx::query_as::<_, userBasicData>("SELECT user_id, username, avatar_id FROM user_data WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(err) => return (StatusCode::NOT_FOUND, "No user found".to_string()),
    };

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
pub struct userData { 
    user_id: String,
    username: String,
    bio: String,
    avatar_id: Option<String>,
    administrator : bool,
    post_count: i32,
    rating_count: i32,
    followers_count: i32,
    following_count: i32,
    creation_date: i64,
}

pub async fn get_profile_data(pagination: Query<GetUserInfoPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user fetch profile data");
    let pagination: GetUserInfoPaginator = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let user_id: &String = &pagination.userId;
    
    let user_data: userData = match sqlx::query_as::<_, userData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(err) => return (StatusCode::NOT_FOUND, "User not found".to_string() + &err.to_string()),
    };

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
    pageSize : String,
    user_id : String,
}

#[derive(Deserialize)]
pub struct GetPostPaginator {
    postId: String,
}

pub async fn get_profile_posts(pagination: Query<GetProfilePosts>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {

    let pagination: GetProfilePosts = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.pageSize.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };

    let user_id: String = match pagination.user_id.parse::<String>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "No user id added".to_string()),
    };
    
    let posts_data: Vec<posts_just_post_id> = match sqlx::query_as::<_, posts_just_post_id>("SELECT post_id FROM posts WHERE poster_user_id = $1 ORDER BY post_date DESC LIMIT $2 OFFSET $3")
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
    pageSize : String,
    user_id : String,
}

pub async fn get_profile_ratings(pagination: Query<GetProfileRatings>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {

    let pagination: GetProfileRatings = pagination.0;
    let database_pool = app_state.database;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.pageSize.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };

    let user_id: String = match pagination.user_id.parse::<String>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "No user id added".to_string()),
    };
    
    let ratings_data: Vec<ratings_just_id> = match sqlx::query_as::<_, ratings_just_id>("SELECT rating_id FROM post_ratings WHERE rating_creator = $1 ORDER BY creation_date DESC LIMIT $2 OFFSET $3")
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