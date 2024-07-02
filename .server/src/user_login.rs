//jwt make sure I do veirfy as well

use std::{collections::HashMap, thread, time::{Duration, SystemTime, UNIX_EPOCH}};
//test token
//
use argon2::{
    password_hash::{
        PasswordHash, PasswordVerifier
    },
    Argon2
};
use axum::{extract::State, Json};
use hyper::{HeaderMap, StatusCode};
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, TokenData, Validation};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::{postgres::Postgres, Pool};
use crate::{notifications::{send_notification_to_user_id, NotificationType}, utils::milliseconds_to_readable_short, AppState};

#[derive(Deserialize)]
pub struct UserLogin {
    email: String,
    password: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct JwtClaims {
    pub user_id: String,
    pub last_reset_password_time: u64,
    pub exp: usize,
    pub creation_date: u128,
}

#[derive(sqlx::FromRow)]
pub struct UserCredentials { 
    pub user_id: String,
    pub email: String,
    pub hashed_password: String,
    pub password_reset_time: i64,
    pub last_login_attempt_time: i64,
    pub login_attempt_number: i32,
    pub notification_token: Option<String>,
    pub invalid_tokens: Vec<String>,
    pub tokens_expire_time: i64,
    pub password_reset_code: Option<String>,
    pub ban_date: i64,
    pub ban_expire_date: i64,
    pub ban_reason: String
}

fn wait_time(start_time: u128) {
    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to get time for 500ms timeout");
            Duration::from_millis(0)
        }
    }.as_millis();

    if (start_time + 500) < time_now_ms {
        println!("danger it has taken more then 500ms to test login");
        return;
    }else{
        let time_to_wait: u64 = match ((start_time + 500) - time_now_ms).try_into() {
            Ok(value) => value,
            Err(_) => {
                println!("failed to convert final wait time to u64");
                0
            },
        };

        thread::sleep(Duration::from_millis(time_to_wait));
        return;
    }
}


pub async fn test_token(token : &String, state: &AppState<'_>) -> Result<TokenData<JwtClaims>,()> {
    let decode_key: &DecodingKey = &state.jwt_decode_key;
    let sqlx_pool: &Pool<Postgres> = &state.database;


    let jwt_token: TokenData<JwtClaims> = match decode::<JwtClaims>(token, &decode_key, &Validation::new(Algorithm::HS512)){
        Ok(value) => value,
        Err(_) => {
            //println!("token invalid ({})",err);
            return Err(())
        },
    };

    //this should later be changed to only be for refresh tokens when I get around to adding them

    let user_id: &String = &jwt_token.claims.user_id;

    let user_credential_data: UserCredentials = match sqlx::query_as::<_, UserCredentials>("SELECT * FROM user_credentials WHERE user_id = $1")
    .bind(&user_id)
    .fetch_one(&*sqlx_pool).await {
        Ok(value) => value,
        Err(_) => {
            //println!("{} ({err})","didn't find a valid user assigned to token".to_owned());
            return Err(())
        },
    };

    //test if all tokens have been expired since then
    if user_credential_data.tokens_expire_time > jwt_token.claims.creation_date as i64 {
        //println!("all token since creation expired");
        return Err(())
    }

    //test if token is in list of manuelly expired tokens
    if user_credential_data.invalid_tokens.contains(token){
        //println!("token manuelly expired");
        return Err(());
    }

    //println!("token valid");
    Ok(jwt_token)
}

pub async fn test_token_header(headers : &axum::http::HeaderMap, state: &AppState<'_>) -> Result<TokenData<JwtClaims>,()> {
    return match headers.get("authorization"){
        Some(value) => match value.to_str() {
            Ok(value) => test_token(&value.to_string(), state).await,
            Err(_) => {
                println!("can't convert token header token to string");
                Err(())
            }
        },
        None => {
            println!("no header token");
            Err(())
        },
    }; 
}

pub async fn post_test_token(State(app_state): State<AppState<'_>>, headers: HeaderMap) -> (StatusCode, String) {
    println!("user testing token");
    let token: Result<TokenData<JwtClaims>, ()> = test_token_header(&headers, &app_state).await;

    match token {
        Ok(_) => return (StatusCode::OK, "vaild token".to_owned()),
        Err(_) => return (StatusCode::UNAUTHORIZED, "invalid token".to_owned())
    }
}



pub async fn post_logout(State(app_state): State<AppState<'_>>, headers: HeaderMap) -> (StatusCode, String) {  //, Json(body): Json<UserLogin>)  just leaving for when I add logging out of 1 device
    let token = test_token_header(&headers, &app_state).await;
    let database_pool = app_state.database;

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


    let database_response = sqlx::query("UPDATE user_credentials SET tokens_expire_time = $1 WHERE user_id = $2")
    .bind(time_now_ms as i64)
    .bind(&user_id)
    .execute(&database_pool).await;

    match database_response {
        Ok(_) => return (StatusCode::OK, "Logged out".to_string()),
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to log out".to_string())
    }

    //later will be one to log out just the one user



}

