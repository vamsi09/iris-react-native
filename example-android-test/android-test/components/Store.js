import { AsyncStorage } from "react-native";

module.exports = {
  IrisTokenResponse: "IrisTokenResponse",
  UserName: "UserName",
  Password: "Password",
  get(key) {
    return AsyncStorage.getItem(key).catch(err => {
      throw new Error(`[read failure] - ${err}`);
    });
  },
  set(key, value) {
    return AsyncStorage.setItem(key, value).catch(err => {
      throw new Error(`[Write failed] - ${err}`);
    });
  },
  del(key) {
    return AsyncStorage.removeItem(key).catch(err => {
      throw new Error(`[write failure] - ${err}`);
    });
  }
};
