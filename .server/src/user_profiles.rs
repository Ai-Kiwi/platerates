use std::{collections::HashMap, fs, path::PathBuf, time::{SystemTime, UNIX_EPOCH}};
use axum::{extract::{Query, State}, Json};
use data_encoding::BASE64;
use hyper::{HeaderMap, StatusCode};
use serde::Deserialize;
use serde_json::Value;
use sqlx::{Pool, Postgres};

use crate::{user_login::test_token_header, user_posts::PostsJustPostId, user_ratings::RatingsJustId, utils::{create_item_id, test_bio, test_username}, AppState, DATA_IMAGE_AVATARS_FOLDER_PATH};

#[derive(Deserialize)]
pub struct GetUserInfoPaginator {
    user_id: String,
}

#[derive(sqlx::FromRow)]
pub struct UserBasicData { 
    pub user_id: String,
    pub username: String,
    pub avatar_id: Option<String>,
}

#[derive(sqlx::FromRow)]
pub struct UserJustUserId { 
    pub user_id: String,
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
    pub creation_date: i64,
    pub licenses: sqlx::types::Json<HashMap<String,i32>>,
    pub notify_on_new_post : bool
}

pub async fn get_profile_data(pagination: Query<GetUserInfoPaginator>, State(app_state): State<AppState<'_>>, headers: HeaderMap,) -> (StatusCode, String) {
    println!("user fetch profile data");
    let pagination: GetUserInfoPaginator = pagination.0;
    let database_pool: &Pool<Postgres> = &app_state.database;
    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
    let logged_in_user_id: Option<String> = match token {
        Ok(value) => Some(value.claims.user_id),
        Err(_) => None,
    };
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let user_id: &String = &pagination.user_id;
    
    let user_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(err) => return (StatusCode::NOT_FOUND, "User not found".to_string() + &err.to_string()),
    };

    let _ = user_data.creation_date; //purely to get rid of unused warning lmao
    data_returning.insert("username".to_string(), Value::String(user_data.username));
    data_returning.insert("bio".to_string(), Value::String(user_data.bio));
    data_returning.insert("administrator".to_string(), Value::Bool(user_data.administrator));
    data_returning.insert("userId".to_string(), Value::String(user_data.user_id));

    let following_count_row: (i64,) = match sqlx::query_as(
        "SELECT COUNT(*) FROM user_follows WHERE follower = $1"
    )
    .bind(&user_id)
    .fetch_one(database_pool)
    .await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to count users being followed by");
            (-1,)
        },
    };
    data_returning.insert("followingCount".to_string(), Value::Number(following_count_row.0.into()));

    let followers_count_row: (i64,) = match sqlx::query_as(
        "SELECT COUNT(*) FROM user_follows WHERE followee = $1"
    )
    .bind(&user_id)
    .fetch_one(database_pool)
    .await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to count users following");
            (-1,)
        },
    };
    data_returning.insert("followersCount".to_string(), Value::Number(followers_count_row.0.into()));

    let post_count_row: (i64,) = match sqlx::query_as(
        "SELECT COUNT(*) FROM posts WHERE poster_user_id = $1"
    )
    .bind(&user_id)
    .fetch_one(database_pool)
    .await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to count posts");
            (-1,)
        },
    };
    data_returning.insert("postCount".to_string(), Value::Number(post_count_row.0.into()));


    let rating_count_row: (i64,) = match sqlx::query_as(
        "SELECT COUNT(*) FROM post_ratings WHERE rating_creator = $1 AND rating IS NOT NULL"
    )
    .bind(&user_id)
    .fetch_one(database_pool)
    .await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to count post ratings");
            (-1,)
        },
    };
    data_returning.insert("ratingCount".to_string(), Value::Number(rating_count_row.0.into()));

    let following: bool = match logged_in_user_id {
        Some(safe_logged_in_user_id) => {
            match sqlx::query_as::<_, UserFollow>("SELECT * FROM user_follows WHERE follower = $1 AND followee = $2")
            .bind(&safe_logged_in_user_id)
            .bind(&user_id)
            .fetch_one(database_pool).await {
                Ok(_) => true,
                Err(err) => {
                    match err {
                        sqlx::Error::RowNotFound => false,
                        _ => {
                            println!("Failed to fetch if following ({})", err);
                            return (StatusCode::NOT_FOUND, "Failed to fetch if following already".to_string());
                        }
                    }
                },
            }
        },
        None => false,
    };

    data_returning.insert("requesterFollowing".to_string(), Value::Bool(following));
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
    println!("user getting profile avatar");
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
    println!("user geting posts from user");
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
    println!("user getting ratings from user");
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

