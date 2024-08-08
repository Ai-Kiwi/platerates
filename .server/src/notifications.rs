use std::{collections::HashMap, time::{SystemTime, UNIX_EPOCH}};

use axum::{extract::{Query, State}, Json};
use hyper::{HeaderMap, StatusCode};
use serde::{de::value, Deserialize, Serialize};
use serde_json::{json, to_string, Value};

use crate::{user_login::{test_token_header, UserCredentials}, user_profiles::UserData, utils::create_item_id, AppState};

#[derive(Serialize, Deserialize)]
struct Notification {
    body: String,
    title: String,
}

#[derive(Serialize, Deserialize)]
struct Data {
    channel_id: String,
    body: String,
    title: String,
}

#[derive(Serialize, Deserialize)]
struct Message {
    token: String,
    notification: Notification,
    data: Data,
}

#[derive(Serialize, Deserialize)]
struct Root {
    message: Message,
}

pub enum NotificationType {
    PostRated,
    UserLogin,
    RatingComment,

}

#[derive(sqlx::FromRow)]
pub struct UserNotification { 
    pub notification_id : String,
    pub item_id : String,
    pub item_type : String,
    pub source_user_id : String,
    pub receiver_id : String,
    pub sent_date : i64,
    pub read : bool,
}

pub async fn send_notification_to_user_id(app_state: &AppState<'_>, source_user_id : &str, user_id : &str, item_id: &str, notification_type : NotificationType ) {
    println!("sending notifications to user");
    //get info about notifcation
    let token: &std::sync::Arc<gcp_auth::Token> = &app_state.firebase_token;
    let fireabase_id: &String = &app_state.firebase_project_id;
    let database_pool: &sqlx::Pool<sqlx::Postgres> = &app_state.database;

    let user_credential_data: UserCredentials = match sqlx::query_as::<_, UserCredentials>("SELECT * FROM user_credentials WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to send notification, user id doesn't exist");
            return ;
        },
    };

    let user_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(user_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to send notification, user id doesn't exist");
            return ;
        },
    };

    let source_user_data: UserData = match sqlx::query_as::<_, UserData>("SELECT * FROM user_data WHERE user_id = $1")
    .bind(source_user_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(_) => {
            println!("failed to send notification, source user id doesn't exist");
            return ;
        },
    };

    //save notication in history

    let time_now: SystemTime = SystemTime::now();
    let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
        Ok(value) => value,
        Err(_) => {
            println!("failed to fetch time");
            return;
        }
    }.as_millis();

    let item_type = match notification_type {
        NotificationType::PostRated => "userRating",
        NotificationType::UserLogin => "newLogin",
        NotificationType::RatingComment => "userComment",
    };

    let notification_id: String = create_item_id(); 

    let result = sqlx::query(
        "INSERT INTO user_notifications (notification_id, item_id, source_user_id, receiver_id, sent_date, item_type) VALUES ($1, $2, $3, $4, $5, $6)")
        .bind(&notification_id)
        .bind(&item_id)
        .bind(&source_user_data.user_id)
        .bind(user_id)
        .bind(time_now_ms as i64)
        .bind(item_type)
        .execute(database_pool).await;

    match result {
        Ok(_) => {
            println!("added notifcation to user")
        },
        Err(err) => {
            println!("failed to add notifcation to app {}",err)
        },
    }


    //send notifcation to device

    let notification_device_token = match user_credential_data.notification_token {
        Some(value) => value,
        None => {
            println!("user yet to have notification linked");
            return ;
        }
    };

    //let username: String = user_data.username;
    let source_username: String = source_user_data.username;

    let message: Message = match notification_type {
        NotificationType::PostRated => Message {
            token: notification_device_token,
            notification: Notification {
                title: "Not Used".to_string(),
                body: "Not Used".to_string(),
            },
            data: Data {
                channel_id:"userRating".to_string(),
                title: "New rating".to_owned(),
                body: format!("{} has rated your post.", source_username),
            }
        },
        NotificationType::UserLogin => Message {
            token: notification_device_token,
            notification: Notification {
                title: "Not Used".to_string(),
                body: "Not Used".to_string(),
            },
            data: Data {
                channel_id:"newLogin".to_string(),
                title: "New account login".to_string(),
                body: "A new device has logged into your account".to_string(),
            }
        },
        
        
    
        NotificationType::RatingComment => Message {
            token: notification_device_token,
            notification: Notification {
                title: "Not Used".to_string(),
                body: "Not Used".to_string(),
            },
            data: Data {
                channel_id:"userComment".to_string(),
                title: "New reply to rating".to_string(),
                body: format!("{} has replied your rating.", source_username),
            }
        },
    };
    let root: Root = Root { message };
    let json_string: String = to_string(&root).unwrap();

    let client = reqwest::Client::new();
    let res = client.post(format!("https://fcm.googleapis.com/v1/projects/{}/messages:send",fireabase_id))
        .header("Content-Type", "application/json")
        .header("Authorization", format!("Bearer {}",token.as_str()))
        .body(json_string)
        .send()
        .await;      

    match res {
        Ok(_) => {
            println!("sent notification");
            //print!("{}", value.text().await.expect("failed to thingy"));
        },
        Err(_) => {
            println!("Failed to send notification post request")
        },
    }
}

#[derive(Deserialize)]
pub struct GetNotificationsListPaginator {
    page : String,
    page_size : String,
}

