use std::{collections::HashMap, fs, path::PathBuf, time::{SystemTime, UNIX_EPOCH}};
use axum::{extract::{Query, State}, routing::{get, post}, Json, Router};
use data_encoding::BASE64;
use hyper::{HeaderMap, StatusCode};
use serde::Deserialize;
use serde_json::{json, Value};
use sqlx::{Pool, Postgres};

use crate::{user_login::test_token_header, user_ratings::ratings_just_id, utils::createItemId, AppState, DATA_IMAGE_POSTS_FOLDER_PATH};


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

#[derive(Deserialize)]
pub struct PostDeletePostPaginator {
    post_id: String,
}

pub async fn post_delete_post(pagination: Query<PostDeletePostPaginator>, State(app_state): State<AppState<'_>>, headers: HeaderMap) -> (StatusCode, String) {  //, Json(body): Json<UserLogin>)  just leaving for when I add logging out of 1 device
    let token = test_token_header(&headers, &app_state).await;
    let database_pool = app_state.database;

    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };

    let post_id = &pagination.post_id;

    let post_data = match sqlx::query_as::<_, posts>("SELECT * FROM posts WHERE post_id = $1")
    .bind(post_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(err) => return (StatusCode::NOT_FOUND, "No post found".to_string()),
    };

    if post_data.poster_user_id != user_id {
        return (StatusCode::UNAUTHORIZED, "You do not own the post".to_string())
    }

    let database_response = sqlx::query("DELETE FROM posts WHERE post_id=$1")
    .bind(&post_id)
    .execute(&database_pool).await;

    match database_response {
        Ok(value) => {
            let mut i = 0;

            //delete all the images added to the post
            while i < (post_data.image_count ) {
                let image_file_name = format!("{}-{}.jpeg",&post_id,i);
                
                let file_path: PathBuf = DATA_IMAGE_POSTS_FOLDER_PATH.join(image_file_name);
                match fs::remove_file(file_path){
                    Ok(value) => value,
                    Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to delete post image".to_string()),
                };
                i = i + 1;
            }

            return (StatusCode::OK, "Post deleted".to_string())
        },
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to delete post".to_string())
    }
}


#[derive(Deserialize)]
pub struct PostUpload {
    title : String,
    description : String,
    images : Vec<String>,
    //share_mode : String

}

pub async fn post_create_upload(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<PostUpload>) -> (StatusCode, String) {
    let post_id: String = createItemId(); //could be already used inthat case postgres errors, chance is like crazy low tho
    let post_title: &String = &body.title;
    let post_description: &String = &body.description;
    let images: &Vec<String> = &body.images;
    let image_count: usize = images.len();

    let token = test_token_header(&headers, &app_state).await;
    let user_id = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };
    let database_pool = &app_state.database;

    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(err) => {
            println!("failed to fetch time");
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to fetch time".to_string());
        }
    }.as_millis();

    if post_title.len() > 50 {
        return (StatusCode::BAD_REQUEST, "title is to large".to_string());
    }
    if post_title.len() < 5 {
        return (StatusCode::BAD_REQUEST, "title is to short".to_string());
    }

    if post_description.len() > 250 {
        return (StatusCode::BAD_REQUEST, "description is to large".to_string());
    }
    if post_description.len() < 5 {
        return (StatusCode::BAD_REQUEST, "description is to short".to_string());
    }

    if image_count > 8 {
        return (StatusCode::BAD_REQUEST, "To many images".to_string());
    }
    if image_count < 1 {
        return (StatusCode::BAD_REQUEST, "Image has to be added".to_string());
    }

    let mut images_data: Vec<Vec<u8>> = vec![];

    for image in images.iter() {
        let image_data: Vec<u8> = match BASE64.decode(image.as_bytes()) {
            Ok(value) => value,
            Err(_) => return (StatusCode::BAD_REQUEST, "Image invalid".to_string()),
        };

        if image_data.len() > 500000{//around 0.5 migabytes
            return (StatusCode::BAD_REQUEST, "Image to large".to_string());
        } 

        images_data.push(image_data);
    }


    //test when last post by user was make sure was awhile ago
    match sqlx::query_as::<_, posts>("SELECT * FROM posts WHERE poster_user_id = $1 ORDER BY post_date DESC")
    .bind(&user_id)
    .fetch_one(database_pool).await {
        Ok(value) => {
            println!("{}",value.title);
            if value.post_date > (time_now_ms as i64) - (20 * 1000){
                return (StatusCode::REQUEST_TIMEOUT, "Timed out for 20 seconds".to_string());
            }
        },
        Err(err) => {
            println!("failed to find post for timeout ({})", err)
        },
    };


    //add post to database
    let result = sqlx::query(
        "INSERT INTO posts (post_id, poster_user_id, title, description, image_count, post_date, rating, rating_count) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)")
        .bind(&post_id)
        .bind(&user_id)
        .bind(post_title)
        .bind(post_description)
        .bind(image_count as i32)
        .bind(time_now_ms as i64)
        .bind(0.0)
        .bind(0)
        .execute(database_pool).await;

    let mut image_upto = 0;
    for image in images_data.iter() {
        let image_file_name = format!("{}-{}.jpeg",&post_id,image_upto);
    
        let file_path: PathBuf = DATA_IMAGE_POSTS_FOLDER_PATH.join(image_file_name);

        let _ = fs::write(file_path, image);

        image_upto = image_upto + 1;
    }

    match result {
        Ok(_) => (StatusCode::CREATED,"Post created".to_owned()),
        Err(err) => {
            println!("failed to create post + ({})", err);
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to create post".to_owned());
        },
    }

}