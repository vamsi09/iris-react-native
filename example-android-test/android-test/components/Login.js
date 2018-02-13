import React from 'react';
import { StyleSheet, Text, Button, View, Alert } from 'react-native';
import {IrisRtcSdk} from 'react-native-iris-sdk';
import config from '../config.json'

var randomUserId = Math.random().toString(36).substr(2, 20) + '@' + config.domain;


class LoginScreen extends React.Component {
  
  static navigationOptions = {
    title: 'Login',
  };

  // Constructor
  constructor(props) {
    super(props);
        this.state = {
                  token: '',
                 };
  };

  // Start init here
  componentWillMount() {
    if (config.appKey == "")
    {
      Alert.alert(
                'Iris Messenger',
                'Please set the appkey and domain before you start '
              );
      return;
    }
  }

  // Start deinit here
  componentWillUnmount() {
    console.log('componentWillUnmount ');

    IrisRtcSdk.disconnect();
  }

  // Render function
  render() {
    const { navigate } = this.props.navigation;
    return (
      <View style={styles.container}>
        <Button
          style={{height: 40, borderColor: 'gray', borderWidth: 1}}
          onPress={() => {
                // Call anonymous login to get a iris token
                fetch('https://' + config.urls.authManager +  '/v1/login/anonymous/', {
                method: 'POST',
                headers: {
                    'X-App-Key': config.appKey,
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                        UserID: randomUserId,
                    })
                }).then(response => {
                        console.log(' Anonymous login returned response code ' + response.status);
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
                    console.log(' Anonymous login returned response ' + JSON.stringify(responseData));
                    //responseData.Token = '';
                    //randomUserId = '';
                    this.setState({token:responseData.Token});
                    
                    this.makeIrisConnection(responseData.Token, randomUserId);

                    // Move to different screen in navigation
                    navigate('RoomSelection', 
                                            { 
                                                token: responseData.Token, 
                                                routingId: randomUserId 
                                            });

                })
                .catch(function(err) {
                    console.log(' Anonymous login returned an error  ' + err );
                    Alert.alert(
                        'Iris Messenger',
                        'Error in login, please check credentials '
                    );
                })
                .done();
            }
          }
          title="Anonymous Login"
          color="#841584"
        />
      </View>
    );
  }
  // Make a connection with iris backend
  makeIrisConnection(token, routingId){
    // Observe events
    IrisRtcSdk.events.addListener('onConnected', function(success) {
        console.log("Connection Successful with iris backend");
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
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
});
export {LoginScreen};
export default LoginScreen;