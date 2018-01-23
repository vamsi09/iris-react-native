import React from 'react';
import { StyleSheet, Text, TextInput, Button, Keyboard, View, Alert, TouchableHighlight } from 'react-native';
import config from '../config.json'
import {IrisRoomContainer, IrisRtcSdk, IrisVideoView} from 'react-native-iris-sdk';
import { GiftedChat } from 'react-native-gifted-chat';
import Ionicons from 'react-native-vector-icons/Ionicons'
import MaterialCommunityIcons from 'react-native-vector-icons/MaterialCommunityIcons'
var alertInProgress=false;
// Room view
export default class RoomView extends React.Component {

    // Add a custom button to enable video and audio
    static navigationOptions = ({ navigation }) => {
    const {state, setParams} = navigation;
    return {
        title: 'Chat',
        headerRight: (
                    <View style={{flex: 1, flexDirection: 'row', alignItems:'center', justifyContent:'center'}}>
                    <View>
                        <TouchableHighlight style={{marginRight: 15}} onPress={() => 
                            { 
                                if (state.params.makeAudioCall)
                                {
                                    setParams({ makeAudioCall: false, audioConfig: {}});
                                    return;
                                }
                                if (state.params.mode == 'chat')
                                {
                                    var userdata = {  
                                                        "data":{  
                                                            "cid":"",
                                                            "cname":""
                                                        },
                                                        "notification":{  
                                                            "topic":config.domain+'/video',
                                                            "type":"video"
                                                        }
                                                    };

                                    let _Config = {
                                                    SessionType: 'outgoing',
                                                    NotificationData: JSON.stringify(userdata)
                                                };
                                    console.log('Video Button called' );
                                    setParams({ mode: 'video', videoConfig: _Config, EnablePreview: true});
                                }
                                else
                                {
                                    setParams({ mode: 'chat', videoConfig: {}, EnablePreview: false});
                                    alertInProgress = false;
                                }
                            }}>
                        <Ionicons name={(state.params.mode=='chat' && ((typeof state.params.makeAudioCall == 'undefined') ||  (state.params.makeAudioCall==false))) ? 'ios-videocam-outline' : 'ios-close-circle-outline'} size={30}/>
                        </TouchableHighlight>
                    </View>
                    <View>
                        <TouchableHighlight style={{marginRight: 15}} onPress={() => { 
                                if (state.params.mode == 'chat')
                                {
                                    let _Config = {
                                                    SessionType: 'outgoing',
                                                    ParticipantId: '2242251234' + '@' +'iristest.comcast.com',
                                                    NotificationData: '',
                                                    SourceTN: '2674550136',
                                                    DestinationTN: '2242251234'
                                            };
                                    console.log('Audio Button called');
                                    setParams({ makeAudioCall: true, audioConfig: _Config});
                                }
                                else
                                {
                                    setParams({ makeAudioCall: false, audioConfig: {}});
                                }
                            }}>
                        <Ionicons name={((typeof state.params.makeAudioCall == 'undefined') ||  (state.params.makeAudioCall==false)) ? 'ios-call-outline': 'ios-chatboxes-outline'} size={30}/>
                        </TouchableHighlight>
                    </View>
                    </View>
        ),
    };
    };

  // Constructor
  constructor(props) {
    super(props);
    this.state = {
                  RoomId: '',
                  Type: this.props.navigation.state.params.mode,
                  messages: [],
                  Config: this.props.navigation.state.params.Config,
                  bottomOffset: '',
                  ThumbnailStreamIds: [],
                   StreamDictionary: {},
                   preferredRoutingId: 'local',
                 };
    
  };

  // Start init here
  componentDidMount() {  

      this.setState({
        messages: [
        {
          _id: this.props.navigation.state.params.routingId,
          text: 'Hello developer',
          createdAt: new Date(),
          user: {
            _id: 2,
            name: 'React Native',
            avatar: 'https://facebook.github.io/react/img/logo_og.png',
          },
        },
      ],

    });  

    this.ListenToNotifications();
  }

  // Start init here
  componentWillReceiveProps(props)
  {  
    if (this.props.navigation.state.params.makeAudioCall != props.navigation.state.params.makeAudioCall)
    {
        // Check if makeaudiocall is true
        if (props.navigation.state.params.makeAudioCall)
        {
            // Get the room id for pstn call
            this.getRoomIdForPstnCall(
                roomId => {
                    this._IrisRoomContainer.createAudioSession(roomId, 
                        props.navigation.state.params.audioConfig);
                    this.setState({audioRoomId: roomId});
                },
                failureCb => {
                }
            );
            
            
        }
        else
        {
            this._IrisRoomContainer.endAudioSession(this.state.audioRoomId);
        }
    }
  }

