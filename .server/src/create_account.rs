use std::{collections::HashMap, fs, path::PathBuf, time::{SystemTime, UNIX_EPOCH}};
use argon2::Argon2;
use axum::{extract::{Query, State}, http::Error, response::Html, Json};
use data_encoding::BASE64;
use hyper::{header, HeaderMap, StatusCode};
use argon2::password_hash::{
    rand_core::OsRng, PasswordHasher, SaltString
};
use lettre::{message::{header::ContentType, Mailbox}, Message, Transport};
use serde::{de::value, Deserialize};
use serde_json::Value;
use sqlx::{Pool, Postgres};

use crate::{user_login::UserCredentials, user_profiles::UserData, utils::{create_create_account_code, create_item_id}, AppState};

#[derive(Deserialize)]
pub struct CreateAccount {
    pub username: String, 
    pub email: String,
    pub password: String,
}

pub async fn post_create_account((app_state): State<AppState<'_>>, Json(body): Json<CreateAccount>) -> (StatusCode, String) {
    println!("user creating account");
    let user_password: &String = &body.password;
    let user_password_bytes: &[u8] = user_password.as_bytes();
    let salt = SaltString::generate(&mut OsRng);
    let database_pool: &Pool<Postgres> = &app_state.database;
    let argon2: &Argon2 = &app_state.argon2;
    let request_code = create_create_account_code();
    let username: &String = &body.username;
    let email: &String = &body.email;
    let emailer = &app_state.mailer;


    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to fetch time");
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to fetch time".to_string());
        }
    }.as_millis();


    let custom_password: Result<argon2::PasswordHash, password_hash::Error> = argon2.hash_password(&user_password_bytes, &salt);
    let user_password_hashed: String = match custom_password {
        Ok(value) => value.to_string(),
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR,"Failed to process password".to_string()),
    }; 

    //test if username already in use
    match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE username = $1")
    .bind(&username)
    .fetch_one(database_pool).await {
        Ok(_) => return (StatusCode::CONFLICT,"Someone already has account with that username".to_string()),
        Err(_) => {()},
    };

    //test if email already in use
    match sqlx::query_as::<_, UserCredentials>("SELECT * FROM user_credentials WHERE email = $1")
    .bind(&email)
    .fetch_one(database_pool).await {
        Ok(_) => return (StatusCode::CONFLICT,"Someone already has account with that email".to_string()),
        Err(_) => {()},
    };

    //test if email already attempted to make account
    match sqlx::query_as::<_, AccountCreateRequests>("SELECT * FROM account_create_requests WHERE email = $1 AND creation_date > $2")
    .bind(&email)
    .bind(time_now_ms as i64 - (1000 * 60 * 60))
    .fetch_one(database_pool).await {
        Ok(_) => return (StatusCode::CONFLICT,"Old code present that is yet to expire".to_string()),
        Err(err) => {()},
    };

    let result = sqlx::query(
    "INSERT INTO account_create_requests (request_code, username, email, password, creation_date) VALUES ($1, $2, $3, $4, $5)")
    .bind(&request_code)
    .bind(&username)
    .bind(&email)
    .bind(&user_password_hashed)
    .bind(time_now_ms as i64)
    .execute(database_pool).await;

    match result {
        Ok(_) => {
            //send the email to them
            let email_html: String = format!(r#"
          <!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PlateRates: Activate Your Account</title>
  <style>
    body {{
      font-family: sans-serif;
      margin: 0;
      padding: 0;
    }}
    .container {{
      padding: 20px;
      max-width: 600px;
      margin: 0 auto;
      background-color: #f5f5f5;
    }}
    .header {{
      text-align: center;
    }}
    .logo {{
      height: 50px; /* Adjust height as needed for your logo */
      width: 50px;  /* Adjust width as needed for your logo */
    }}
    .content {{
      padding: 20px;
      text-align: left;
    }}
    .reset-button {{
      text-align: center;
      padding: 10px 20px;
      background-color: #3498db;
      color: white;
      font-weight: bold;
      border: none;
      border-radius: 5px;
      cursor: pointer;
      display: block;
      margin: 20px auto;
      width: 200px;
    }}
    .footer {{
      text-align: center;
      font-size: 12px;
      padding: 10px;
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <img src="https://aikiwi.dev/platerates-logo.svg" alt="platerates Logo" class="logo">
    </div>
    <div class="content">
      <p>Hi there,</p>
      <p>Welcome to PlateRates! We're excited to have you on board.</p>
      <p>Please click the button below to activate your account and start exploring all the features we have to offer.</p>
      <p>**If you did not create an account with us, please ignore this email.**</p>
      <a href="https://platerates.com/create-account?code={}" class="reset-button">Activate Account</a>
      <p>This link will expire in 1 hours for your security.</p>
      <p>If you need any assistance, feel free to contact our support team.</p>
    </div>
    <div class="footer">
      <p>Having trouble? Contact us at <a href="mailto:support@platerates.com">support@platerates.com</a></p>
      <p>The platerates Team</p>
    </div>
  </div>
</body>
</html>"#,&request_code);

            let email_receiving: Mailbox = match email.parse() {
              Ok(value) => value,
              Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to send email, possible invalid input".to_owned()),
            };
          
            let email_message = Message::builder()
            .from("no-reply platerates <accounts@noreply.platerates.com>".parse().unwrap())
            .to(email_receiving)
            .subject("Account creation for platerates")
            .header(ContentType::TEXT_HTML)
            .body(email_html);
          
            match email_message {
              Ok(value) => match emailer.send(&value) {
                  Ok(_) => return (StatusCode::OK,"Account activation code has been sent and emailed.\nCheck your emails".to_string()),
                  Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to send email".to_owned()),
              }
              Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "Failed to send email, invalid".to_owned()),
            }
        },
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR,"Failed to create account code".to_string()),
    }
}

