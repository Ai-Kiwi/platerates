use std::{collections::HashMap, fs, path::PathBuf, time::{SystemTime, UNIX_EPOCH}};
use axum::{extract::{Query, State}, Json};
use data_encoding::BASE64;
use hyper::{HeaderMap, StatusCode};
use serde::{de::value, Deserialize};
use serde_json::Value;
use sqlx::{Pool, Postgres};

use crate::{notifications::{send_notification_to_user_id, NotificationType}, user_login::test_token_header, user_profiles::UserJustUserId, user_ratings::{Ratings, RatingsJustId}, utils::create_item_id, AppState, DATA_IMAGE_POSTS_FOLDER_PATH};


#[derive(sqlx::FromRow)]
pub struct PostsJustPostId { 
    pub post_id: String, 
}

#[derive(Deserialize)]
pub struct GetPostFeed {
    page : String,
    page_size : String,
}

pub async fn get_post_feed(pagination: Query<GetPostFeed>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user getting feed");
    let pagination: GetPostFeed = pagination.0;
    let database_pool: Pool<Postgres> = app_state.database;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.page_size.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };
    
    let posts_data: Vec<PostsJustPostId> = match sqlx::query_as::<_, PostsJustPostId>("SELECT post_id FROM posts ORDER BY post_date DESC LIMIT $1 OFFSET $2")
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
    post_id: String,
}

#[derive(sqlx::FromRow)]
pub struct Posts { 
    pub post_id: String, 
    pub poster_user_id: String,
    pub title: String, 
    pub description: String, 
    pub image_count: i32, 
    pub post_date: i64,
    pub recipe: Option<String>
    //pub rating: f32, 
    //pub rating_count: i32, 
}


pub async fn get_post_data(pagination: Query<GetPostPaginator>, State(app_state): State<AppState<'_>>, headers: HeaderMap) -> (StatusCode, String) {
    println!("user getting post data");
    let pagination: GetPostPaginator = pagination.0;
    let database_pool: &Pool<Postgres> = &app_state.database;
    let token = test_token_header(&headers, &app_state).await;
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();

    let post_id: &String = &pagination.post_id;

    let post_data = match sqlx::query_as::<_, Posts>("SELECT * FROM posts WHERE post_id = $1")
    .bind(post_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "No post found".to_string()),
    };

    data_returning.insert("title".to_string(), Value::String(post_data.title));
    data_returning.insert("description".to_string(), Value::String(post_data.description));
    data_returning.insert("postDate".to_string(), Value::Number(post_data.post_date.into()));
    match post_data.recipe {
        //pretty sure something else is meant to be used instead of match here lol
        Some(recipe) => {data_returning.insert("recipe".to_string(), Value::String(recipe)); ()},
        None => (),
    };
    


    let row: (i64,) = match sqlx::query_as(
        "SELECT COUNT(*) FROM post_ratings WHERE parent_post_id = $1"
    )
    .bind(&post_id)
    .fetch_one(database_pool)
    .await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to count post ratings");
            (-1,)
        },
    };

    let rating_count: i64 = row.0;

    data_returning.insert("ratingsAmount".to_string(), Value::Number(rating_count.into()));
    match token {
        Ok(value) => {
            let rated = match sqlx::query_as::<_, Ratings>("SELECT * FROM post_ratings WHERE rating_creator = $1 AND parent_post_id = $2 ORDER BY creation_date DESC")
            .bind(&value.claims.user_id)
            .bind(&post_id)
            .fetch_one(database_pool).await {
                Ok(_) => {
                    true
                    
                },
                Err(_) => {
                    false
                }
            };
            data_returning.insert("requesterRated".to_string(), Value::Bool(rated));
        }
        Err(_) => {
            data_returning.insert("requesterRated".to_string(), Value::Bool(false));
        },
    }
    data_returning.insert("postId".to_string(), Value::String(post_data.post_id));
    data_returning.insert("imageCount".to_string(), Value::Number(post_data.image_count.into()));
    data_returning.insert("posterId".to_string(), Value::String(post_data.poster_user_id));

    
    let row: Option<(f64,)> = match sqlx::query_as(
        "SELECT AVG(rating) FROM post_ratings WHERE parent_post_id = $1"
    )
    .bind(&post_id)
    .fetch_optional(database_pool)
    .await {
        Ok(value) => value,
        Err(_) => Some((-1.0,)),
    };
    
    
    let post_rating: f64 = match row {
        Some(value) => value.0,
        None => 0.0,
    };

    data_returning.insert("rating".to_string(), Value::String(post_rating.to_string()));


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
    post_id: String,
    image_number: String,
}

