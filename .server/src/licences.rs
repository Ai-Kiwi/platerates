use std::collections::HashMap;

use axum::extract::State;
use hyper::{HeaderMap, StatusCode};
use serde::Deserialize;
use sqlx::types::Json;

use crate::{user_login::test_token_header, user_profiles::UserData, AppState, LICENSES};


//get unsigned lisences
//accept licenes


pub async fn get_unaccepted_licenses(State(app_state): State<AppState<'_>>, headers: HeaderMap) -> (StatusCode, String) {
    println!("user fetching unaccepted licenses");
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

    let user_licenses: Json<HashMap<String, i32>> = user_data.licenses;
 
    let mut not_accepted_licenses : sqlx::types::Json<HashMap<String,i32>> = Json(HashMap::new());

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

}

//pub async fn post_licenses_update(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<UpdateLicenses>){
//
//}
//updates all the liceneses to the latest version


//router.post('/licenses/update', [confirmTokenValid], async (req : Request, res : Response) => {
//    console.log(" => user updating licenses")
//    try{
//        const userId = req.body.tokenUserId;
//        const licensesUserAccepted = req.body.licenses;
//
//        const userLicenses = await database.user_licenses
//        .where({ user_id : userId })
//    
//        var licenses = {}
//
//        //if (userData === null){
//        //    console.log("user id from token invalid")
//        //    res.status(404).send(`user id from token invalid`);
//        //    return;
//        //}
//
//        if (userLicenses.length > 0){
//            licenses = userLicenses[0].licenses
//        }
//        
//        for (const key in licensesUserAccepted) {
//            
//            if (Licenses[key] == licensesUserAccepted[key]){
//                licenses[key] = licensesUserAccepted[key];
//
//            }
//        }
//
//        var response;
//        
//        if (userLicenses.length == 0){
//            response = await database.user_licenses
//            .insert({
//                user_id : userId,
//                licenses : licenses
//            })
//        }else{
//            response = await database.user_licenses
//            .where({ user_id : userId })
//            .update({
//                licenses : licenses
//            })
//        }
//
//        if (response > 0){
//            console.log("updated licenses")
//            return res.status(200).send("updated licenses")
//        }else{
//            console.log("failed to update licenses")
//            return res.status(500).send("failed to update licenses")
//        }
//
//
//
//
//      
//    }catch(err){
//        reportError(err);
//        return res.status(500).send("server error")
//    }
//})