  // Start deinit here
  componentWillUnmount() {
    console.log('componentWillUnmount ');
    this._IrisRoomContainer.endSession(this.props.navigation.state.params.roomId);
  }
  renderASingleThumbnail(_StreamId) {
    return <IrisVideoView style={styles.thumbnail} key={_StreamId} StreamId={_StreamId} />;
  }
  renderThumbnails(mode, ThumbnailStreamIds) {
      if (mode == 'chat' || mode == 'audio')
      {
        return null;
      }
      else
      {
        return ThumbnailStreamIds.map(this.renderASingleThumbnail);
      }
  }
  renderMainVideoView(mode)
  {
      if (mode == 'chat' || mode == 'audio')
      {
        return null;
      }
      else
      {
          return <IrisVideoView style={{
                    top: 0,
                    left: 0,
                    height: '100%',
                    width: '100%',
                    position: 'absolute'
                    }}
                ref={(IrisVideoView) => { this._MainIrisVideoView = IrisVideoView; }}
                StreamId={this.state.MainStreamId}
                onStreamError={this.onStreamError.bind(this)}
              />;
      }
  }
  renderChatView(mode) {
    if (mode == 'chat')
    {
        return <GiftedChat style={{
                    }}
                    messages={this.state.messages}
                    bottomOffset={this.state.chatbottomoffset}
                    onSend={(messages) => this.onSend(messages)}
                    user={{
                    _id: this.props.navigation.state.params.routingId,
                }}
            />;
    }
    else
    {
        return null;
    }
  }

  renderThumbnailView(mode){
    if (mode != 'chat'){
       return <View style={{
            right: 0,
            bottom: 0,
            height: '20%',
            width: '100%',
            position: 'absolute',
       }}>
            <View style={{
            flex: 1,
            flexDirection: 'row',
            justifyContent: 'flex-end',
            alignItems: 'flex-end',
            }}>
                {this.renderThumbnails(mode, this.state.ThumbnailStreamIds)}
            </View>
        </View>;
    }
    else{
        return null;
    }

  }
  // Render function
  render() {
    const { navigate, state } = this.props.navigation;
    return (
            <View style={{flex: 1}}>
                <IrisRoomContainer 
                    ref={(IrisRoomContainer) => { this._IrisRoomContainer = IrisRoomContainer; }}
                    Type={state.params.mode}
                    EnablePreview={state.params.EnablePreview}
                    RoomId={state.params.roomId}
                    evmUrl={config.urls.eventManager}
                    routingId={state.params.routingId}
                    token={state.params.token}
                    audioConfig={state.params.audioConfig}
                    videoConfig={state.params.videoConfig}
                    onSessionCreated={this.onSessionCreated.bind(this)}
                    onSessionConnected={this.onSessionConnected.bind(this)}
                    onSessionDisconnected={this.onSessionDisconnected.bind(this)}
                    onSessionSIPStatus={this.onSessionSIPStatus.bind(this)}
                    onSessionTypeChanged={this.onSessionTypeChanged.bind(this)}
                    onSessionError={this.onSessionError.bind(this)}
                    onChatMessage={this.onChatMessage.bind(this)}
                    onChatMessageAck={this.onChatMessageAck.bind(this)}
                    onChatMessageError={this.onChatMessageError.bind(this)}
                    onSessionParticipantJoined={this.onSessionParticipantJoined.bind(this)}
                    onSessionParticipantLeft={this.onSessionParticipantLeft.bind(this)}
                    onSessionParticipantConnected={this.onSessionParticipantConnected.bind(this)}
                    onSessionDominantSpeakerChanged={this.onSessionDominantSpeakerChanged.bind(this)}
                    onStreamError={this.onStreamError.bind(this)}
                    onLocalStream={this.onLocalStream.bind(this)}
                    onRemoteAddStream={this.onRemoteAddStream.bind(this)}
                    onRemoteRemoveStream={this.onRemoteRemoveStream.bind(this)}
                    onEventHistory={this.onEventHistory.bind(this)}
               />
             {this.renderChatView(state.params.mode)}
             {this.renderMainVideoView(state.params.mode)}
             {this.renderThumbnailView(state.params.mode)}
             
            </View>
        );
    }

