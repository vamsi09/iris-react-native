import React from 'react';
import { StyleSheet, Text, TextInput, Button, Keyboard, View, Alert, PushNotificationIOS } from 'react-native';
import config from '../config.json'
import {IrisRtcSdk} from 'react-native-iris-sdk';

// Room selection class
export default class RoomSelection extends React.Component {
  
  static navigationOptions = {
    title: 'Select the participant',
  };

  // Constructor
  constructor(props) {
    super(props);
    this.state = {
                  RoomId: '',
                  RoomIds: [],
                  text: 'sdkwire3@gmail.com'
                 };
    
  };

  // Start init here
  componentDidMount() {  
    // Callback for notification
    IrisRtcSdk.events.addListener('onNotification', function(data) {
      console.log("Notification received with [" + JSON.stringify(data) + "]");
      var userdata = JSON.parse(data.userdata);
      if (this.props.screenProps.currentScreen != 'RoomSelection')
        return;
      /*Alert.alert(
        'Iris Messenger',
        'Received the text ' + userdata.data.text
      );      // Got a chat request, let's move to to roomview*/

      var config = {
        SessionType: 'outgoing',
        NotificationData: ''
      };
      // Move to different screen in navigation
      this.props.navigation.navigate('RoomView', 
      { 
          token: this.props.navigation.state.params.token, 
          routingId: this.props.navigation.state.params.routingId,
          roomId:  data.roomid,
          mode: 'chat',
          videoConfig: config,
          audioConfig: {},
          toPublicId: this.state.text,
          toRoutingId: data.routingid
      });

    }.bind(this));
  }

  
  // Start deinit here
  componentWillUnmount() {
    console.log('componentWillUnmount ');
    IrisRtcSdk.events.removeListener('onNotification', this.onNotificationListener.bind(this)); 
  }

  componentWillReceiveProps(nextProps){
    console.log('RoomSelection:: Current screen ' + nextProps.screenProps.currentScreen);
    
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

              // Get routing id for the participant
              fetch("https://"+ config.urls.idManager + "/v1/routingid/appdomain/"+ config.domain + '/publicid/' + this.state.text, {
                method : "GET",
                headers : {
                  "Authorization": "Bearer " + state.params.token,
                  "Content-Type": "application/json",
                }
              })
              .then(response => {
                console.log(' Get routing id for the participant returned response code ' + response.status);
                if (response.status == 200) {
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
              .then((response) => {
                console.log(' Get routing id for the participant returned response ' + JSON.stringify(response) );
                var toRoutingId = response.routing_id;
                // Call createroom of evm to get a room id
                fetch("https://"+ config.urls.eventManager + "/v1/createroom/participants", {
                  method : "PUT",
                  headers : {
                    "Authorization": "Bearer " + state.params.token,
                    "Content-Type": "application/json",
                  },
                  body: JSON.stringify({
                            participants: [{'notification': true, 
                                            'owner': true, 
                                            'room_identifier': true, 
                                            'history': true,
                                            'routing_id': state.params.routingId
                                          },
                                          {'notification': true, 
                                            'owner': true, 
                                            'room_identifier': true, 
                                            'history': true,
                                            'routing_id': response.routing_id
                                          }],
                        })
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
                .then(response => {
                    setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
                    return response.json()
                })
                .then((response) => {
                  console.log(' createroom returned response ' + JSON.stringify(response) );

                  var userdata = {  
                     "data":{  
                        "cid":"",
                        "cname":""
                     },
                     "notification":{  
                        "topic":"iristest.comcast.com/video",
                        "type":"video"
                     }
                  };
                  var config = {
                    SessionType: 'outgoing',
                    NotificationData: JSON.stringify(userdata)
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
                                                  toPublicId: this.state.text,
                                                  toRoutingId: toRoutingId
                                              });

                })
                .catch((error) => {
                  console.log("createroom returned an error ", error);
                })

              })
              .catch((error) => {
                console.log("Error while getting roomid ", error);
              })
            }
          }}
          title="Join"
          color="#841584"
        />
      </View>
    );
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