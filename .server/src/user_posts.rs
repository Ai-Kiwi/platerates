use std::{collections::HashMap, fs, path::PathBuf};
use axum::{extract::{Query, State}, routing::get, Router};
use data_encoding::BASE64;
use hyper::StatusCode;
use serde::Deserialize;
use serde_json::{json, Value};
use sqlx::{Pool, Postgres};

use crate::{user_ratings::ratings_just_id, AppState, DATA_IMAGE_POSTS_FOLDER_PATH};


#[derive(sqlx::FromRow)]
pub struct posts_just_post_id { 
    pub post_id: String, 
}

#[derive(Deserialize)]
pub struct GetPostFeed {
    page : String,
    pageSize : String,
}

pub async fn get_post_feed(pagination: Query<GetPostFeed>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    let pagination: GetPostFeed = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.pageSize.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };
    
    let posts_data: Vec<posts_just_post_id> = match sqlx::query_as::<_, posts_just_post_id>("SELECT post_id FROM posts ORDER BY post_date DESC LIMIT $1 OFFSET $2")
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
pub struct GetPostPaginator {
    postId: String,
}

#[derive(sqlx::FromRow)]
pub struct posts { 
    post_id: String, 
    poster_user_id: String,
    title: String, 
    description: String, 
    image_count: i32, 
    post_date: i64,
    rating: f32, 
    rating_count: i32, 
}


pub async fn get_post_data(pagination: Query<GetPostPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    let pagination: GetPostPaginator = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let post_id: &String = &pagination.postId;

    let post_data = match sqlx::query_as::<_, posts>("SELECT * FROM posts WHERE post_id = $1")
    .bind(post_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(err) => return (StatusCode::NOT_FOUND, "No post found".to_string()),
    };

    data_returning.insert("title".to_string(), Value::String(post_data.title));
    data_returning.insert("description".to_string(), Value::String(post_data.description));
    data_returning.insert("postDate".to_string(), Value::Number(post_data.post_date.into()));
    data_returning.insert("ratingsAmount".to_string(), Value::Number(post_data.rating_count.into()));
    data_returning.insert("requesterRated".to_string(), Value::Bool(false));
    data_returning.insert("postId".to_string(), Value::String(post_data.post_id));
    data_returning.insert("imageCount".to_string(), Value::Number(post_data.image_count.into()));
    data_returning.insert("posterId".to_string(), Value::String(post_data.poster_user_id));
    data_returning.insert("rating".to_string(), Value::String(post_data.rating.to_string()));


    let mut relative_viewer_data: HashMap<String, Value> = HashMap::new();
    relative_viewer_data.insert("following".to_string(), Value::Bool(false));

    
    let value = match serde_json::to_string(&data_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert post data to json".to_string())
    };


    (StatusCode::OK, value)
}


#[derive(Deserialize)]
pub struct GetPostImagePaginator {
    postId: String,
    imageNumber: String,
}

pub async fn get_post_image_data(pagination: Query<GetPostImagePaginator>) -> (StatusCode, String) {
    let pagination: GetPostImagePaginator = pagination.0;
    let image_number: String = pagination.imageNumber;
    //println!("{}", image_number);

    if image_number.contains(".") {
        return (StatusCode::BAD_REQUEST, "image number contains invalid char".to_string());
    }
    if image_number.contains("/") {
        return (StatusCode::BAD_REQUEST, "image number contains invalid char".to_string());
    }
    if image_number.contains("-") {
        return (StatusCode::BAD_REQUEST, "image number contains invalid char".to_string());
    }

    let post_id: String = pagination.postId;
    if post_id.contains(".") {
        return (StatusCode::BAD_REQUEST, "post id contains invalid char".to_string());
    }
    if post_id.contains("/") {
        return (StatusCode::BAD_REQUEST, "post id contains invalid char".to_string());
    }
    if post_id.contains("-") {
        return (StatusCode::BAD_REQUEST, "post id contains invalid char".to_string());
    }

    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let image_file_name = format!("{}-{}.jpeg",post_id,image_number);
    
    let file_path: PathBuf = DATA_IMAGE_POSTS_FOLDER_PATH.join(image_file_name);
    let image_data: Vec<u8> = match fs::read(file_path){
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "post image file not found".to_string()),
    };

    let base64_image_value: String = BASE64.encode(&image_data);


    data_returning.insert("imageData".to_string(), Value::String(base64_image_value));


    //make sure non contain dashs or slashs or dots

    //let current_path = env::current_dir().unwrap();

    let value = match serde_json::to_string(&data_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert post image data to json".to_string())
    };


    return (StatusCode::OK, value);
}

#[derive(Deserialize)]
pub struct GetPostRatingPaginator {
    page : String,
    pageSize : String,
    post_id: Option<String>,
    rating_id: Option<String>,
}

pub async fn get_post_ratings(pagination: Query<GetPostRatingPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {

    let pagination: GetPostRatingPaginator = pagination.0;
    let database_pool = app_state.database;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.pageSize.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };

    let mut parent_type = "".to_string();

    let parent_data = match pagination.post_id {
        Some(value) => {
            parent_type = "post".to_owned();
            value
        },
        None => match pagination.rating_id {
            Some(value) => {
                parent_type = "rating".to_owned();
                value
            },
            None => return (StatusCode::BAD_REQUEST, "no rating or post provided".to_owned()),
        }
    };

    //let post_id: String = match pagination.post_id.parse::<String>() {
    //    Ok(value) => value,
    //    Err(_) => return (StatusCode::BAD_REQUEST, "No user id added".to_string()),
    //};
    
    let ratings_data: Vec<ratings_just_id> = if parent_type == "post"{
        match sqlx::query_as::<_, ratings_just_id>("SELECT rating_id FROM post_ratings WHERE parent_post_id = $1 ORDER BY creation_date DESC LIMIT $2 OFFSET $3")
        .bind(parent_data)
        .bind(page_size)
        .bind(page_number * page_size)
        .fetch_all(&database_pool).await {
            Ok(value) => value,
            Err(err) => {
                println!("{}", err);
                return (StatusCode::NOT_FOUND, "Failed getting posts".to_string());
            },
        }
    }else{
        match sqlx::query_as::<_, ratings_just_id>("SELECT rating_id FROM post_ratings WHERE parent_rating_id = $1 ORDER BY creation_date DESC LIMIT $2 OFFSET $3")
        .bind(parent_data)
        .bind(page_size)
        .bind(page_number * page_size)
        .fetch_all(&database_pool).await {
            Ok(value) => value,
            Err(err) => {
                println!("{}", err);
                return (StatusCode::NOT_FOUND, "Failed getting posts".to_string());
            },
        }
    };
    
    
    

    let mut post_returning: Vec<HashMap<&str, &str>> = vec!();

    for rating_item in &ratings_data {
        let rating_id = &rating_item.rating_id;

        post_returning.push(HashMap::from([
            ("type", "rating"),
            ("data", &rating_id),
        ]));
    }
    

    let value = match serde_json::to_string(&post_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert post data to json".to_string()),
    };

    (StatusCode::OK, value)
}