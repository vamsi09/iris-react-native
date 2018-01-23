var Buffer = require("buffer").Buffer;
import config from '../config.json'

const LOGIN_URL = "https://" + config.urls.authManager + "/v1/login/";
const REGISTER_URL = "https://" + config.urls.authManager + "/v1/user/";
const APP_DOMAIN = config.domain;
const APP_KEY = config.appKey;
const APP_SECRET = config.appSecret;

// record data and mark success
var store = require("./Store");

class AuthService {
  login(creds, cb) {
    const userName = creds.username;
    const password = creds.password;

    const authHeader =
      "Basic " + new Buffer(APP_KEY + ":" + APP_SECRET).toString("base64");

    fetch(LOGIN_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: authHeader
      },
      body: JSON.stringify({
        Type: "Email",
        Email: userName,
        Name: userName,
        Password: password
      })
    })
      .then(response => {
        setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
        if (response.headers.get("Content-Type") == "application/json") {
          return response.json();
        }

        throw response.body.text;
      })
      .then(authTokenResponse => {
        console.log("Response JSON", JSON.stringify(authTokenResponse));

        if (authTokenResponse.error) {
          throw new Error(authTokenResponse.error.message);
        }
       /* store.set(store.IrisToken, JSON.stringify(authTokenResponse));
        store.set(store.UserName, userName);
        store.set(store.Password, password);*/

        cb({ success: true, TokenResponse: authTokenResponse });
      })
      .catch(error => {
        cb({ error: error.toString() });
      })
      .finally(() => {});
  }
}

module.exports = new AuthService();