    // Adjust the view based on the preferred routing id
    adjustView(preferredRoutingId)
    {
        var _ThumbnailStreamIds = [];
        for (var routingId in this.state.StreamDictionary) {
            if (routingId != preferredRoutingId)
                _ThumbnailStreamIds.push(this.state.StreamDictionary[routingId]);
        }
        this.setState({ 
            ThumbnailStreamIds: _ThumbnailStreamIds,
            MainStreamId: this.state.StreamDictionary[preferredRoutingId]
        });
        console.log("Thumbnails " + this.state.ThumbnailStreamIds)
    }
    // Gifted chat send message
    onSend(messages = []) {
        this.setState((previousState) => ({
        messages: GiftedChat.append(previousState.messages, messages),
        }));
        var self = this;
        messages.forEach(function (message)
        {
            if (self._IrisRoomContainer != null)
                self._IrisRoomContainer.sendChatMessage(message._id, message.text );
        });
    }

    onSessionCreated(event){
        console.log("ReactApp --- onSessionCreated" +   JSON.stringify(event));
    }

    onSessionConnected(event){
        console.log("ReactApp --- onSessionConnected" + JSON.stringify(event));
    }
    
    onSessionTypeChanged(event){
        console.log("ReactApp --- onSessionTypeChanged" + JSON.stringify(event));
        const {state, setParams } = this.props.navigation;
        if (event.SessionType == 'groupchat' && this.props.navigation.state.params.mode == 'video')
        {
            Alert.alert(
                'Incoming Notification',
                'Remote participant has changed the mode to groupchat , do you want to downgrade?',
                [
                  {text: 'Cancel', onPress: () => { 
                    console.log('Cancel Pressed');
                  }, style: 'cancel'},
                  {text: 'OK', onPress: () => {
                    setParams({ mode: 'chat', videoConfig: {}, EnablePreview: false});
                  }},
                ],
                { cancelable: false }
              );
        }
    }
    onSessionDisconnected(event){
        console.log("ReactApp --- onSessionDisconnected" + JSON.stringify(event));
        /*if (this.state.Type == 'chat')
        {
            this._IrisRoomContainer.endChatSession(this.props.navigation.state.params.roomId);
        }
        if (this.state.Type == 'audio')
        {
            this._IrisRoomContainer.endAudioSession(this.props.navigation.state.params.roomId);
        }
        if (this.state.Type == 'video')
        {
            this._IrisRoomContainer.endVideoSession(this.props.navigation.state.params.roomId);
        }*/
    }

    onSessionSIPStatus(event){
        console.log("ReactApp --- onSessionSIPStatus" + JSON.stringify(event));
    }

    onSessionError(event){
        console.log("ReactApp --- onSessionError" + JSON.stringify(event));
    }
    
    onSessionParticipantJoined(event){
        console.log("ReactApp --- onSessionParticipantJoined" + JSON.stringify(event));
    }

    onSessionParticipantLeft(event){
        console.log("ReactApp --- onSessionParticipantLeft" + JSON.stringify(event));
        var _StreamDictionary = this.state.StreamDictionary;
        if (_StreamDictionary[event.RoutingId])
          delete _StreamDictionary[event.RoutingId];
        this.setState({
          StreamDictionary: _StreamDictionary
        });
        this.adjustView(this.state.preferredRoutingId);
    }

    onSessionParticipantConnected(event){
        console.log("ReactApp --- onSessionParticipantConnected" + JSON.stringify(event));
    }

    onSessionDominantSpeakerChanged(event){
        console.log("ReactApp --- onSessionDominantSpeakerChanged" + JSON.stringify(event));
        // Check if we are talking
        if (event.RoutingId.split('/')[0] == this.props.navigation.state.params.routingId)
        {
          return;
        }

        this.setState({
            preferredRoutingId: event.RoutingId
        });
          
        this.adjustView(this.state.preferredRoutingId);
    }

    onStreamError(event){
        console.log("ReactApp --- onStreamError" + JSON.stringify(event));
    }

    onLocalStream(event){
        console.log("ReactApp --- onLocalStream" + JSON.stringify(event));
        var _StreamDictionary = this.state.StreamDictionary;
        _StreamDictionary['local'] = event.StreamId;
        this.setState({
          MainStreamId:event.StreamId,
          StreamDictionary: _StreamDictionary
        });
    }

