use std::fmt::Error;

use std::{collections::HashMap, time::{SystemTime, UNIX_EPOCH}};
use axum::{extract::{Query, State}, Json};
use hyper::{HeaderMap, StatusCode};
use serde::{de::value, Deserialize};
use sqlx::{Pool, Postgres};

use crate::{user_login::test_token_header, user_profiles::UserData, AppState};


pub async fn test_user_admin(state: &AppState<'_>, user_id : &String) -> Result<bool, ()> {
    let database_pool: &Pool<Postgres> = &state.database;

    let user_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to send notification, user id doesn't exist");
            return Err(());
        },
    };

    let admin: bool = user_data.administrator;
    Ok(admin)
}

#[derive(Deserialize)]
pub struct BanUser {
    user_id : String,
    reason : String,
    time : i64,
}

pub async fn post_ban_user(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<BanUser>) -> (StatusCode, String) {
    let token = test_token_header(&headers, &app_state).await;
    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };

    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to fetch time");
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to fetch time".to_string());
        }
    }.as_millis();
    let ban_time: i64 = body.time;
    let ban_reason: String = body.reason;
    let ban_user_id: String = body.user_id;

    let database_pool = &app_state.database;

    match test_user_admin(&app_state,&user_id).await {
        Ok(value) => {
            if value == false {
                return (StatusCode::UNAUTHORIZED, "Not admin user".to_string())
            }else{
                ()
            }
        },
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to test if user admin".to_string()),
    };

    let response = sqlx::query("UPDATE user_credentials SET tokens_expire_time = $1, ban_date = $2, ban_expire_date = $3, ban_reason = $4 WHERE user_id = $5")
    .bind(time_now_ms as i64)
    .bind(time_now_ms as i64)
    .bind((time_now_ms as i64) + ban_time)
    .bind(&ban_reason)
    .bind(&ban_user_id)
    .execute(database_pool).await;

    match response {
        Ok(_) => {
            return (StatusCode::OK, "Banned user".to_string())
        }
        Err(_) => {
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to ban user".to_string())
        }
    }
}
