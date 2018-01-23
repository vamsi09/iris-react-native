import React, { Component } from "react";
import {
  AppRegistry,
  StyleSheet,
  View,
  Text,
  TouchableHighlight,
  TextInput,
  ActivityIndicator,
  Alert
} from "react-native";
import authService from './AuthService.js' 
import config from '../config.json'
import {IrisRtcSdk} from 'react-native-iris-sdk';

var randomUserId = Math.random().toString(36).substr(2, 20) + '@' + config.domain;

export default class LoginView extends Component {
  static navigationOptions = {
    title: 'Login',
  };
  constructor(props) {
    super(props);
    this.state = {
      userName: "sdkwire2@gmail.com",
      password: "sdkwire2",
      showProgress: false
    };
  }
  showDashboard() {
    const { navigate } = this.props.navigation;

    // show the progress spinner, this will re-render
    this.setState({ showProgress: true });

    // login using email credentials
    authService.login(
      {
        username: this.state.userName,
        password: this.state.password
      },
      results => {
        // dismiss the spinner
        this.setState({ showProgress: false });

        // if there was an error
        if (results.error) {
          // show error to the user
          this.setState({ error: results.error });
        } else {
          //handle success
          
          // Call IDM to get the ids
          fetch('https://' + config.urls.idManager +  '/v1/allidentities', {
          method: 'GET',
          headers: {
              'Authorization': "Bearer " + results.TokenResponse.Token,
          }}).then(response => {
              console.log(' Get identities returned response code ' + response.status);
              if (response.status >= 200 && response.status < 300) {
                  return response;
              } else {
                  let error = new Error(response.statusText);
                  error.response = response;
                  throw error;
              }
          })
          .then(response => {
            setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
            return response.json()
          })
          .then((responseData) => {          
              console.log(' Get identities returned  response ' + JSON.stringify(responseData));

              this.makeIrisConnection(results.TokenResponse.Token, responseData.routing_id);

              // Move to different screen in navigation
              navigate('RoomSelection', 
                                      { 
                                          token: results.TokenResponse.Token, 
                                          routingId: responseData.routing_id,
                                          publicId: responseData.public_ids
                                      });

          })
          .catch(function(err) {
              console.log(' Get identities returned an error  ' + err );
              Alert.alert(
                  'Get identities',
                  'Error in getting identities '
              );
          })
          .done();
        }
      }
    );
  }

  //
  render() {
    var errorLabel = <View />;

    if (this.state.error) {
      errorLabel = <Text style={styles.error}>{this.state.error}</Text>;
    }

    return (
      <View style={styles.container}>
        <Text style={styles.banner}>PhoneWire</Text>
        <TextInput
          style={styles.input}
          placeholder="Enter Email Id"
          value={this.state.userName}
          autoCorrect={false}
          autoCapitalize="none"
          onChangeText={text => this.setState({ userName: text, error: "" })}
        />
        <TextInput
          style={styles.input}
          secureTextEntry={true}
          placeholder="Enter password"
          autoCorrect={false}
          autoCapitalize="none"
          value={this.state.password}
          onChangeText={text => this.setState({ password: text, error: "" })}
        />
        {errorLabel}

        <TouchableHighlight style={styles.button}>
          <Text style={styles.btnLabel} onPress={this.showDashboard.bind(this)}>
            Sign In
          </Text>
        </TouchableHighlight>

        <ActivityIndicator
          style={styles.activityIndicator}
          size="large"
          animating={this.state.showProgress}
        />
      </View>
    );
  }
  // Make a connection with iris backend
  makeIrisConnection(token, routingId){
    var self = this;
    // Observe events
    IrisRtcSdk.events.addListener('onConnected', function(success) {
        console.log("Connection Successful with iris backend");
        // Subscribe for notifications
        self.sendSubscriptionRequest(token, routingId);
    });
    IrisRtcSdk.events.addListener('onDisconnected', function(disconnected) {
        console.log("Connection disconnected from iris backend");

    });
    IrisRtcSdk.events.addListener('onConnectionError', function(error) {
        console.log("Failed with error [" + JSON.stringify(error) + "]");
    });
    // Call connection method 
    IrisRtcSdk.connectUsingServer('https://' + config.urls.eventManager, token, routingId);


  }

