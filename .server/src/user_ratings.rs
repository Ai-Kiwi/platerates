use std::{collections::HashMap, time::{SystemTime, UNIX_EPOCH}};
use axum::{extract::{Query, State}, Json};
use hyper::{HeaderMap, StatusCode};
use serde::{de::value, Deserialize};
use serde_json::Value;
use sqlx::{Pool, Postgres};
use sqlx_error::{sqlx_error, SqlxError};

use crate::{notifications::{send_notification_to_user_id, NotificationType}, user_login::test_token_header, user_posts::Posts, utils::create_item_id, AppState};




#[derive(sqlx::FromRow)]
pub struct RatingsJustId { 
    pub rating_id: String, 
}

#[derive(Deserialize)]
pub struct GetRatingPaginator {
    rating_id: String,
}

#[derive(sqlx::FromRow)]
pub struct Ratings { 
    rating_id: String, 
    text: String,
    creation_date: i64, 
    rating : Option<f32>,
    rating_creator : String,
    parent_post_id : Option<String>,
    parent_rating_id : Option<String>,
}

pub async fn get_rating_data(pagination: Query<GetRatingPaginator>, headers: HeaderMap, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user getting rating data");
    let pagination: GetRatingPaginator = pagination.0;
    let token = test_token_header(&headers, &app_state).await;
    let user_id: Option<String> = match token {
        Ok(value) => Some(value.claims.user_id),
        Err(_) => None,
    };
    
    let mut data_returning: HashMap<String, Value> = HashMap::new();
    let database_pool: Pool<Postgres> = app_state.database;

    let rating_id: &String = &pagination.rating_id;

    let rating_data = match sqlx::query_as::<_, Ratings>("SELECT * FROM post_ratings WHERE rating_id = $1")
    .bind(rating_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "No post found".to_string()),
    };

    let _ = rating_data.rating_id; //purely to get rid of unused warning lmao

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


    let count_row: (i64,) = match sqlx::query_as(
        "SELECT COUNT(*) FROM post_ratings WHERE parent_rating_id = $1"
    )
    .bind(rating_id)
    .fetch_one(&database_pool)
    .await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to count child ratings");
            (-1,)
        },
    };

    let count_response: i64 = count_row.0;   
    data_returning.insert("childRatingsAmount".to_string(),Value::Number(count_response.into()));


    let row: (i64,) = match sqlx::query_as(
        "SELECT COUNT(*) FROM post_rating_likes WHERE rating_id = $1"
    )
    .bind(rating_id)
    .fetch_one(&database_pool)
    .await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to count rating likes");
            (-1,)
        },
    };

    let like_count = row.0;

    data_returning.insert("ratingLikes".to_string(),Value::Number(like_count.into()));

    let rating_liked: bool = match user_id {
        Some(safe_user_id) => {
            match sqlx::query_as::<_, RatingLike>("SELECT * FROM post_rating_likes WHERE rating_id = $1 AND liker = $2")
            .bind(&rating_id)
            .bind(&safe_user_id)
            .fetch_one(&database_pool).await {
                Ok(_) => true,
                Err(err) => {
                    match err {
                        sqlx::Error::RowNotFound => false,
                        _ => {
                            println!("Failed to fetch if rated liked ({})", err);
                            return (StatusCode::NOT_FOUND, "Failed to fetch rating liked".to_string());
                        }
                    }
                },
            }
        }
        None => false,
    };

    data_returning.insert("requesterLiked".to_string(),Value::Bool(rating_liked));
    data_returning.insert("creationDate".to_string(),Value::Number(rating_data.creation_date.into()));
    
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
    println!("user deleting rating");
    let token = test_token_header(&headers, &app_state).await;
    let database_pool = app_state.database;

    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };

    let rating_id = &pagination.rating_id;

    let rating_data = match sqlx::query_as::<_, Ratings>("SELECT * FROM post_ratings WHERE rating_id = $1")
    .bind(&rating_id)
    .fetch_one(&database_pool).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "No rating found".to_string()),
    };

    if rating_data.rating_creator != user_id {
        return (StatusCode::UNAUTHORIZED, "You do not own the post rating".to_string())
    }

    let database_response = sqlx::query("DELETE FROM post_ratings WHERE rating_id=$1")
    .bind(&rating_id)
    .execute(&database_pool).await;

    match database_response {
        Ok(_) => return (StatusCode::OK, "Rating deleted".to_string()),
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
    println!("user creating rating");
    let rating_id: String = create_item_id();
    let text: &String = &body.text;
    let root_type: &String = &body.root_type;
    let root_data: &String = &body.root_data;
    let rating: Option<f32> = body.rating;

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

    if text.len() > 500 {
        return (StatusCode::BAD_REQUEST, "rating text is to large".to_string());
    }


    if root_type == "post" {
        let parent_post_data: Posts = match sqlx::query_as::<_, Posts>("SELECT * FROM posts WHERE post_id = $1")
        .bind(&root_data)
        .fetch_one(database_pool).await {
            Ok(value) => value,
            Err(err) => {
                println!("Not a valid post rating ({})", err);
                return (StatusCode::NOT_FOUND, "Not a valid post being rated".to_string());
            },
        };

        if &parent_post_data.poster_user_id == &user_id {
            return (StatusCode::CONFLICT, "you can not rate your own post".to_string());
        }

        match sqlx::query_as::<_, Ratings>("SELECT * FROM post_ratings WHERE rating_creator = $1 AND parent_post_id = $2 ORDER BY creation_date DESC")
        .bind(&user_id)
        .bind(&root_data)
        .fetch_one(database_pool).await {
            Ok(_) => {
                return (StatusCode::CONFLICT, "you have already rated".to_string());
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
            .bind(&user_id)
            .bind(root_data)
            .execute(database_pool).await;

        match result {
            Ok(_) => {
                send_notification_to_user_id(&app_state,&user_id,&parent_post_data.poster_user_id, &rating_id, NotificationType::PostRated).await;
                return (StatusCode::CREATED, "Created rating".to_string())
            },
            Err(_) => {
                println!("failed to create rating");
                return (StatusCode::BAD_REQUEST, "Failed creating rating".to_string());
            }
        }


    }else if root_type == "rating" {
        let parent_rating_data = match sqlx::query_as::<_, Ratings>("SELECT * FROM post_ratings WHERE rating_id = $1")
        .bind(&root_data)
        .fetch_one(database_pool).await {
            Ok(value) => value,
            Err(err) => {
                println!("Not a valid rating commenting on ({})", err);
                return (StatusCode::NOT_FOUND, "Not a valid post being rated".to_string());
            },
        };

        match sqlx::query_as::<_, Ratings>("SELECT * FROM post_ratings WHERE rating_creator = $1 AND parent_rating_id = $2 ORDER BY creation_date DESC")
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
            .bind(&user_id)
            .bind(root_data)
            .execute(database_pool).await;

        match result {
            Ok(_) => {
                send_notification_to_user_id(&app_state,&user_id,&parent_rating_data.rating_creator, &rating_id, NotificationType::RatingComment).await;
                return (StatusCode::CREATED, "Created rating".to_string())
            },
            Err(err) => {
                println!("failed to create rating ({})",err);
                return (StatusCode::BAD_REQUEST, "Failed creating rating".to_string());
            }
        }

    }else{
        return (StatusCode::BAD_REQUEST, "Invalid parent rating item".to_string());
    }
}

#[derive(Deserialize)]
pub struct RatingLikeBody {
    rating_id : String,
    liking: bool,
}    

#[derive(sqlx::FromRow)]
pub struct RatingLike { 
    //rating_like_id: String, 
    rating_id: String,
    liker: String, 
}


pub async fn post_like_rating(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<RatingLikeBody>) -> (StatusCode, String) {
    println!("user liking post");
    let rating_id: String = body.rating_id;
    let liking: bool = body.liking;

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

    let rating_data: Ratings = match sqlx::query_as::<_, Ratings>("SELECT * FROM post_ratings WHERE rating_id = $1")
    .bind(&rating_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(err) => {
            println!("Not a valid post rating ({})", err);
            return (StatusCode::NOT_FOUND, "Not a valid post being rated".to_string());
        },
    };

    if &rating_data.rating_creator == &user_id {
        return (StatusCode::CONFLICT, "you can not like your own rating".to_string());
    }

    let already_liked: bool = match sqlx::query_as::<_, RatingLike>("SELECT * FROM post_rating_likes WHERE rating_id = $1 AND liker = $2")
    .bind(&rating_id)
    .bind(&user_id)
    .fetch_one(database_pool).await {
        Ok(_) => true,
        Err(err) => {
            match err {
                sqlx::Error::RowNotFound => false,
                _ => {
                    println!("Failed to fetch if rated ({})", err);
                    return (StatusCode::NOT_FOUND, "Failed to fetch if rated".to_string());
                }
            }
        },
    };

    if liking == true && already_liked == true {
        return (StatusCode::CONFLICT, "Already liked rating".to_string());
    }
    if liking == false && already_liked == false {
        return (StatusCode::NOT_FOUND, "Already not liked rating".to_string());
    }

    if liking == true {
        match sqlx::query(
            "INSERT INTO post_rating_likes (rating_id, liker, like_date) VALUES ($1, $2, $3)")
            .bind(&rating_id)
            .bind(&user_id)
            .bind(time_now_ms as i64)
            .execute(database_pool).await {
                Ok(_) => return (StatusCode::OK, "Like added to rating".to_string()),
                Err(err) => {
                    println!("Failed to add like to rating ({})", err);
                    return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to add like to rating".to_string());
                },
            }
    }else{
        match sqlx::query("DELETE FROM post_rating_likes WHERE rating_id = $1 AND liker = $2")
        .bind(&rating_id)
        .bind(&user_id)
        .execute(database_pool).await {
            Ok(_) => return (StatusCode::OK, "Like removed from rating".to_string()),
            Err(err) => {
                println!("Failed to add like to rating ({})", err);
                return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to remove like from rating".to_string());
            },
        }
    }
}