#[derive(Deserialize)]
pub struct FollowUserBody {
    pub user_id : String,
    pub following: bool,
}    
#[derive(sqlx::FromRow)]
pub struct UserFollow { 
    pub follower: String,
    pub followee: String,
}

pub async fn post_user_follow(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<FollowUserBody>) -> (StatusCode, String) {
    println!("user following/unfollowing");
    let following_user_id: String = body.user_id;
    let following: bool = body.following;

    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };
    let database_pool = &app_state.database;

    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to fetch time");
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to fetch time".to_string());
        }
    }.as_millis();

    let follow_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(&following_user_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(err) => {
            println!("Not a valid user following ({})", err);
            return (StatusCode::NOT_FOUND, "Not a valid user being followed".to_string());
        },
    };

    if &follow_data.user_id == &user_id {
        return (StatusCode::CONFLICT, "you can not follow yourself".to_string());
    }

    let already_following: bool = match sqlx::query_as::<_, UserFollow>("SELECT * FROM user_follows WHERE follower = $1 AND followee = $2")
    .bind(&user_id)
    .bind(&following_user_id)
    .fetch_one(database_pool).await {
        Ok(_) => true,
        Err(err) => {
            match err {
                sqlx::Error::RowNotFound => false,
                _ => {
                    println!("Failed to fetch if following ({})", err);
                    return (StatusCode::NOT_FOUND, "Failed to fetch if following already".to_string());
                }
            }
        },
    };

    if following == true && already_following == true {
        return (StatusCode::CONFLICT, "Already following".to_string());
    }
    if following == false && already_following == false {
        return (StatusCode::NOT_FOUND, "Already not following".to_string());
    }

    if following == true {
        match sqlx::query(
            "INSERT INTO user_follows (follower, followee) VALUES ($1, $2)")
            .bind(&user_id)
            .bind(&following_user_id)
            .execute(database_pool).await {
                Ok(_) => return (StatusCode::OK, "Now following".to_string()),
                Err(err) => {
                    println!("Failed to follow ({})", err);
                    return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to follow".to_string());
                },
            }
    }else{
        match sqlx::query("DELETE FROM user_follows WHERE follower = $1 AND followee = $2")
        .bind(&user_id)
        .bind(&following_user_id)
        .execute(database_pool).await {
            Ok(_) => return (StatusCode::OK, "unfollowed".to_string()),
            Err(err) => {
                println!("Failed to unfollow ({})", err);
                return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to unfollow".to_string());
            },
        }
    }
}

//update settings

#[derive(Deserialize)]
pub struct UserSettingChange { 
    pub setting: String,
    pub value: String,
}

