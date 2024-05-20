use std::{collections::HashMap, fs, path::PathBuf, time::{SystemTime, UNIX_EPOCH}};
use axum::{extract::{Query, State}, routing::get, Json, Router};
use data_encoding::BASE64;
use hyper::{HeaderMap, StatusCode};
use serde::{de::value, Deserialize};
use serde_json::{json, Number, Value};
use sqlx::{pool, Pool, Postgres};

use crate::{user_login::test_token_header, user_posts::posts, utils::createItemId, AppState};




#[derive(sqlx::FromRow)]
pub struct ratings_just_id { 
    pub rating_id: String, 
}

#[derive(Deserialize)]
pub struct GetRatingPaginator {
    ratingId: String,
}

#[derive(sqlx::FromRow)]
pub struct ratings { 
    rating_id: String, 
    text: String,
    creation_date: i64, 
    rating : Option<f32>,
    rating_creator : String,
    rating_like_count : i32,
    parent_post_id : Option<String>,
    parent_rating_id : Option<String>,
}

pub async fn get_rating_data(pagination: Query<GetRatingPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    let pagination: GetRatingPaginator = pagination.0;
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();
    let database_pool: Pool<Postgres> = app_state.database;

    let rating_id: &String = &pagination.ratingId;

    let rating_data = match sqlx::query_as::<_, ratings>("SELECT * FROM post_ratings WHERE rating_id = $1")
    .bind(rating_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(err) => return (StatusCode::NOT_FOUND, "No post found".to_string()),
    };

    match rating_data.rating {
        Some(value) => data_returning.insert("rating".to_string(),Value::String(value.to_string())),
        None => Some(Value::String("no value for rating".to_string())),
    };
    
    data_returning.insert("text".to_string(),Value::String(rating_data.text));
    data_returning.insert("ratingPosterId".to_string(),Value::String(rating_data.rating_creator));
    match rating_data.parent_post_id {
        Some(value) => {
            data_returning.insert("rootItemType".to_string(),Value::String("post".to_string()));
            data_returning.insert("rootItemData".to_string(),Value::String(value));
        },
        None => match rating_data.parent_rating_id {
            Some(value) => {
                data_returning.insert("rootItemType".to_string(),Value::String("rating".to_string()));
                data_returning.insert("rootItemData".to_string(),Value::String(value));
            },
            None => {
                println!("no parent post");
                return (StatusCode::INTERNAL_SERVER_ERROR, "no parent item".to_string())
            },
        },
    };

    let count_response = sqlx::query_scalar(r#"
    WITH RECURSIVE PostRatingsHierarchy AS (
        SELECT rating_id, parent_rating_id
        FROM post_ratings
        WHERE rating_id = $1

        UNION ALL

        SELECT pr.rating_id, pr.parent_rating_id
        FROM post_ratings pr
        INNER JOIN PostRatingsHierarchy ph ON pr.parent_rating_id = ph.rating_id
    )
    SELECT COUNT(*) AS total_children_posts
    FROM PostRatingsHierarchy;
    "#,)
    .bind(rating_id)
    .fetch_one(&database_pool).await;

    let count: i64 = match count_response {
        Ok(value) => value,
        Err(_) => {
            println!("failed to count child ratings");
            return (StatusCode::INTERNAL_SERVER_ERROR, "no children ratings".to_string())
        },
    };

    data_returning.insert("childRatingsAmount".to_string(),Value::Number(count.into()));
    data_returning.insert("ratingLikes".to_string(),Value::Number(rating_data.rating_like_count.into()));
    data_returning.insert("creationDate".to_string(),Value::Number(rating_data.creation_date.into()));

    data_returning.insert("requesterLiked".to_string(),Value::Bool(false));

    



    //requesterRated

    //{
    //    title : itemData[0].title,
    //    description : itemData[0].description,
    //    rating : itemData[0].rating,
    //    postDate : itemData[0].post_date,
    //    ratingsAmount : itemData[0].rating_count, // converts to string as client software pefers that
    //    requesterRated :`${requesterHasRated}`,
    //    postId : postId,
    //    imageCount : itemData[0].image_count,
    //    posterId : itemData[0].poster_user_id,
    //}    
    
    let value = match serde_json::to_string(&data_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert post data to json".to_string())
    };


    (StatusCode::OK, value)
}


#[derive(Deserialize)]
pub struct PostDeleteRatingPostPaginator {
    rating_id: String,
}

pub async fn post_delete_rating_post(pagination: Query<PostDeleteRatingPostPaginator>, State(app_state): State<AppState<'_>>, headers: HeaderMap) -> (StatusCode, String) {  //, Json(body): Json<UserLogin>)  just leaving for when I add logging out of 1 device
    let token = test_token_header(&headers, &app_state).await;
    let database_pool = app_state.database;

    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };

    let rating_id = &pagination.rating_id;

    let rating_data = match sqlx::query_as::<_, ratings>("SELECT * FROM post_ratings WHERE rating_id = $1")
    .bind(&rating_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(err) => return (StatusCode::NOT_FOUND, "No rating found".to_string()),
    };

    if rating_data.rating_creator != user_id {
        return (StatusCode::UNAUTHORIZED, "You do not own the post rating".to_string())
    }

    let database_response = sqlx::query("DELETE FROM post_ratings WHERE rating_id=$1")
    .bind(&rating_id)
    .execute(&database_pool).await;

    match database_response {
        Ok(value) => return (StatusCode::OK, "Rating deleted".to_string()),
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to delete rating".to_string())
    }

}


