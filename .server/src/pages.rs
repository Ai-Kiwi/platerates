//hard coded because it means end user has less files to worry about, ideally when I get a change I will find a beter way

use axum::{body::Body, response::{Html, IntoResponse, Response as AxumResponse}};
use hyper::{header::CONTENT_TYPE, Response, StatusCode};




pub async fn get_page_community_guidelines() -> Html<&'static str> {
  println!("fetching community guidelines");
    Html(r#"<!DOCTYPE html>
        <html>
        <head>
            <title>PlateRates Community Guidelines</title>
            <link rel="stylesheet" type="text/css" href="styles.css">
        </head>
        <body>
            <h1>Welcome to Food in General App Guidelines</h1>
        
            <h2>1. Be Respectful and Inclusive</h2>
            <p>Everyone is welcome here! Embrace and celebrate the diverse range of culinary creations, cooking styles, and food preferences represented by our users. Treat others with respect, regardless of their cultural background, dietary choices, or cooking skills.</p>
        
            <h2>2. Content Guidelines</h2>
            <h3>2.1 Share Food-Related Content</h3>
            <p>This platform is all about food! Share photos, videos, and stories about your culinary adventures. Post recipes, tips, tricks, and anything else related to the wonderful world of food.</p>
            <h3>2.2 Keep it Appropriate</h3>
            <p>Please refrain from posting any content that is considered offensive, hateful, discriminatory, or sexually suggestive. We want to maintain a welcoming and inclusive environment for all users.</p>
        
            <h2>3. User Conduct</h2>
            <h3>3.1 Be Polite and Courteous</h3>
            <p>Engage in discussions and share your opinions in a respectful and constructive manner. Avoid personal attacks, insults, and any form of harassment.</p>
            <h3>3.2 Protect Privacy</h3>
            <p>Do not share personal information about yourself or others without their consent. This includes names, addresses, phone numbers, and any other identifiable details.</p>
        
            <h2>4. Copyright and Intellectual Property</h2>
            <p>We take intellectual property rights seriously. Only share content that you have the right to share, whether it\'s your own creation or something you have permission to use. Respect the rights of others.</p>
        
            <br><p>revision: 1<br>
            last updated: 29th February 2024</p>
        </body>
        </html>"#)
}


pub async fn get_page_delete_data() -> Html<&'static str> {
  println!("fetching deletion policies");
    Html(r#"
<!DOCTYPE html>
<html>

<head>
    <title>PlateRates - Account Deletion Request</title>
    <link rel="stylesheet" type="text/css" href="styles.css">
</head>

<body>
    <h1>PlateRates - Account Deletion Request</h1>
    <p>Thank you for using PlateRates. We are committed to protecting your privacy and respecting your data
        preferences. If you wish to delete your account and associated data from our system, please follow the steps
        outlined below.</p>

    <h2>How to Request Account Deletion:</h2>
    <p>To initiate the account deletion process, please send an email to <a href="mailto:support@platerates.com">support@platerates.com</a>.
        In the email subject line, use "Account Deletion Request" to ensure prompt handling of your inquiry. In the body
        of the email, kindly include the following information:</p>
    <ol>
        <li>Your registered email address or username within the app.</li>
        <li>A brief statement indicating your desire to delete your account and associated data.</li>
    </ol>

    <h2>Data Deletion Details:</h2>
    <p>Upon receiving your account deletion request, we will proceed to delete all personally identifiable information
        associated with your account. This includes any data stored on our servers and your device, such as account
        details and profile information.</p>
    <p>However, please note that certain data may be retained for legitimate business purposes, such as maintaining ban history records to prevent abuse of our services. This ensures that banned accounts cannot simply be deleted and immediately re-created. Such retained data is strictly used for security and compliance reasons and is not used for other purposes.</p>
    <p>Please note that while we delete personal data, certain non-personal information, such as app analytics and
        aggregated usage statistics, may be retained for analytical purposes. These data points are anonymized and do not
        identify individual users.</p>
    
    <h2>Verification and In-App Deletion:</h2>
    <p>For security purposes, we may require additional verification to process your account deletion request. This is to
        ensure that only the account owner can initiate such a request.</p>
    <p>Additionally, within the app, you may have the option to delete certain data while signed in. For example, you can
        delete your posts and ratings by clicking on the three dots (...) next to the respective content.</p>

    <h2>Contact Us:</h2>
    <p>For any questions or concerns regarding your account deletion request or our privacy practices, please feel free
        to contact our support team at <a href="mailto:support@platerates.com">support@platerates.com</a>.</p>

    <p>We are committed to adhering to best practices to protect your privacy. Thank you for your trust in PlateRates.</p>

    <br><p>revision: 3<br>
    last updated: 29th February 2024</p>
</body>

</html>"#)
}

