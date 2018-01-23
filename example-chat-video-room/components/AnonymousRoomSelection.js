import React from 'react';
import { StyleSheet, Text, TextInput, Button, Keyboard, View, Alert, PushNotificationIOS } from 'react-native';
import config from '../config.json'
import ntmService from './NotificationService.js';
import {IrisRtcSdk} from 'react-native-iris-sdk';
var alertInProgress = false;

// Room selection class
export default class AnonymousRoomSelection extends React.Component {
  
  static navigationOptions = {
    title: 'Enter a room to join',
  };

  // Constructor
  constructor(props) {
    super(props);
    this.state = {
                  RoomId: '',
                  RoomIds: [],
                  text: ''
                 };
    
  };

  // Start init here
  componentDidMount() {  

    this.initNotification(this.props.navigation.state.params.token);
  }

  // Start deinit here
  componentWillUnmount() {
    console.log('componentWillUnmount ');
  }
  
  // Render function
  render() {
    const { navigate, state } = this.props.navigation;

    return (
      <View style={styles.container}>

        <TextInput ref='roomname' 
          style={{height:40, borderColor: 'gray', color: 'black',  borderWidth: 1}}
          placeholder='Please enter the participant public id to chat with'
          placeholderTextColor='black'
          onChangeText={(text) => this.setState({text})}
          value={this.state.text}
          onEndEditing={this.clearFocus}
        />
        <Button
          style={{height: 40, borderColor: 'gray', borderWidth: 1}}
          onPress={() => {
            // Check if the text is entered
            if (this.state.text == '')
            {
              Alert.alert(
                'Iris Messenger',
                'Please enter a room and then press join '
              );
              return;
            }
            // Check if the token is obtained
            if (state.params.token == '')
            {
              Alert.alert(
                'Iris Meet',
                'Please wait for login or see if there are errors in login '
              );
              return;
            }

            Keyboard.dismiss(); 

            if(this.state.text && state.params.token){

              console.log(' Get routing id for the participant ' + this.state.text);

              var self = this;

                // Call createroom of evm to get a room id
              fetch("https://"+config.urls.eventManager + "/v1/createroom/room/"+ this.state.text, {
                method : "PUT",
                headers : {
                  "Authorization": "Bearer " + state.params.token,
                  "Content-Type": "application/json",
                },
                body: JSON.stringify({"participants":""})
              })
              .then(response => {
                console.log(' createroom returned response code ' + response.status);
                if (response.status >= 200 && response.status < 300) {
                    return response;
                  } else {
                    let error = new Error(response.statusText);
                    error.response = response;
                    throw error;
                  }
              })
              .then(response => response.json())
              .then((response) => {
                let roomId = response.room_id;
                var config = {
                  SessionType: 'outgoing',
                  NotificationData: ''
                };
                // Move to different screen in navigation
                  navigate('RoomView', 
                                    { 
                                        token: state.params.token, 
                                        routingId: state.params.routingId,
                                        roomId:  response.room_id,
                                        mode: 'chat',
                                        videoConfig: config,
                                        audioConfig: {},
                                    });

                
              })
              .catch((error) => {
                console.log("Error while getting roomid ", error);
              })/*
              var  routingId = "2675163255" + '@' + config.domain;

              // Call create room to get a room
                fetch('https://' + config.urls.eventManager +  '/v1/createroom/participants', {
                    method: 'PUT',
                    headers: {
                        'Authorization': 'Bearer ' + state.params.token,
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                            participants: [{'notification': true, 
                                            'owner': true, 
                                            'room_identifier': true, 
                                            'history': true,
                                            'routing_id': routingId
                                          },
                                          {'notification': true, 
                                            'owner': true, 
                                            'room_identifier': true, 
                                            'history': true,
                                            'routing_id': state.params.routingId
                                          }],
                        })
                    }).then(response => {
                        setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
                        return response.json()
                    })
                    .then((responseData) => {
                        console.log(' CreateRoom returned response ' + JSON.stringify(responseData));
                        if (responseData.room_id)
                        {
                            // Move to different screen in navigation
                            navigate('RoomView', 
                                    { 
                                        token: state.params.token, 
                                        routingId: state.params.routingId,
                                        roomId:  responseData.room_id,
                                        mode: 'chat',
                                        Config: {},
                                        audioConfig: {},
                                    });
                        }
                        else
                        {
                            throw new Error("room_id doesn't exist");
                        }
                    })
                    .catch(function(err) {
                        console.log(' CreateRoom returned an error  ' + err );
                    })
                    .done();*/
            }
          }}
          title="Join"
          color="#841584"
        />
      </View>
    );
  }
  initNotification(appToken)
    {
      // Observe events
      PushNotificationIOS.addEventListener('notification', function(event) {
          console.log("Received notification " + event);
      });

      PushNotificationIOS.addEventListener('localNotification', function(event) {
          console.log("Received localNotification " + event);
      });

      PushNotificationIOS.addEventListener('register', function(token) {
          console.log("Received register " + token);
          ntmService.registerWithNTM(token, 'apns', config.domain, appToken, function (event)
          {
              // Success
              console.log('register success with ' + JSON.stringify(event));
              //ntmService.subscribe()
          });

      });

      PushNotificationIOS.addEventListener('registrationError', function(event) {
          console.log("Received registrationError " + event);
      });
      PushNotificationIOS.requestPermissions();

      var self = this;
      // Callback for notification
      IrisRtcSdk.events.addListener('onNotification', function(data) {
        console.log("Notification received with [" + JSON.stringify(data) + "]");
        if (alertInProgress)
          return;
        // check the type if it is 'notify'
        if (data.type == 'notify')
        {
          var userdata = JSON.parse(data.userdata);
          var cname = '';
          if (userdata && userdata.data && userdata.data.cname)
          {
              cname = userdata.data.cname;
          }
          alertInProgress = true;

          Alert.alert(
            'Incoming call',
            'Received a call from ' + cname + ', do you want to accept?',
            [
              {text: 'Cancel', onPress: () => { 
                console.log('Cancel Pressed');
                alertInProgress = false;
              }, style: 'cancel'},
              {text: 'OK', onPress: () => {
                var _videoConfig = {
                  SessionType: 'incoming',
                  RoomToken: data.roomtoken,
                  RoomTokenExpiryTime: data.roomtokenexpirytime,
                  RtcServer: data.rtcserver
                };
                // Move to different screen in navigation
                self.props.navigation.navigate('RoomView', 
                        { 
                            token: self.props.navigation.state.params.token, 
                            routingId: self.props.navigation.state.params.routingId,
                            roomId:  data.roomid,
                            mode: 'video',
                            videoConfig: _videoConfig,
                            EnablePreview: true,
                            audioConfig: {},
                        });
              }},
            ],
            { cancelable: false }
          );
        }
      });
    }
  getRoomsFromEventManager(routingId, token)
  {
    console.log("Get rooms for routing ids " +  routingId);
    // Get rooms for routing ids
    fetch('https://' + config.urls.eventManager +  '/v1/view/rooms/routingid/' + routingId + '/records/' + 100, {
    method: 'GET',
    headers: {
        'Authorization': "Bearer " + token,
    }}).then(response => {
        console.log(' Get rooms for routing ids returned response code ' + response.status);
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
        console.log(' Get rooms for routing ids returned  response ' + JSON.stringify(responseData));
        responseData.forEach(function(element) {
          // Get rooms for routing ids
          fetch('https://' + config.urls.eventManager +  '/v1/view/rooms/routingid/' + routingId + '/room/' + element.room_id + '/records/' + 100, {
          method: 'GET',
          headers: {
              'Authorization': "Bearer " + token,
          }}).then(response => {
              console.log(' Get events for rooms returned response code ' + response.status);
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
              console.log(' Get events for rooms returned  response ' + JSON.stringify(responseData));
          })
          .catch(function(err) {
              console.log(' Get events for rooms returned an error  ' + err );
              Alert.alert(
                  'Get events for rooms returned an error',
                  'Get events for rooms returned an error '
              );
          })
          .done();
        }, this);

    })
    .catch(function(err) {
        console.log(' Get rooms for routing ids returned an error  ' + err );
        Alert.alert(
            'Get rooms for routing ids returned an error',
            'Get rooms for routing ids returned an error '
        );
    })
    .done();

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