  sendSubscriptionRequest(token, routingId)
  {
    var self = this;
    
    // Call IDM to get the ids
    fetch('https://' + config.urls.notificationManager +  '/v1/subscriber/', {
      method: 'POST',
      headers: {
          'Authorization': "Bearer " + token,
          'Content-Type': 'application/json',
      },
      body: JSON.stringify({ "app_domain": config.domain, "proto": "xmpp", "token": routingId })
      }).then(response => {
          console.log(' sendSubscriptionRequest returned response code ' + response.status);
          if (response.status >= 200 && response.status < 300) {
              return response;
          } else {
              let error = new Error(response.statusText);
              error.response = response;
              throw error;
          }
      })
      .then(response => {
        setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
        return response.json()
      })
      .then((responseData) => {          
          console.log(' sendSubscriptionRequest returned  response ' + JSON.stringify(responseData));

          // Send topic request
          var jsonResponse = JSON.parse(responseData);

          // token details
          var subscriberId = jsonResponse.id;
          
          // Subscribe to topic
          var videoTopic = encodeURIComponent(config.domain + "/" + "video" + "/" + routingId);
          var audioTopic = encodeURIComponent(config.domain + "/" + "audio" + "/" + routingId);
          var chatTopic = encodeURIComponent(config.domain + "/" + "chat" + "/" + routingId);
          self.sendSubscribeTopicRequest(subscriberId, videoTopic, token);
          self.sendSubscribeTopicRequest(subscriberId, audioTopic, token);
          self.sendSubscribeTopicRequest(subscriberId, chatTopic, token);
          
          //if(domain == "xfinityvoice.comcast.com"){
          //var pstnTopic = encodeURIComponent("federation" + "/" + "pstn" + "/" + routingId);
          //self.sendSubscribeTopicRequest(subscriberId, pstnTopic);

      })
      .catch(function(err) {
          console.log(' sendSubscriptionRequest returned an error  ' + err );
      })
      .done();
  }

  sendSubscribeTopicRequest(subscriberId, topic, token)
  {
    console.log(' sendSubscribeTopicRequest with ' +  subscriberId + ' & topic as ' + topic );
    var subscriptionPath = "/v1/subscription/subscriber/" + subscriberId + "/topic/" + topic;
    // Call IDM to get the ids
    fetch('https://' + config.urls.notificationManager +  subscriptionPath, {
      method: 'POST',
      headers: {
          'Authorization': "Bearer " + token,
          'Content-Type': 'application/json',
      }      
     }).then(response => {
          console.log(' sendSubscribeTopicRequest returned response code ' + response.status);
          if (response.status >= 200 && response.status < 300) {
              return response;
          } else {
              let error = new Error(response.statusText);
              error.response = response;
              throw error;
          }
      })
      .then(response => {
        setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
        return response.json()
      })
      .then((responseData) => {          
          console.log(' sendSubscribeTopicRequest returned  response ' + JSON.stringify(responseData));
      })
      .catch(function(err) {
          console.log(' Get sendSubscribeTopicRequest returned an error  ' + err );
      })
      .done();
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 10,
    backgroundColor: "#fff",
    alignItems: "center"
  },
  banner: {
    fontSize: 30,
    margin: 30,
    color: "#319ed9"
  },
  button: {
    height: 40,
    backgroundColor: "#319ed9",
    padding: 10,
    paddingLeft: 20,
    paddingRight: 20,
    margin: 10,
    borderRadius: 20
  },
  btnLabel: {
    flex: 1,
    color: "#FFF"
  },
  input: {
    height: 40,
    borderColor: "#000",
    borderStyle: "solid",
    marginTop: 10
  },
  activityIndicator: {
    alignItems: "center",
    justifyContent: "center",
    padding: 8
  },
  error: {
    color: "red",
    padding: 10
  }
});