pub async fn get_page_privacy_policy() -> Html<&'static str> {
  println!("fetching privacy policy");
    Html(r#"
<!DOCTYPE html>
<html>
<head>
  <title>Privacy Policy for PlateRates</title>
  <link rel="stylesheet" type="text/css" href="styles.css">
</head>
<body>
  <h1>Privacy Policy for PlateRates</h1>
  <p><strong>Effective Date:</strong> 3rd December 2023</p>

  <p>Thank you for using PlateRates ("App"), an application and website provided by Ai Kiwi. This Privacy Policy outlines how we collect, use, disclose, and safeguard your personal information when you use the App. By using the App, you consent to the data practices described in this Privacy Policy. If you do not agree with this policy, please do not use the App.</p>

  <br>
  <h1>1. Information We Collect</h1>

  <h2>1.1 Anonymous Information for Crash Detection:</h2>
  <p>We may collect anonymous information about your usage of the App, including website visits and interactions for crash detection and debugging purposes. This data is used solely to improve the App's performance and user experience and does not personally identify you.</p>

  <h2>1.2 Identifier User Account Information:</h2>
  <p>To provide you with access to certain features and personalized services, we collect the following information when you register for an account:</p>
  <ul>
    <li>UserID: An alphanumeric identifier assigned to your account.</li>
    <li>Email Address: Your email address will be used for account-related communications and password reset requests.</li>
  </ul>

  <h2>1.3 Password:</h2>
  <p>We collect and store your password securely to authenticate your access to the App. For security reasons, we encrypt and hash this data to ensure its protection.</p>

  <h2>1.4 User-Generated Content:</h2>
  <p>Any data you post, such as posts or ratings will be stored on our and/or third-party servers. This data is publicly visible and associated with your account.</p>

  <h2>1.5 Private User-Generated Content:</h2>
  <p>Any private data you post, such as messages will be stored on our and/or third-party servers. This data is not publicly visible however is associated with your account.</p>

  <h2>1.6 Profile Information:</h2>
  <p>You have the option to provide additional information for your profile, such as bios and usernames. This data is visible to other users of the App.</p>

  <h2>1.7 Failed Login Information:</h2>
  <p>In the event of a failed login attempt, we may collect information such as your IP address to monitor and protect against unauthorized access to your account.</p>

  <h2>1.8 Password Reset Email:</h2>
  <p>When requesting a password reset, your IP address will be logged and sent to your registered email address for security purposes.</p>

  <br>
  <h1>2. Firebase Services</h1>
  <p>We use Firebase, a mobile and web application development platform provided by Google, to enhance the functionality and features of our App. Firebase may collect and process certain data for these purposes. Here's how Firebase is integrated into our App:</p>

  <h2>2.1 Firebase Crashlytics</h2>
  <p>We employ Firebase Crashlytics to enhance the stability and performance of our App. Firebase Crashlytics helps us identify and resolve issues, crashes, and errors, allowing us to provide you with a smoother and more reliable user experience.</p>
  <p>When you use our App, Firebase Crashlytics may automatically collect and process data related to application crashes and errors, which may include device information, application logs, and the sequence of events leading to a crash. This data is used solely for debugging and improving the App's performance.</p>
  <p>We want to assure you that the data collected by Firebase Crashlytics is anonymized and does not personally identify you. It is solely intended to help us maintain the quality and reliability of our App.</p>

  <h2>2.2 Firebase Cloud Messaging (FCM)</h2>
  <p>Our App utilizes Firebase Cloud Messaging (FCM) to deliver push notifications to your device. FCM enables us to send you important announcements, updates, and personalized messages to enhance your experience with the App.</p>
  <p>When you use our App, FCM may collect and process data that includes your device's unique identifiers, such as the Firebase Instance ID, and your device's operating system information. This information is used solely for the purpose of delivering notifications and improving your interaction with the App.</p>
  <p>If you wish to opt out of receiving push notifications from our App, you can manage your notification preferences in your device settings. Please note that opting out may result in missing important updates and information related to the App.</p>
 
  <h2>2.3 Firebase Analytics</h2>
  <p>Our App uses Firebase Analytics to collect anonymous data on user interactions and behaviors. This information helps us understand user preferences and improve the App's performance. Firebase Analytics may collect data such as device information, user interactions, and geographic location. This data is used solely for analytical and performance enhancement purposes.</p>
  
  <h2>2.4 Firebase App Check</h2>
  <p>We have implemented Firebase App Check as a security measure to protect the integrity of our App and your data. Firebase App Check is a service provided by Google that helps us ensure that only genuine and safe client devices are able to interact with our services.</p>  
  <p>When you use our App, Firebase App Check may collect and process data related to your device's interactions with our services. This data includes device information, requests made to our servers, and other security-related events. This information is used solely for the purpose of verifying the authenticity of your device and preventing unauthorized or malicious access to our services.</p> 
  <p>We want to assure you that the data collected by Firebase App Check is not used to personally identify you and is not shared with third parties. It is used solely to enhance the security and reliability of our App.</p> 
  <p>If you have any concerns or questions regarding how Firebase App Check is used in our App, please do not hesitate to contact us at <a href="mailto:support@platerates.com">support@platerates.com</a>.</p>


   <!-- might add in future so are here for that reason 
  <h2>2.2 Firebase Authentication</h2>
  <p>To provide you with secure access to our services, we use Firebase Authentication. When you register for an account, Firebase may collect and process user identifiers, email addresses, and other account-related information. Firebase Authentication helps us verify user identities and protect user data.</p>
  -->


  <br>
  <h1>3. Use of Information</h1>
  <p>We use the collected information for the following purposes:</p>

  <h2>3.1 To Provide and Improve Services:</h2>
  <p>We use the information to provide, operate, and maintain the App, personalize your experience, and improve our services and features.</p>

  <h2>3.2 Communication:</h2>
  <p>We may use your email address to send you important announcements, updates, and changes related to the App.</p>

  <h2>3.3 User-Generated Content:</h2>
  <p>Your posts and ratings will be publicly displayed on the App to other users, as intended by the App's functionality.</p>

  <h2>3.4 Crash Detection and Debugging:</h2>
  <p>Anonymous information collected may be used for crash detection and debugging to ensure a smooth user experience.</p>

  <br>
  <h1>4. Disclosure of Information</h1>
  <p>We will not disclose your personal information to third parties except in the following circumstances:</p>

  <h2>4.1 Service Providers:</h2>
  <p>We may share certain information with trusted third-party service providers who assist us in operating the App and delivering services to you. These providers are bound by confidentiality obligations and are prohibited from using your information for any other purpose.</p>

  <h2>4.2 Compliance with Legal Requirements:</h2>
  <p>We may disclose your information if required by law, government request, or when necessary to protect our rights, privacy, safety, or the public.</p>

  <br>
  <h1>6. Data Security</h1>
  <p>We take appropriate measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction. Despite our efforts, no method of transmission over the internet or electronic storage is entirely secure, and we cannot guarantee absolute security.</p>

  <br>
  <h1>7 Moderation Procedures</h1>
  <p>By using the App, you acknowledge and agree to our right to access and review private data for moderation purposes. We do this to ensure a safe and respectful environment for all users of the App.</p>

  <br>
  <h1>8. Your Choices</h1>
  <p>You may review, update, or delete your account information at any time. To do so, please contact us at <a href="mailto:support@platerates.com">support@platerates.com</a>. You may also choose not to provide certain information; however, this may limit your access to certain features and functionality of the App.</p>

  <br>
  <h1>9. Changes to this Privacy Policy</h1>
  <p>We reserve the right to modify this Privacy Policy at any time. Any changes will be effective immediately upon posting the updated policy in the App. Your continued use of the App after any modifications constitutes your acceptance of the revised Privacy Policy.</p>

  <br>
  <h1>10. Contact Us</h1>
  <p>If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at <a href="mailto:support@platerates.com">support@platerates.com</a>.</p>
  
  <p><em>For more information on deleting data, please visit <a href="https://platerates.com/deleteData">https://platerates.com/deleteData</a>.</em></p>

  <br><p>revision: 3<br>
  last updated: 29th February 2024</p>
</body>
</html>"#)
}


