use std::{collections::HashMap, fs, path::PathBuf, time::{Duration, SystemTime, UNIX_EPOCH}};
use axum::{extract::{Query, State}, Json};
use data_encoding::BASE64;
use hyper::{HeaderMap, StatusCode};
use lettre::{message::Mailbox, Message, Transport};
use serde::Deserialize;
use serde_json::Value;
use sqlx::{Pool, Postgres};
use crate::{user_login::test_token_header, user_profiles::UserData, utils::create_item_id, AppState};

#[derive(sqlx::FromRow)]
pub struct UserReport { 
    pub report_id: String,
    pub report_text: String,
    pub report_item_type: String,
    pub report_item_id: String,
    pub reporter_id: String,
    pub report_date: i64
}

#[derive(Deserialize)]
pub struct UserReportItem {
    pub item_type: String,
    pub item_id: String,
    pub reason: String,
}

pub async fn post_report(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<UserReportItem>) -> (StatusCode, String) {
    println!("user reporting item");
    let report_id: String = create_item_id();
    let item_type_resporting: String = body.item_type;
    let item_id_reporting: String = body.item_id;
    let report_reason: String = body.reason;
    let emailer = &app_state.mailer;
    
    let token = test_token_header(&headers, &app_state).await;
    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };

    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to get time for 500ms timeout");
            Duration::from_millis(0)
        }
    }.as_millis();

    let database_pool: &Pool<Postgres> = &app_state.database;

    if item_type_resporting != "post" && item_type_resporting != "post_rating" {
        return (StatusCode::BAD_REQUEST, "Bad item reporting".to_string())
    }

    match sqlx::query_as::<_, UserReport>("SELECT * FROM reports WHERE report_item_type = $1 AND report_item_id = $2 AND reporter_id = $3")
    .bind(&item_type_resporting)
    .bind(&item_id_reporting)
    .bind(&user_id)
    .fetch_one(database_pool).await {
        Ok(_) => return (StatusCode::BAD_REQUEST, "item already reported".to_string()),
        Err(_) => {
            ()
        }
    };


    //look if item already exists
    let result = sqlx::query(
    "INSERT INTO reports ( report_id, report_text, report_item_type, report_item_id, reporter_id, report_date) VALUES ($1, $2, $3, $4, $5, $6)")
    .bind(&report_id)
    .bind(&report_reason)
    .bind(&item_type_resporting)
    .bind(&item_id_reporting)
    .bind(&user_id)
    .bind(time_now_ms as i64)
    .execute(database_pool).await;

    match result {
        Ok(_) => {
            let email_body: String = format!(r#"New item has been reported on platerates
item id : {}
type id : {}
reason : {}"#,&item_id_reporting,&item_type_resporting,&report_reason);

            let email_message = Message::builder()
            .from("no-reply platerates <reports@noreply.platerates.com>".parse().unwrap())
            .to("support@platerates.com".parse().unwrap())
            .subject("New item reported on platerates")
            .body(email_body);
    
            match email_message {
              Ok(value) => match emailer.send(&value) {
                  Ok(_) => println!("sent email about report"),
                  Err(_) => println!("failed to send email about report"),
              }
              Err(_) => println!("failed to make email about report"),
            };
            
            return (StatusCode::OK, "item reported".to_string())
        },
        Err(err) => {
            println!("post report failed ({})", err);
            return (StatusCode::INTERNAL_SERVER_ERROR, "failed to report post".to_string())
        },
    }
}