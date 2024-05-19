use rand::{distributions::Alphanumeric, Rng};
use random_string::generate;


pub fn createItemId() -> String {
    let string = generate(16, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
    string
}