pub async fn get_page_styles() -> AxumResponse {
  println!("fetching css styles page");
  let css_body = r#"
  body {
    background-color: #000;
    color: #fff;
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
  }
  
  /* Style the header (h1) */
  h1 {
    color: #00C853; /* Flutter's default green color */
    font-size: 24px;
  }
  
  /* Style the subheadings (ch2) */
  h2 {
    color: #00C853; /* Flutter's default green color */
    font-size: 18px;
  }
  
  /* Style paragraphs and lists */
  p, ol {
    font-size: 16px;
    line-height: 1.5;
  }    println!("user updating licenses accepted");

    background-color: #000;
    padding: 20px;
    border: 1px solid #00C853; /* Flutter's default green color */
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
    border-radius: 5px;
  }"#;

  Response::builder()
  .status(StatusCode::OK)
  .header(CONTENT_TYPE, "text/css")
  .body(Body::from(css_body))
  .unwrap()
  .into_response()

}


pub async fn get_page_terms_of_service() -> Html<&'static str> {
  println!("fetching terms of service");
  Html(r#"
<!DOCTYPE html>
<html>
<head>
    <title>PlateRates Terms of Service</title>
    <link rel="stylesheet" type="text/css" href="styles.css">
</head>
<body>
    <h1>Welcome to PlateRates Terms of Service</h1>
    <p>Please read these Terms of Service carefully as they are a legally binding agreement between you and PlateRates. By using our platform, you agree to comply with the following terms</p>

    <h2>1. Account Usage</h2>
    <p>You are responsible for your account. Protect your login credentials and do not share your account with others. You must be of legal age to use PlateRates.</p>

    <h2>2. Content Ownership</h2>
    <p>You retain ownership of the content you post on PlateRates, but you grant us a non-exclusive license to use and display your content on the platform.</p>

    <h2>3. Respecting Intellectual Property</h2>
    <p>Do not infringe on copyrights, trademarks, or any other intellectual property rights when posting content.</p>

    <h2>4. User Conduct</h2>
    <p>Adhere to our community guidelines. Violations may result in warnings, content removal, or account suspension.</p>

    <h2>5. Chat Feature</h2>
    <p>PlateRates provides a chat feature for users to engage in friendly conversations. Use the chat responsibly, avoiding spam, harassment, or any form of misconduct. Conversations in chat are private but may be monitored for safety purposes.</p>

    <h2>6. Liability</h2>
    <p>PlateRates is not responsible for the content posted by users, but we reserve the right to moderate and remove content that violates our guidelines.</p>

    <h2>7. Termination</h2>
    <p>We reserve the right to terminate accounts for violations of these terms.</p>

    <p>By using PlateRates, you agree to these terms and agree to follow the guidelines. We're excited to have you join our positive and toasty community!</p>

    <br><p>revision: 1<br>
    last updated: 29th February 2024</p>


</body>
</html>"#)
}

