use std::{collections::HashMap, fs, path::PathBuf, time::{SystemTime, UNIX_EPOCH}};
use axum::{extract::{Query, State}, Json};
use data_encoding::BASE64;
use hyper::{HeaderMap, StatusCode};
use serde::Deserialize;
use serde_json::Value;
use sqlx::{Pool, Postgres};

use crate::{user_posts::GetPostRatingPaginator, user_profiles::UserData};
use crate::AppState;





#[derive(Deserialize)]
pub struct GetSearchUsersPaginator {
    pub text : String,
    pub page : String,
    pub page_size : String,
}

pub async fn get_search_users(pagination: Query<GetSearchUsersPaginator>, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {

    let pagination: GetSearchUsersPaginator = pagination.0;
    let database_pool = &app_state.database;
    let search_text: String = pagination.text;
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.page_size.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };
    
    let ratings_data: Vec<UserData> = match sqlx::query_as::<_, UserData>("SELECT *, username FROM user_data WHERE username LIKE $1 ORDER BY creation_date DESC LIMIT $2 OFFSET $3")
    .bind(format!("%{}%",search_text))
    .bind(page_size)
    .bind(page_number * page_size)
    .fetch_all(database_pool).await {
        Ok(value) => value,
        Err(err) => {
            println!("{}", err);
            return (StatusCode::NOT_FOUND, "Failed getting users".to_string());
        },
    };

    let mut post_returning: Vec<HashMap<&str, &str>> = vec!();

    for rating_item in &ratings_data {
        let user_id = &rating_item.user_id;

        post_returning.push(HashMap::from([
            ("type", "user"),
            ("data", &user_id),
        ]));
    }
    

    let value: String = match serde_json::to_string(&post_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert user data to json".to_string()),
    };

    (StatusCode::OK, value)
}