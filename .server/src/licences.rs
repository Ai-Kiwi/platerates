use std::collections::HashMap;
use axum::{extract::State, Json};
use hyper::{HeaderMap, StatusCode};
use serde::Deserialize;
use crate::{user_login::test_token_header, user_profiles::UserData, AppState, LICENSES};


pub async fn get_unaccepted_licenses(State(app_state): State<AppState<'_>>, headers: HeaderMap) -> (StatusCode, String) {
    println!("user getting unaccepted licenses");
    let database_pool: &sqlx::Pool<sqlx::Postgres> = &app_state.database;
    let token_data: jsonwebtoken::TokenData<crate::user_login::JwtClaims> = match test_token_header(&headers, &app_state).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::UNAUTHORIZED,"User not logged in".to_owned()),
    };

    let user_id: String = token_data.claims.user_id;

    let user_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::NOT_FOUND, "User not found".to_string()),
    };

    let user_licenses: sqlx::types::Json<HashMap<String, i32>> = user_data.licenses;
 
    let mut not_accepted_licenses : sqlx::types::Json<HashMap<String,i32>> = sqlx::types::Json(HashMap::new());

    for license in LICENSES.iter() {
        //println!("{}, {}",license.0, license.1);
        let license_name: String = license.0.clone();
        let license_version: i32 = license.1.clone();

        match user_licenses.get(&license_name) {
            Some(value) => {
                if value != &license_version {
                    not_accepted_licenses.insert(license_name.to_string(), license_version);
                }
            },
            None => {
                not_accepted_licenses.insert(license_name.to_string(), license_version);
            }
        };
    }

    let value: String = match serde_json::to_string(&not_accepted_licenses) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to convert token to json");
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert token data to json".to_string())
        }
    };

    return (StatusCode::OK,value.to_owned())
}
//lists a vector with all the unaccapted lisenses

#[derive(Deserialize)]
pub struct UpdateLicenses {
    licenses : Vec<String>
}

pub async fn post_licenses_update(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<UpdateLicenses>) -> (StatusCode, String) {
    println!("user updating licenses accepted");
    let accepted_licenses: Vec<String> = body.licenses;
    let database_pool: &sqlx::Pool<sqlx::Postgres> = &app_state.database;
    let token_data: jsonwebtoken::TokenData<crate::user_login::JwtClaims> = match test_token_header(&headers, &app_state).await {
        Ok(value) => value,
        Err(_) => return (StatusCode::UNAUTHORIZED,"User not logged in".to_owned()),
    };

    for license in accepted_licenses.iter() {

        let latest_version = match LICENSES.get(license) {
            Some(value) => value,
            None => return (StatusCode::INTERNAL_SERVER_ERROR,"Invalid license".to_owned()),
        };

        let mut license_path: Vec<String> = Vec::new();
        license_path.push(license.to_string());

        let database_response = sqlx::query("UPDATE user_data SET licenses = jsonb_set( COALESCE(licenses, '{}'), $1::text[], to_jsonb($2), true) WHERE user_id = $3")
        .bind(license_path)
        .bind(latest_version)
        .bind(&token_data.claims.user_id)
        .execute(database_pool).await;
        
        match database_response {
            Ok(_) => (),
            Err(err) => {
                println!("update license failed {}", err);
                return (StatusCode::INTERNAL_SERVER_ERROR,"Failed to update license".to_owned());
        },
        }

    }

    return (StatusCode::OK, "Updated licenses".to_string())
}