pub async fn get_post_image_data(pagination: Query<GetPostImagePaginator>) -> (StatusCode, String) {
    println!("user geting post image");
    let pagination: GetPostImagePaginator = pagination.0;
    let image_number: String = pagination.image_number;
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

    let post_id: String = pagination.post_id;
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
    page_size : String,
    post_id: Option<String>,
    rating_id: Option<String>,
}

pub async fn get_post_ratings(pagination: Query<GetPostRatingPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user getting post ratings");
    let pagination: GetPostRatingPaginator = pagination.0;
    let database_pool = app_state.database;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.page_size.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };

    let (parent_data, parent_type) = match pagination.post_id {
        Some(value) => {
            (value, "post".to_owned())
        },
        None => match pagination.rating_id {
            Some(value) => {
                (value, "rating".to_owned())
            },
            None => return (StatusCode::BAD_REQUEST, "no rating or post provided".to_owned()),
        }
    };

    //let post_id: String = match pagination.post_id.parse::<String>() {
    //    Ok(value) => value,
    //    Err(_) => return (StatusCode::BAD_REQUEST, "No user id added".to_string()),
    //};
    
    let ratings_data: Vec<RatingsJustId> = if parent_type == "post"{
        match sqlx::query_as::<_, RatingsJustId>("SELECT rating_id FROM post_ratings WHERE parent_post_id = $1 ORDER BY creation_date DESC LIMIT $2 OFFSET $3")
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
        match sqlx::query_as::<_, RatingsJustId>("SELECT rating_id FROM post_ratings WHERE parent_rating_id = $1 ORDER BY creation_date DESC LIMIT $2 OFFSET $3")
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
    println!("user deleting post");
    let token = test_token_header(&headers, &app_state).await;
    let database_pool = app_state.database;

    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };

    let post_id = &pagination.post_id;

    let post_data = match sqlx::query_as::<_, Posts>("SELECT * FROM posts WHERE post_id = $1")
    .bind(post_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "No post found".to_string()),
    };

    if post_data.poster_user_id != user_id {
        return (StatusCode::UNAUTHORIZED, "You do not own the post".to_string())
    }

    let database_response = sqlx::query("DELETE FROM posts WHERE post_id=$1")
    .bind(&post_id)
    .execute(&database_pool).await;

    match database_response {
        Ok(_) => {
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
    recipe : Option<String>,
    //share_mode : String
}

pub async fn post_create_upload(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<PostUpload>) -> (StatusCode, String) {
    println!("user uploading post");
    let post_id: String = create_item_id(); //could be already used inthat case postgres errors, chance is like crazy low tho
    let post_title: &String = &body.title;
    let post_description: &String = &body.description;
    let images: &Vec<String> = &body.images;
    let image_count: usize = images.len();
    let recipe: &Option<String> = &body.recipe;

    let token = test_token_header(&headers, &app_state).await;
    let user_id = match token {
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

    match recipe {
        Some(recipe) => if recipe.len() > 10000 {
            return (StatusCode::BAD_REQUEST, "recipe size to large".to_string());

        }
        None => (),
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
    match sqlx::query_as::<_, Posts>("SELECT * FROM posts WHERE poster_user_id = $1 ORDER BY post_date DESC")
    .bind(&user_id)
    .fetch_one(database_pool).await {
        Ok(value) => {
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
        "INSERT INTO posts (post_id, poster_user_id, title, description, image_count, post_date, recipe) VALUES ($1, $2, $3, $4, $5, $6, $7)")
        .bind(&post_id)
        .bind(&user_id)
        .bind(post_title)
        .bind(post_description)
        .bind(image_count as i32)
        .bind(time_now_ms as i64)
        .bind(recipe)
        .execute(database_pool).await;

    let mut image_upto = 0;
    for image in images_data.iter() {
        let image_file_name = format!("{}-{}.jpeg",&post_id,image_upto);
    
        let file_path: PathBuf = DATA_IMAGE_POSTS_FOLDER_PATH.join(image_file_name);

        let _ = fs::write(file_path, image);

        image_upto = image_upto + 1;
    }

    match sqlx::query_as::<_, UserJustUserId>("SELECT user_id FROM user_data WHERE notify_on_new_post = $1")
    .bind(true)
    .fetch_all(database_pool).await {
        Ok(value) => {
            for user in value.iter() {
                let _ = send_notification_to_user_id(&app_state,&user_id,&user.user_id, &post_id, NotificationType::AnyNewPost).await;
            }
        },
        Err(err) => {
            println!("failed to get users that want to be altered on new post {err}");
            ()
        },
    };






    match result {
        Ok(_) => (StatusCode::CREATED,"Post created".to_owned()),
        Err(err) => {
            println!("failed to create post + ({})", err);
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to create post".to_owned());
        },
    }

}