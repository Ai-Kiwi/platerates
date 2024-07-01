use std::time::{SystemTime, UNIX_EPOCH};

use argon2::Argon2;
use axum::{
  extract::State, http::StatusCode, response::Html, Json
  
};
use lettre::{message::{header::ContentType, Mailbox}, Message, Transport};
use serde::Deserialize;
use sqlx::{Pool, Postgres};
use argon2::password_hash::{
      rand_core::OsRng, PasswordHasher, SaltString
  };
use crate::{user_login::UserCredentials, utils::create_reset_code, AppState};
extern crate lettre;

#[derive(Deserialize)]
pub struct UseResetPasswordCode {
  password: String,
  reset_code: String
}

pub async fn post_use_reset_password_code(State(app_state): State<AppState<'_>>, Json(body): Json<UseResetPasswordCode>) -> (StatusCode, String){
  let user_password = &body.password;
  let user_password_bytes: &[u8] = user_password.as_bytes();
  let user_reset_code = &body.reset_code;
  let database_pool = &app_state.database;
  let argon2: Argon2 = app_state.argon2;


  let time_now: SystemTime = SystemTime::now();
  let time_now_ms: u128 = match time_now.duration_since(UNIX_EPOCH) {
      Ok(value) => value,
      Err(_) => {
          println!("Failed to get system time");
          return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to get system time".to_string());
      }
  }.as_millis();

  let user_credential_data: UserCredentials = match sqlx::query_as::<_, UserCredentials>("SELECT * FROM user_credentials WHERE password_reset_code = $1")
  .bind(&user_reset_code)
  .fetch_one(database_pool).await {
      Ok(value) => value,
      Err(err) => {
          println!("{} ({err})","didn't find a valid user".to_owned());
          return (StatusCode::NOT_FOUND, "Invalid reset code".to_string())
      },
  };

  if user_credential_data.password_reset_time < time_now_ms as i64 - (1000 * 60 * 60 * 1) {
    (StatusCode::REQUEST_TIMEOUT, "Password reset code expired".to_string())
  }else{

    let invalid_token: Vec<String> = vec![];

    let salt = SaltString::generate(&mut OsRng);
    let custom_password = argon2.hash_password(&user_password_bytes, &salt);

    let new_password = match custom_password {
        Ok(value) => value.to_string(),
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to create password hash".to_string()),
    };

    let database_response = sqlx::query("UPDATE user_credentials SET invalid_tokens = $1, tokens_expire_time = $2, notification_token = NULL, password_reset_time = $3, hashed_password = $4 WHERE user_id = $5")
    .bind(invalid_token)
    .bind(time_now_ms as i64)
    .bind(0)
    .bind(&new_password)
    .bind(&user_credential_data.user_id)
    .execute(database_pool).await;

    match database_response {
        Ok(_) => return (StatusCode::OK, "Password has been resetnPage can be closed".to_string()),
        Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to update password".to_string()),
    }

    
  }
}