pub async fn post_user_login(State(app_state): State<AppState<'_>>, Json(body): Json<UserLogin>) -> (StatusCode, String) {
    println!("user logging in");
    let user_email = &body.email;
    let user_password = &body.password;
    let user_password_bytes: &[u8] = user_password.as_bytes();

    let database_pool: &Pool<Postgres> = &app_state.database;
    let encode_key: &EncodingKey = &app_state.jwt_encode_key;

    let argon2: &Argon2 = &app_state.argon2;


    //this code is left here just for debugging
    //it creates a password which you can slap into the database, usefull for in test env
    //let salt = SaltString::generate(&mut OsRng);
    //let custom_password = argon2.hash_password(&user_password_bytes, &salt);
    //match custom_password {
    //    Ok(value) => println!("created password idea {}", value),
    //    Err(_) => println!("Failed to create password"),
    //}


    //used for reset password time and also used for waiting 500ms before returning stopping time attacks
    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to fetch time");
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to fetch time".to_string());
        }
    }.as_millis();

    let user_credential_data: UserCredentials = match sqlx::query_as::<_, UserCredentials>("SELECT * FROM user_credentials WHERE email = $1")
    .bind(&user_email)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(err) => {
            println!("{} ({err})","didn't find a valid user".to_owned());
            wait_time(time_now_ms);
            return (StatusCode::NOT_FOUND, "Username or Password invalid".to_string())
        },
    };

    //loggins expire after 12hours
    //println!("{}",time_now_ms);
    if (time_now_ms - (1000 * 60 * 60 * 12)) as i64 > user_credential_data.last_login_attempt_time {
        //login timeout values has expired

        //still values present that need to be reset, or moved upto 1
        let database_response = sqlx::query("UPDATE user_credentials SET last_login_attempt_time = $1, login_attempt_number = $2 WHERE user_id = $3")
        .bind(time_now_ms as i64)
        .bind(1)
        .bind(&user_credential_data.user_id)
        .execute(database_pool).await;

        match database_response {
            Ok(_) => (),
            Err(err) => {
                println!("failed to reset timeout values ({})", err);
            }
        };

    }else{
        let login_timeout_left: i64 = ((user_credential_data.login_attempt_number as i64) * (1000 * 60)) + user_credential_data.last_login_attempt_time - (time_now_ms as i64);

        //login timeoutes has not expired yet
        if user_credential_data.login_attempt_number > 3 {
            if login_timeout_left > 0 {
                if login_timeout_left < 60000 {
                    //timmed out for less then a minute
                    return (StatusCode::REQUEST_TIMEOUT, "Login timed out for ".to_owned() + &((login_timeout_left as f64) / 1000.0).floor().to_string() + " seconds")

                }else{
                    //timed out for more then a minute
                    return (StatusCode::REQUEST_TIMEOUT, "Login timed out for ".to_owned() + &((login_timeout_left as f64) / 60000.0).floor().to_string() + " minutes")

                }
            }
        }

        let database_response = sqlx::query("UPDATE user_credentials SET last_login_attempt_time = $1, login_attempt_number = $2 WHERE user_id = $3")
        .bind(time_now_ms as i64)
        .bind(&user_credential_data.login_attempt_number + 1)
        .bind(&user_credential_data.user_id)
        .execute(database_pool).await;

        match database_response {
            Ok(_) => (),
            Err(err) => {
                println!("failed to increase login timeout values ({})", err);
                return (StatusCode::INTERNAL_SERVER_ERROR, "failed to timeout".to_string())
            }
        };

    };

    

    //argon2.hash_password(password, salt)


    let user_password_hash: PasswordHash = match PasswordHash::new(&user_credential_data.hashed_password) {
        Ok(value) => value,
        Err(err) => {
            println!("saved password is invalid, likely need to reset ({})", err);
            wait_time(time_now_ms);
            return (StatusCode::INTERNAL_SERVER_ERROR, "saved password is invalid, likely need to reset".to_string());
        },
    };

    let password_valid = argon2.verify_password(user_password_bytes, &user_password_hash);

    match password_valid {
        Ok(_) => (),
        Err(_) => {
            println!("user password is invalid");
            wait_time(time_now_ms);
            return (StatusCode::NOT_FOUND, "Username or Password invalid".to_string())
        },
    }
    

    let header: Header = Header::new(Algorithm::HS512);

    let my_claims: JwtClaims = JwtClaims {
        user_id: user_credential_data.user_id.clone(),
        last_reset_password_time: user_credential_data.last_login_attempt_time as u64,
        exp: (time_now_ms + (1000 * 60 * 60 * 24 * 30)) as usize,
        creation_date: time_now_ms
    };

    let token: String = match encode(&header, &my_claims, &encode_key) {
        Ok(value) => value,
        Err(_) => {
            println!("{}","Failed to create token".to_owned());
            wait_time(time_now_ms);
            return (StatusCode::NOT_FOUND, "Failed to create token".to_string())
        },
    };
    
    if user_credential_data.ban_expire_date > time_now_ms as i64 {
        return (StatusCode::UNAUTHORIZED, format!("account has been banned for {} it will be unbanned in {}", user_credential_data.ban_reason, milliseconds_to_readable_short( user_credential_data.ban_expire_date - (time_now_ms as i64) )))
    }

    let mut data_returning: HashMap<String, Value> = HashMap::new();

    data_returning.insert("token".to_string(), Value::String(token));


       
    let value = match serde_json::to_string(&data_returning) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to convert token to json");
            wait_time(time_now_ms);
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert token data to json".to_string())
        }
    };

    send_notification_to_user_id(&app_state,"",&user_credential_data.user_id.clone(), "", NotificationType::UserLogin).await;

    wait_time(time_now_ms);
    (StatusCode::OK, value)

}