//I haven't done these yet
pub async fn get_page_change_log() -> Html<&'static str> {
  println!("fetching change log");
  println!("user fetching changelog");
  Html(r#"
  <b> Naming system </b> <br>
  Names in this are split into 3 sections, example : 1.2.3 <br>
  1 : at the moment stays at one <br>
  2 : large changes to server api, meaning everyone must update <br> 
  3 : small changes to client or server that doesn't break api <br>
  <br>

  <b> 2.2.0 </b> <br>
   - added auto clearing old cache individually <br>
   - updated dependencies for app <br>
   - added support link on login screen <br>
   - changed post popup to say for post not message, fixed copy id being user id instead of post id <br>
  <br>

  <b> 2.1.0 </b> <br>
   - pushed major release to force update for exif patch <br>
   - fixed notification_token not getting cleared from other users <br>
   - updated notification icon <br>
  <br>

  <b> 2.0.3 </b> <br>
   - fixed notifcations not working <br>
   - fixed leaked exif data <br>
  <br>

  <b> 2.0.2 </b> <br>
   - fixed rating count, post count, following count and followers count <br>
   - added blur to profile picture background image <br>
   - made your own posts not say you haven't rated them yet <br>
   - allowed reading notifcations for deleted items <br>
   - fixed notifcations not sending to devices <br>
   - removed need to add text to rating <br>
   - changed app backend code to com.platerates <br>
   - made page reopen when rating or comment posted instead of open ontop of current page <br>
   - removed open chat button. Will readd back when chats readded to app <br>
   - allowed running older versions as long as no major change had been made <br>
   - added loading on create post as uploading <br>
   - added loading as you are logging in <br>
  <br>

  <b> 2.0.1 </b> <br>
  - added support for back to android 9 <br>
  - fixed creating account sending you an email incorrectly label reseting password <br>
  - made app restart as soon as login to make licenses prompt as soon as you login instead of after reboot <br>
  - made wide mode on web not always show red icon for new notification <br>
  - added spacing on top of profiles that aren't yours<br>
  - made background be profile pic for profiles<br>
  <br>

  <b> 2.0.0 </b> <br>
  - temporarily removed chat <br>
  - switched name to PlateRates <br>
  - moved over to being anything food related instead of just toast <br> 
  - added support for more then 1 image per post <br>
  - moved backend database to postgresql <br> 
  - moved backend to use local file storage for post images <br>
  - recoded backend in rust <br>
  - improved support for web on desktop <br>
  - moved default color to be blue <br>
  <br>
 
 <b> 1.1.0 </b> <br>
  - Moved bio and username settings to the profile settings page. <br>
  - Added avatars. <br>
  - Remade UI elements, including: <br>
  - - Create post. <br>
  - - Upload post. <br>
  - - User profiles. <br>
  - - Notifications. <br>
  - - User search menu. <br>
  - - Login screen. <br>
  - - User ratings. <br>
  - - Account user profile settings. <br>
  - - Reset password screen. <br>
  - normalized emails to stop 2 account with 1 email. <br>
  - Added the ability to chat with other users. <br>
  - Switched back to using pop-ups instead of prompts at the bottom of the screen. <br>
  - Implemented dark mode for all prompts. <br>
  - Improved error messages. <br>
  - Introduced the ability to follow other users. <br>
  - Overhauled notifications, including: <br>
  - - Added a display for the number of unread notifications. <br>
  - - Fixed crashes when items were deleted. <br>
  - - Added on-device app notifications. <br>
  - - Clicking on items, such as replies, will open all parent items as well. <br>
  - Implemented a new menu for changing profile settings, such as bio and username. <br>
  - Added the ability to like ratings. <br>
  - Prompted web users to switch to the app. <br>
  - Eliminated freezing when uploading images. <br>
  - Changed the name to "Toaster" (with a capital 'T') instead of "toaster." <br>
  - Removed empty bio to streamline the user profile. <br>
  - Created a search menu on the homepage. <br>
  - Added account sign-up functionality. <br>
  - Implemented notifications for account logins. <br>
  - Added a tab to display ratings on user profiles. <br>
  - Introduced a counter for missed notifications and messages. <br>
  - Implemented crash reporting for both server and client. <br>
  - Improved ban messages. <br>
  - Added prompts for accepting new licenses. <br>
  - Moved the kebab menu to a pop-up to maintain consistency with other menus. <br>
  - Added display for when rating and post was created <br> 
 
 <br>
  
 <b> 1.0.11 </b> <br>
 - added notifications  <br>
 - - ratings for posts  <br>
 - - replys to ratings  <br>
 - fixed mobile app ratings not loading  <br>
 <br>
 
 <b> 1.0.10 </b> <br>
 - added ratings to cache  <br>
 - added user profiles to cache  <br>
 - made cache test if updated after use  <br>
 <br>
 
 <b> 1.0.9 </b> <br>
 - moved over to hive  <br>
 - improved cache system  <br>
 - - auto expire for profile and basic user data  <br>
 - - auto expire for all cache data  <br>
 <br>
 
 <b> 1.0.8 </b> <br>
 - added comment replying  <br>
 - removed leaderboards  <br>
 <br>
 
 <b> 1.0.7 </b> <br>
  - created changelog  <br>
  - renamed invalid token error  <br>
  - made links clickable on text fields  <br>
  - made text copyable on text fields  <br>
  - fixed settings and logout button showing on other users profiles  <br>
  - added rankings to player list <br>
  "#)
}
