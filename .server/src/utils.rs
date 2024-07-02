use random_string::generate;


pub fn create_item_id() -> String {
    let string = generate(16, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
    string
}

pub fn create_reset_code() -> String {
    let string = generate(512, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
    string
}

pub fn create_create_account_code() -> String {
    let string: String = generate(512, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
    string
}

pub fn milliseconds_to_readable_short(time: i64) -> String {
    if time > 1000 * 60 * 60 * 24 * 365 { // is in years
        let time_value = 1000 * 60 * 60 * 24 * 365 ;
        return format!("{} years", (time / time_value))
    }else if time > 1000 * 60 * 60 * 24 * 30 { // is in months
        let time_value = 1000 * 60 * 60 * 24 * 30;
        return format!("{} months", (time / time_value))
    }else if time > 1000 * 60 * 60 * 24 * 7 { // is in weeks
        let time_value = 1000 * 60 * 60 * 24 * 7;
        return format!("{} weeks", (time / time_value))
    }else if time > 1000 * 60 * 60 * 24 { // is in days
        let time_value = 1000 * 60 * 60 * 24;
        return format!("{} days", (time / time_value))
    }else if time > 1000 * 60 * 60 { // is in hours
        let time_value = 1000 * 60 * 60;
        return format!("{} hours", (time / time_value))
    }else if time > 1000 * 60 { // is in minutes
        let time_value = 1000 * 60;
        return format!("{} minutes", (time / time_value))
    }else if time > 1000 { // is in seconds
        let time_value = 1000;
        return format!("{} seconds", (time / time_value))
    }else{ // is in miliseconds
        return format!("{} milliseconds", time)
    }
}

pub fn test_username(username : &String) -> (bool, String) {
    if username.len() > 25 {
        return (false, "username to large".to_owned());
    }

    if username.len() < 3 {
        return (false, "username to short".to_owned());
    }

    //let allowed_chars = username.chars().all(char::is_alphanumeric);
    //if allowed_chars {
    //    return (false, "username contains invalid chars".to_owned());
    //}

    return (true, "".to_owned());
}

pub fn test_bio(username : &String) -> (bool, String) {
    if username.len() > 500 {
        return (false, "bio to large".to_owned());
    }

    //let allowed_chars = username.chars().all(char::is_alphanumeric);
    //if allowed_chars {
    //    return (false, "username contains invalid chars".to_owned());
    //}

    return (true, "".to_owned());
}