fn create_error_html(error: String) -> String {
    return format!(r#"<!DOCTYPE html>
<html lang="en">
<head>
  <title>PlateRates: Account Creation</title>
  <style>
    body {{
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background-color: #2196F3;
    }}
    .container {{
      max-width: 400px;
      padding: 30px;
      border-radius: 10px;
      background-color: #fff;
      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
      text-align: center;
    }}
    h1 {{
      color: #e74c3c; /* Red color */
      font-size: 24px;
    }}
    .message {{
      font-size: 18px;
      margin-top: 20px;
    }}
    .icon {{
      font-size: 48px;
      color: #e74c3c; /* Red color */
    }}
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">❌</div>
    <h1>Account Creation Failed</h1>
    <div class="message">Failed to create your user account.<br>
    {}</div>
  </div>
</body>
</html>"#,error).to_string();
}

fn create_success_html() -> String {
 return r#"
 <!DOCTYPE html>
<html lang="en">
<head>
  <title>PlateRates: Account Creation</title>
  <style>
    body {
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      background-color: #2196F3;
    }
    .container {
      max-width: 400px;
      padding: 30px;
      border-radius: 10px;
      background-color: #fff;
      box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
      text-align: center;
    }
    h1 {
      color: #27ae60; /* Green color */
      font-size: 24px;
    }
    .message {
      font-size: 18px;
      margin-top: 20px;
    }
    .icon {
      font-size: 48px;
      color: #27ae60; /* Green color */
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">✔️</div>
    <h1>Account Created</h1>
    <div class="message">Your user account has been created successfully.</div>
  </div>
</body>
</html>"#.to_string();
}

#[derive(sqlx::FromRow)]
pub struct AccountCreateRequests { 
    pub request_code: String,
    pub username: String,
    pub email: String,
    pub password: String,
    pub creation_date: i64
}

#[derive(Deserialize)]
pub struct ActivateAccountCodePaginator {
    code : String,
}

pub async fn get_use_create_account_code(pagination: Query<ActivateAccountCodePaginator>, State(app_state): State<AppState<'_>>) -> Html<String> {
  println!("user using create account code");
    let database_pool: &Pool<Postgres> = &app_state.database;
    let pagination: ActivateAccountCodePaginator = pagination.0;
    let account_create_code: String = pagination.code;

    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to fetch time");
            return axum::response::Html(create_error_html("Failed to load time".to_string()))
        }
    }.as_millis();

    let create_account_info: AccountCreateRequests = match sqlx::query_as::<_, AccountCreateRequests>("SELECT * FROM account_create_requests WHERE request_code = $1")
    .bind(&account_create_code)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(_) => return axum::response::Html(create_error_html("Invalid code".to_string())),
    };

    //test if username already in use
    match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE username = $1")
    .bind(&create_account_info.username)
    .fetch_one(database_pool).await {
        Ok(_) => return axum::response::Html(create_error_html("Username already in use".to_string())),
        Err(_) => {()},
    };

    //test if email already in use
    match sqlx::query_as::<_, UserCredentials>("SELECT * FROM user_credentials WHERE email = $1")
    .bind(&create_account_info.email)
    .fetch_one(database_pool).await {
        Ok(_) => return axum::response::Html(create_error_html("Email already in use".to_string())),
        Err(_) => {()},
    };

    if create_account_info.creation_date < (time_now_ms as i64 ) - 60 * 60 * 1000 { //1 hour
        return axum::response::Html(create_error_html("Code is expired".to_string()))
    }

    let user_id = create_item_id();
    let none_value: Option<&str> = None;

    //create account
    let user_data_result = sqlx::query(
      "INSERT INTO user_data (user_id, username, bio, avatar_id, administrator, creation_date) VALUES ($1, $2, $3, $4, $5, $6)")
      .bind(&user_id)
      .bind(&create_account_info.username)
      .bind("".to_string())
      .bind(&none_value)
      .bind(false)
      .bind(time_now_ms as i64)
      .execute(database_pool).await;

    match user_data_result {
        Ok(_) => (),
        Err(_) => return axum::response::Html(create_error_html("Failed creating user".to_string())),
    }

    //don't really need to bother checking as it will fail if prevous item failed
    let user_credentials_result = sqlx::query(
      "INSERT INTO user_credentials (user_id, email, hashed_password, notification_token, password_reset_code) VALUES ($1, $2, $3, $4, $5)")
      .bind(&user_id)
      .bind(&create_account_info.email)
      .bind(&create_account_info.password)
      .bind(&none_value)
      .bind(&none_value)
      .execute(database_pool).await;
    
    match user_credentials_result {
      Ok(_) => (),
      Err(_) => {
        match sqlx::query("DELETE FROM user_data WHERE user_id = $1")
        .bind(&user_id)
        .execute(database_pool).await {
            Ok(_) => (),
            Err(err) => {
                println!("Failed to remove user data after creating account ({})", err);
            },
        }
        return axum::response::Html(create_error_html("Failed creating user".to_string()))
    },
    }

    return axum::response::Html(create_success_html());
}