pub async fn get_reset_password(State(_app_state): State<AppState<'_>>) -> Html<String> {
  let body: String = r#"<!DOCTYPE html>
    <html lang="en">
    <head>
      <title>PlateRates: Reset Password</title>
      <style>
        body {
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          background-color: #f5f5f5;
        }
        .container {
          max-width: 400px;
          padding: 30px;
          border-radius: 10px;
          background-color: #fff;
          box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        }
        h1 {
          text-align: center;
          color: #333; /* Black text color */
        }
        .form-group {
          margin-bottom: 20px;
        }
        label {
          display: block;
          margin-bottom: 5px;
          font-weight: bold;
          color: #333; /* Black text color */
        }
        input[type="password"] {
          width: 100%;
          padding: 12px 10px;
          border: 1px solid #ccc;
          border-radius: 5px;
          font-size: 16px;
        }
        .error {
          color: red;
          font-size: 12px;
          margin-top: 5px;
        }
        .button {
          text-align: center;
          padding: 10px 20px;
          background-color: #27ae60; /* Green color for button */
          color: white;
          font-weight: bold;
          border: none;
          border-radius: 5px;
          cursor: pointer;
          display: block;
          margin: 15px auto;
          width: 180px;
        }
        .password-tips {
          margin-top: 10px;
          font-size: 12px;
          color: #333; /* Black text color */
        }
        .password-tips li {
          margin-bottom: 5px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Reset Your Password</h1>
          <div class="form-group">
            <label for="new-password">New Password</label>
            <input type="password" id="new-password" name="new-password" required>
            <span class="error" id="new-password-error"></span>
            </div>
          <div class="form-group">
            <label for="confirm-password">Confirm Password</label>
            <input type="password" id="confirm-password" name="confirm-password" required>
            <span class="error" id="confirm-password-error"></span>
          </div>
          <button id="reset-button">Reset Password</button>
        <div class="password-tips">
          <p>**Password Tips:**</p>
          <ul>
            <li>Use a strong password with at least 8 characters.</li>
            <li>Include a combination of uppercase and lowercase letters, numbers, and symbols.</li>
            <li>Don't use the same password for multiple accounts.</li>
            <li>Consider using a password manager to help you create and store strong passwords.</li>
          </ul>
        </div>
      </div>
      <script>
      document.getElementById("reset-button").onclick = () => {    
          const newPassword = document.getElementById('new-password').value;
          const confirmPassword = document.getElementById('confirm-password').value;
          const newPasswordError = document.getElementById('new-password-error');
          const confirmPasswordError = document.getElementById('confirm-password-error');
    
          newPasswordError.textContent = '';
          confirmPasswordError.textContent = '';
    
          if (newPassword !== confirmPassword) {
            confirmPasswordError.textContent = 'Passwords do not match.';
            return;
          }
    
          const urlParams = new URLSearchParams(window.location.search);
          const resetCode = urlParams.get('reset_code');
    
          if (!resetCode) {
            newPasswordError.textContent = 'Reset code is missing.';
            return;
          }
    
          fetch('/use-reset-password-code', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({
              password: newPassword,
              reset_code: resetCode
            })
          })
          .then(response => {
            if (response.ok) {
              alert('Password reset successfully.');
            } else {
              return response.text().then(data => {
                throw new Error(data);
              });
            }
          })
          .catch(error => {
            newPasswordError.textContent = error.message;
          });
        };
      </script>
      </body>
    </html>"#.to_owned();
  Html(body)
}

#[derive(Deserialize)]
pub struct UserResetPassword {
  email: String,
}

pub async fn post_create_reset_password_code(State(app_state): State<AppState<'_>>, Json(body): Json<UserResetPassword>) -> (StatusCode, String) {
  let user_email: &String = &body.email;
  let database_pool: Pool<Postgres> = app_state.database;
  let emailer = app_state.mailer;

  println!("user running email reset");

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
  .fetch_one(&database_pool).await {
      Ok(value) => value,
      Err(err) => {
          println!("{} ({err})","didn't find a valid user assigned to email".to_owned());
          return (StatusCode::NOT_FOUND, "Email invalid".to_string())
      },
  };

  let password_reset_time: i64 = user_credential_data.password_reset_time;
  let password_reset_code: String = create_reset_code();

  if password_reset_time + (1000 * 60 * 60 * 24) > time_now_ms as i64 {
    return (StatusCode::REQUEST_TIMEOUT, "Email codes can only be created every 24hours".to_owned());
  }else{
    let database_response = sqlx::query("UPDATE user_credentials SET password_reset_code = $1, password_reset_time = $2 WHERE user_id = $3")
    .bind(&password_reset_code)
    .bind(time_now_ms as i64)
    .bind(&user_credential_data.user_id)
    .execute(&database_pool).await;

    match database_response {
        Ok(_) => {
          let email_html: String = format!(r#"
          <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>PlateRates: Reset Your Password</title>
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
            <p>We received a request to reset your password for your platerates account.</p>
            <p>If you requested this reset, click the button below to choose a new password.</p>
            <p>**If you did not request a password reset, please ignore this email.**</p>
            <a href="https://platerates.com/reset-password?reset_code={}" class="reset-button">Reset Password</a>
            <p>This link will expire in 1 hour for your security.</p>
          </div>
          <div class="footer">
            <p>Having trouble? Contact us at <a href="mailto:support@platerates.com">support@platerates.com</a></p>
            <p>The platerates Team</p>
          </div>
        </div>
      </body>
      </html>"#,&password_reset_code);

          let email_receiving: Mailbox = match user_credential_data.email.parse() {
            Ok(value) => value,
            Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Invalid email, contact support".to_owned()),
          };

          let email_message = Message::builder()
          .from("no-reply platerates <accounts@noreply.platerates.com>".parse().unwrap())
          .to(email_receiving)
          .subject("Password reset for platerates")
          .header(ContentType::TEXT_HTML)
          .body(email_html);

          match email_message {
            Ok(value) => match emailer.send(&value) {
                Ok(_) => return (StatusCode::OK, "Created email reset code, check emails".to_owned()),
                Err(_) => return (StatusCode::INTERNAL_SERVER_ERROR, "Failed to send email".to_owned()),
            }
            Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "Failed to send email, invalid".to_owned()),
          }
        },
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, "Failed to create reset password code".to_owned()),
    }
  }
  
}