pub async fn get_notifications_list(pagination: Query<GetNotificationsListPaginator>, headers: HeaderMap, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user listing notifications");
    let pagination: GetNotificationsListPaginator = pagination.0;
    let database_pool: &sqlx::Pool<_> = &app_state.database;
    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };
    
    let page_number: i64 = match pagination.page.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page number".to_string()),
    };
    let page_size: i64 = match pagination.page_size.parse::<i64>() {
        Ok(value) => value,
        Err(_) => return (StatusCode::BAD_REQUEST, "Invalid page size".to_string()),
    };

    let notifications = match sqlx::query_as::<_, UserNotification>("SELECT * FROM user_notifications WHERE receiver_id = $1 ORDER BY sent_date DESC LIMIT $2 OFFSET $3")
    .bind(user_id)
    .bind(page_size)
    .bind(page_number * page_size)
    .fetch_all(database_pool).await {
        Ok(value) => value,
        Err(err) => {
            println!("{}", err);
            return (StatusCode::NOT_FOUND, "Failed getting notifications".to_string());
        },
    };
    
    
    

    let mut notifications_returning: Vec<HashMap<&str, Value>> = vec!();

    for notification in &notifications {
        let notification_data = json!({
            "notification_id": notification.notification_id,
            "item_id": notification.item_id,
            "item_type": notification.item_type,
            "source_user_id": notification.source_user_id,
            "receiver_id": notification.receiver_id,
            "sent_date": notification.sent_date,
            "read": notification.read,
        });

        notifications_returning.push(HashMap::from([
            ("type", Value::String("notification".to_owned())),
            ("data", notification_data),
        ]));
    }
    

    let value = match serde_json::to_string(&notifications_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert notification data to json".to_string()),
    };

    (StatusCode::OK, value)
}


#[derive(Deserialize)]
pub struct NotificationTokenBody {
    notification_token : String,
}    

pub async fn post_update_notification_token(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<NotificationTokenBody>) -> (StatusCode, String) {
    println!("user updating notification token");
    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };
    let database_pool: &sqlx::Pool<sqlx::Postgres> = &app_state.database;

    let notification_token: String = body.notification_token;

    let _ = sqlx::query("UPDATE user_credentials SET notification_token = $1 WHERE user_id != $2 AND notification_token != $3")
    .bind(&notification_token)
    .bind(&user_id)
    .bind(&notification_token)
    .execute(database_pool).await;

    let response = sqlx::query("UPDATE user_credentials SET notification_token = $1 WHERE user_id = $2")
    .bind(&notification_token)
    .bind(&user_id)
    .execute(database_pool).await;

    match response {
        Ok(_) => return (StatusCode::OK, "Updated notification token".to_string()),
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to update notification token".to_string()),
    }
}

#[derive(Deserialize)]
pub struct MarkNotificationReadBody {
    notification_id : String,
}    

pub async fn post_mark_notification_read(State(app_state): State<AppState<'_>>, headers: HeaderMap, Json(body): Json<MarkNotificationReadBody>) -> (StatusCode, String) {
    println!("user marking notification as read");
    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };
    let database_pool: &sqlx::Pool<sqlx::Postgres> = &app_state.database;
    let notification_id = body.notification_id;


    //test when last post by user was make sure was awhile ago
    let notification_data: UserNotification = match sqlx::query_as::<_, UserNotification>("SELECT * FROM user_notifications WHERE notification_id = $1")
    .bind(&notification_id)
    .fetch_one(database_pool).await {
        Ok(value) => value,
        Err(err) => {
            println!("Failed to get notification data ({})", err);
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to get notification data".to_string());

        },
    };

    if notification_data.receiver_id != user_id {
        return (StatusCode::UNAUTHORIZED, "You doesn't own notification".to_string());
    }

    if notification_data.read == true {
        return (StatusCode::CONFLICT, "Notification already marked as read".to_string());
    }

    let response = sqlx::query("UPDATE user_notifications SET read = $1 WHERE notification_id = $2")
    .bind(true)
    .bind(&notification_id)
    .execute(database_pool).await;

    match response {
        Ok(_) => return (StatusCode::OK, "Marked notification read".to_string()),
        Err(err) => {
            println!("{}",err);
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to mark notification read".to_string())
        
        },
    }
}


pub async fn get_notifications_unread(headers: HeaderMap, State(app_state): State<AppState<'_>>) -> (StatusCode, String) {
    println!("user fetching unread notification count");
    let token: Result<jsonwebtoken::TokenData<crate::user_login::JwtClaims>, ()> = test_token_header(&headers, &app_state).await;
    let user_id: String = match token {
        Ok(value) => value.claims.user_id,
        Err(_) => return (StatusCode::UNAUTHORIZED, "Not logged in".to_string()),
    };

    let database_pool: &sqlx::Pool<sqlx::Postgres> = &app_state.database;

    let unread_notification : (i64,) = match sqlx::query_as(
        "SELECT COUNT(*) FROM user_notifications WHERE receiver_id = $1 AND read = $2"
    )
    .bind(&user_id)
    .bind(false)
    .fetch_one(database_pool)
    .await {
        Ok(value) => value,
        Err(_) => {
            return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to fetch unread notification count".to_string())
        },
    };

    let unread_notification_count: i64 = unread_notification.0;


    let mut data_returning: HashMap<String, Value> = HashMap::new();

    data_returning.insert("unreadCount".to_string(), Value::Number(unread_notification_count.into()));
    data_returning.insert("newChatMessages".to_string(), Value::Number(0.into()));


    let value = match serde_json::to_string(&data_returning) {
        Ok(value) => value,
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to convert notification to json".to_string())
    };

    return (StatusCode::OK, value)
}
