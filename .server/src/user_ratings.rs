use std::{collections::HashMap, fs, path::PathBuf};
use axum::{extract::{Query, State}, routing::get, Router};
use data_encoding::BASE64;
use hyper::StatusCode;
use serde::{de::value, Deserialize};
use serde_json::{json, Number, Value};
use sqlx::{pool, Pool, Postgres};

use crate::AppState;




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