    onRemoteAddStream(event){
        console.log("ReactApp --- onRemoteAddStream" + JSON.stringify(event));
        var _StreamDictionary = this.state.StreamDictionary;
        _StreamDictionary[event.RoutingId] = event.StreamId;
        this.setState({
          StreamDictionary: _StreamDictionary
        });

        // This is the first remote view
        if (Object.keys(this.state.StreamDictionary).length == 2)
        {
          this.setState({
            preferredRoutingId: event.RoutingId
          });
        }
        this.adjustView(this.state.preferredRoutingId);
    }

    onRemoteRemoveStream(event){
        console.log("ReactApp --- onRemoteRemoveStream" + JSON.stringify(event));
        var _StreamDictionary = this.state.StreamDictionary;
        if (_StreamDictionary[event.RoutingId])
          delete _StreamDictionary[event.RoutingId];
        this.setState({
          StreamDictionary: _StreamDictionary
        });
        this.adjustView(this.state.preferredRoutingId); 
    }
  
    onEventHistory(events){
        console.log("ReactApp --- onEventHistory" + JSON.stringify(events));
        var self = this;
        events.reverse().forEach(function (event)
        {
           var message=
            {
                _id: Math.random().toString(36).substr(2, 20),
                text: '---' + event.event_type + '---',
                createdAt: new Date(event.time_received),
                user: {
                    _id: event.routing_id,
                    name: event.routing_id,
                    avatar: 'https://facebook.github.io/react/img/logo_og.png',
                },
            };
            if (event.event_type != 'chat')
            {
                if (event.routing_id == self.props.navigation.state.params.routingId)
                {
                    message.text = '--- ' + 'You initiated a ' +  event.event_type + ' ---';
                }
                else
                {
                    message.text = '--- ' + 'You were part of a ' +  event.event_type + ' ---';                    
                }
            }
            else
            {
                var userdata = JSON.parse(event.userdata);
                message.text = userdata.data.text;
            }

            self.setState((previousState) => ({
                messages: GiftedChat.append(previousState.messages, message),
            }));
        });
    }
    onChatMessage(event){
        console.log("ReactApp --- onChatMessage" + JSON.stringify(event));
        var message=
        {
            _id: event.messageId + Math.random().toString(36).substr(2, 20),
            text: event.data,
            createdAt: new Date(),
            user: {
                _id: event.participantId,
                name: event.participantId,
                avatar: 'https://facebook.github.io/react/img/logo_og.png',
            },
        };
        this.setState((previousState) => ({
            messages: GiftedChat.append(previousState.messages, message),
        }));
    }

    onChatMessageAck(event){
        console.log("ReactApp --- onChatMessageAck " + JSON.stringify(event));
    }

    onChatMessageError(event){
        console.log("ReactApp --- onChatMessageError " + JSON.stringify(event));
    }

    getRoomIdForPstnCall(successCb, failureCb)
    {
        var  routingId = "2242251234" + '@' + config.domain;
        
        // Call create room to get a room
        fetch('https://' + config.urls.eventManager +  '/v1/createroom/participants', {
            method: 'PUT',
            headers: {
                'Authorization': 'Bearer ' + this.props.navigation.state.params.token,
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
                                    'routing_id': this.props.navigation.state.params.routingId
                                    }],
                })
            }).then(response => {
                setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
                return response.json()
            })
            .then((responseData) => {
                console.log(' CreateRoom returned response ' + JSON.stringify(responseData));
                successCb(responseData.room_id);
            })
            .catch(function(err) {
                console.log(' CreateRoom returned an error  ' + err );
                failureCb(err);
            })
            .done();
    }
    ListenToNotifications()
    {
        var self = this;
        
        const {state, setParams } = this.props.navigation;

          // Callback for notification
          IrisRtcSdk.events.addListener('onNotification', function(data) {
            console.log("Notification received with [" + JSON.stringify(data) + "]");
            if ((state.mode == 'video') || (alertInProgress==true))
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
                'Received a video call from ' + cname + ', do you want to upgrade?',
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

                    setParams({ mode: 'video', videoConfig: _videoConfig, EnablePreview: true});
                  }},
                ],
                { cancelable: false }
              );
            }
          });
    }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },
  Square: {
    width: 40,
    height: 40,
    backgroundColor: 'rgba(255, 0, 0, 0.5)',
    flexDirection:'row', 
    alignItems:'center', 
    justifyContent:'center',
    marginBottom: 5
  },
  thumbnail: {
    position: "relative",
    width: '20%',
    height: '100%',
    marginRight: '4%',
  },
});