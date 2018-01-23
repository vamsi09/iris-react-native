/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';

import { StyleSheet,AppRegistry, Text, TextInput, Button, Keyboard, View, Alert, PushNotificationIOS } from 'react-native';

import IrisRtcSdk from 'react-native-iris-sdk';

// Hard-coded values for testing
var irisToken=""
var RoutingId="";
var SessionId;
// Observe events

/*IrisRtcSdk.events.addListener('onCallConnecting', function(event) {
    console.log("onCallConnecting with sessionId", event.SessionId);
    SessionId = event.SessionId;
});
IrisRtcSdk.events.addListener('onCallRinging', function(event) {
    console.log("onCallRinging");
});
IrisRtcSdk.events.addListener('onCallConnected', function(event) {
    console.log("onCallConnected");

    setTimeout(function(){ 
        IrisRtcSdk.end(SessionId);
      }, 20000);

});
IrisRtcSdk.events.addListener('onCallDisconnected', function(event) {
    console.log("onCallDisconnected");
});*/

// Call connection method 




export default class irisdialer extends Component {
  
  constructor(){
    super();
    this.state = {isStarted: true,roomId: ""};
    

  }
  componentDidMount() {
    console.log('componentDidMount');
   


    IrisRtcSdk.events.addListener('onConnected', function(success) {
      console.log("Connection Successful with iris backend");
  
      // Let's make a call
      var config = {
                    idmUrl: 'idm.iris.comcast.net',
                    evmUrl: 'evm.iris.comcast.net',
                    token: irisToken,
                    domain: 'iristest.comcast.com',
                    routingId: RoutingId,
                    sourceTN: '2676066437'
                    };
     // IrisRtcSdk.dial("2149230283", config);
  });
  IrisRtcSdk.events.addListener('onDisconnected', function(disconnected) {
      console.log("Connection disconnected from iris backend");
  
  });
  IrisRtcSdk.events.addListener('onConnectionError', function(error) {
      console.log("Failed with error [" + JSON.stringify(error) + "]");
  });
  IrisRtcSdk.events.addListener('onSessionSIPStatus', function(event) {
      console.log("onSessionSIPStatus = " + JSON.stringify(event) + "]");
  });

  IrisRtcSdk.events.addListener('onSessionCreated', function(event) {
    console.log("onSessionCreated = " + JSON.stringify(event) + "]");
    this.setState({ roomId: event.SessionId });
}.bind(this));

  
  IrisRtcSdk.connectUsingServer("https://evm.iris.comcast.net", irisToken, RoutingId);

  }
  
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to Iris PSTN Call feature!
        </Text>
        <Text style={styles.instructions}>
          Press start for initiating the call
        </Text>
        <Button style={{height: 50, borderColor: 'gray', borderWidth: 1}}
        title={this.state.isStarted ? "start": "stop"}
        color="#841584"
        onPress={() => {
          
          console.log('pressed button');
          if(this.state.isStarted){
           
            this.setState({ isStarted: false });
            var config = {
                  idmUrl: 'idm.iris.comcast.net',
                  evmUrl: 'evm.iris.comcast.net',
                  token: irisToken,
                  domain: 'iristest.comcast.com',
                  routingId: RoutingId,
                  sourceTN: '<source number>'
                  };
         IrisRtcSdk.dial("<tareget number>", config);
            
          }
          else{
          
            this.setState({ isStarted: true });
            IrisRtcSdk.endAudioSession(this.state.roomId);
          }
          
        }
        }
        />
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('irisdialer', () => irisdialer);