pub async fn post_setting_change(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<UserSettingChange>) -> (StatusCode, String) {
    println!("user changing setting");
    let setting_name: String = body.setting;
    let setting_value: String = body.value;
    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };
    let database_pool: &Pool<Postgres> = &app_state.database;

    if setting_name == "username" {
        let (username_valid, username_invalid_reason) = test_username(&setting_value);
        if username_valid == false{
            return (StatusCode::BAD_REQUEST, username_invalid_reason)
        }

        let database_response = sqlx::query("UPDATE user_data SET username = $1 WHERE user_id = $2")
        .bind(setting_value)
        .bind(&user_id)
        .execute(database_pool).await;

        match database_response {
            Ok(_) => {
                return (StatusCode::OK, "username updated".to_string())
            },
            Err(_) => {
                return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to update username".to_string())
            },
        };

    }else if setting_name == "bio" {
        let (bio_valid, bio_invalid_reason) = test_bio(&setting_value);
        if bio_valid == false{
            return (StatusCode::BAD_REQUEST, bio_invalid_reason)
        }

        let database_response = sqlx::query("UPDATE user_data SET bio = $1 WHERE user_id = $2")
        .bind(setting_value)
        .bind(&user_id)
        .execute(database_pool).await;

        match database_response {
            Ok(_) => {
                return (StatusCode::OK, "bio updated".to_string())
            },
            Err(_) => {
                return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to update bio".to_string())
            },
        };
    }else if setting_name == "avatar" {
        let avatar_id: String =  create_item_id();

        let image_data: Vec<u8> = match BASE64.decode(&setting_value.as_bytes()) {
            Ok(value) => value,
            Err(_) => return (StatusCode::BAD_REQUEST, "Image invalid".to_string()),
        };
    
        if image_data.len() > 1000000{  //around 1 migabytes
            return (StatusCode::OK, "avatar file size to large".to_string());
        }

        let user_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
        .bind(&user_id)
        .fetch_one(database_pool).await {
            Ok(value) => value,
            Err(err) => return (StatusCode::NOT_FOUND, "User not found".to_string() + &err.to_string()),
        };       

        //write the file to the disk
        let image_file_name = format!("{}.jpeg",&avatar_id);
        let file_path: PathBuf = DATA_IMAGE_AVATARS_FOLDER_PATH.join(image_file_name);
        let file_response = fs::write(&file_path, image_data);
        match file_response {
            Ok(_) => (),
            Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to save avatar image to disk".to_string()),
        }


        let database_response = sqlx::query("UPDATE user_data SET avatar_id = $1 WHERE user_id = $2")
        .bind(&avatar_id)
        .bind(&user_id)
        .execute(database_pool).await;

        match database_response {
            Ok(_) => {
                //delete old avatar
                match user_data.avatar_id {
                    Some(value) => {
                        let old_image_file_name = format!("{}.jpeg",&value);
                        let old_file_path: PathBuf = DATA_IMAGE_AVATARS_FOLDER_PATH.join(old_image_file_name);
                        let old_file_delete_response = fs::remove_file(&old_file_path);
                        match old_file_delete_response {
                            Ok(_) => (),
                            Err(err) => {
                                println!("failed to delete old avatar file {}",err);
                            },
                        }
                    },
                    None => (),
                }
                return (StatusCode::OK, "avatar updated".to_string())
            },
            Err(_) => {
                let _ = fs::remove_file(&file_path);
                return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to update avatar".to_string())
            },
        };
    }else if setting_name == "notify_on_new_post" {
        let new_value: bool = if setting_value == "true" {
            true
        }else if setting_value == "false" {
            false
        }else {
            return (StatusCode::BAD_REQUEST, "invalid value".to_owned());
        };

        let database_response = sqlx::query("UPDATE user_data SET notify_on_new_post = $1 WHERE user_id = $2")
        .bind(new_value)
        .bind(&user_id)
        .execute(database_pool).await;

        match database_response {
            Ok(_) => {
                return (StatusCode::OK, "setting updated".to_string())
            },
            Err(_) => {
                return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to update setting".to_string())
            },
        };
    }else{
        return (StatusCode::BAD_REQUEST, "Invalid setting to change".to_string())
    }
}

pub async fn get_settings(State(app_state): State<AppState<'_>>, headers: HeaderMap) -> (StatusCode, String) {
    println!("user getting settings");
    let database_pool: &Pool<Postgres> = &app_state.database;
    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
    let logged_in_user_id: Option<String> = match token {
        Ok(value) => Some(value.claims.user_id),
        Err(_) => None,
    };

    let user_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(logged_in_user_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "No user found".to_string()),
    };

    let mut settings_returning: HashMap<String, Value> = HashMap::new();

    settings_returning.insert("notify_on_new_post".to_string(), Value::Bool(user_data.notify_on_new_post));

    let value = match serde_json::to_string(&settings_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert setting data to json".to_string()),
    };

    (StatusCode::OK, value)
}