#[derive(Deserialize)]
pub struct RatingCreate {
    text : String,
    rating : Option<f32>,
    root_type : String,
    root_data : String

}             

pub async fn post_create_rating(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<RatingCreate>) -> (StatusCode, String) {
    let rating_id: String = createItemId();
    let text: &String = &body.text;
    let root_type: &String = &body.root_type;
    let root_data: &String = &body.root_data;
    let rating: Option<f32> = body.rating;

    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
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

    if text.len() > 500 {
        return (StatusCode::BAD_REQUEST, "text is to large".to_string());
    }
    if text.len() < 5 {
        return (StatusCode::BAD_REQUEST, "text is to short".to_string());
    }


    if root_type == "post" {
        match sqlx::query_as::<_, posts>("SELECT * FROM posts WHERE post_id = $1")
        .bind(&root_data)
        .fetch_one(database_pool).await {
            Ok(_) => (),
            Err(err) => {
                println!("Not a valid post rating ({})", err);
                return (StatusCode::NOT_FOUND, "Not a valid post being rated".to_string());
            },
        };

        match sqlx::query_as::<_, ratings>("SELECT * FROM post_ratings WHERE rating_creator = $1 AND parent_post_id = $2 ORDER BY creation_date DESC")
        .bind(&user_id)
        .bind(&root_data)
        .fetch_one(database_pool).await {
            Ok(value) => {
                return (StatusCode::CONFLICT, "Already posted".to_string());
                
            },
            Err(err) => {
                println!("not already posted ({})", err)
            }
        };

        let valid_rating: f32 = match rating {
            Some(value) => value,
            None => return (StatusCode::BAD_REQUEST, "No rating was added".to_string())
        };
        if valid_rating < 0.0 || valid_rating > 5.0 {
            return (StatusCode::BAD_REQUEST, "invalid rating".to_string());
        }

        

        let result = sqlx::query(
            "INSERT INTO post_ratings (rating_id, text, creation_date, rating, rating_creator, parent_post_id) VALUES ($1, $2, $3, $4, $5, $6)")
            .bind(&rating_id)
            .bind(&text)
            .bind(time_now_ms as i64)
            .bind(rating)
            .bind(user_id)
            .bind(root_data)
            .execute(database_pool).await;

        match result {
            Ok(_) => return (StatusCode::CREATED, "Created rating".to_string()),
            Err(_) => {
                println!("failed to create rating");
                return (StatusCode::BAD_REQUEST, "Failed creating rating".to_string());
            }
        }


    }else if root_type == "rating" {
        match sqlx::query_as::<_, ratings>("SELECT * FROM post_ratings WHERE rating_id = $1")
        .bind(&root_data)
        .fetch_one(database_pool).await {
            Ok(_) => (),
            Err(err) => {
                println!("Not a valid rating commenting on ({})", err);
                return (StatusCode::NOT_FOUND, "Not a valid post being rated".to_string());
            },
        };

        match sqlx::query_as::<_, ratings>("SELECT * FROM post_ratings WHERE rating_creator = $1 AND parent_rating_id = $2 ORDER BY creation_date DESC")
        .bind(&user_id)
        .bind(&root_data)
        .fetch_one(database_pool).await {
            Ok(value) => {
                if value.creation_date - (20 * 1000) > (time_now_ms as i64) {
                    return (StatusCode::REQUEST_TIMEOUT, "Please wait abit before commenting again".to_string());
                }
            },
            Err(err) => {
                println!("not already posted ({})", err)
            }
        };

        let result = sqlx::query(
            "INSERT INTO post_ratings (rating_id, text, creation_date, rating_creator, parent_rating_id) VALUES ($1, $2, $3, $4, $5)")
            .bind(&rating_id)
            .bind(&text)
            .bind(time_now_ms as i64)
            .bind(user_id)
            .bind(root_data)
            .execute(database_pool).await;

        match result {
            Ok(_) => return (StatusCode::CREATED, "Created rating".to_string()),
            Err(err) => {
                println!("failed to create rating ({})",err);
                return (StatusCode::BAD_REQUEST, "Failed creating rating".to_string());
            }
        }

    }else{
        return (StatusCode::BAD_REQUEST, "Invalid parent rating item".to_string());
    }
    (StatusCode::INTERNAL_SERVER_ERROR,"Not finished coding yet".to_owned())
}