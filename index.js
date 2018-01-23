import React, { Component } from 'react';
import PropTypes from 'prop-types';
import {
    AppRegistry,
    Text,
    View,
    requireNativeComponent,
    NativeEventEmitter,
    NativeModules
} from 'react-native';

const { IrisRtcSdk } = NativeModules;
if (IrisRtcSdk) {
    IrisRtcSdk.events = new NativeEventEmitter(IrisRtcSdk);
} else {
    console.log(' IrisRtcSdk not found !!!');
}

// Add support for dial function
if (IrisRtcSdk) {
    // dial function allows to make a call
    IrisRtcSdk.dial = function(number, config) {
        // Send a request to get the routing id
        fetch('https://' + config.idmUrl + '/v1/routingid/appdomain/' + config.domain + '/publicid/' + number, {
                method: 'GET',
                headers: {
                    'Authorization': 'Bearer ' + config.token,
                    'Content-Type': 'application/json',
                }
            }).then((response) => {
                console.log(' IDM returned response ' + JSON.stringify(response));
                var routingId;
                if (response.status == 204) {
                    routingId = number + '@' + config.domain;
                }

                console.log(' Calling createroom with ' + routingId);

                // Call create room to get a room
                fetch('https://' + config.evmUrl + '/v1/createroom/participants', {
                        method: 'PUT',
                        headers: {
                            'Authorization': 'Bearer ' + config.token,
                            'Content-Type': 'application/json',
                        },
                        body: JSON.stringify({
                            participants: [{
                                    'notification': true,
                                    'owner': true,
                                    'room_identifier': true,
                                    'history': true,
                                    'routing_id': routingId
                                },
                                {
                                    'notification': true,
                                    'owner': true,
                                    'room_identifier': true,
                                    'history': true,
                                    'routing_id': config.routingId
                                }
                            ],
                        })
                    }).then(response => {
                        setTimeout(() => null, 0); // This is a hack, read more at https://github.com/facebook/react-native/issues/6679
                        return response.json()
                    })
                    .then((responseData) => {
                        console.log(' CreateRoom returned response ' + JSON.stringify(responseData));
                        if (responseData.room_id) {
                            IrisRtcSdk.createAudioStream();
                            console.log(' createAudioSession called ');

                            IrisRtcSdk.createAudioSession(responseData.room_id,
                                routingId,
                                config.sourceTN,
                                number,
                                "");
                        } else {
                            throw new Error("room_id doesn't exist");
                        }

                    })
                    .catch(function(err) {
                        console.log(' CreateRoom returned an error  ' + err);
                        IrisRtcSdk.events.emit('onCallError', { "error": ' CreateRoom returned an error  ' + err });
                    })
                    .done();
            })
            .done();
    }
}
var IrisRtcVideoCallView = requireNativeComponent('IrisRtcVideoCallView', IrisVideoCallView);
class IrisVideoCallView extends Component {


    static propTypes = {
        EnablePreview: PropTypes.bool,
        RoomId: PropTypes.string,
        Config: PropTypes.object,
        onPreviewStarted: PropTypes.func,
        onPreviewError: PropTypes.func,
        onSessionCreated: PropTypes.func,
        onSessionConnected: PropTypes.func,
        onParticipantJoined: PropTypes.func,
        onParticipantLeft: PropTypes.func,
        onSessionError: PropTypes.func,
        onSessionEnded: PropTypes.func,
        onChatMessage: PropTypes.func
    };
    constructor() {
        super();
        this._onPreviewStarted = this._onPreviewStarted.bind(this);
        this._onPreviewError = this._onPreviewError.bind(this);
        this._onSessionCreated = this._onSessionCreated.bind(this);
        this._onSessionConnected = this._onSessionConnected.bind(this);
        this._onParticipantJoined = this._onParticipantJoined.bind(this);
        this._onParticipantLeft = this._onParticipantLeft.bind(this);
        this._onSessionError = this._onSessionError.bind(this);
        this._onSessionEnded = this._onSessionEnded.bind(this);
        this._onChatMessage = this._onChatMessage.bind(this);
    }
    _onPreviewStarted(event) {
        if (!this.props.onPreviewStarted) {
            return;
        }
        this.props.onPreviewStarted(event.nativeEvent);
    }
    _onPreviewError(event) {
        if (!this.props.onPreviewError) {
            return;
        }
        this.props.onPreviewError(event.nativeEvent);
    }
    _onSessionCreated(event) {
        if (!this.props.onSessionCreated) {
            return;
        }
        this.props.onSessionCreated(event.nativeEvent);
    }
    _onSessionConnected(event) {
        if (!this.props.onSessionConnected) {
            return;
        }
        this.props.onSessionConnected(event.nativeEvent);
    }
    _onParticipantJoined(event) {
        if (!this.props.onParticipantJoined) {
            return;
        }
        this.props.onParticipantJoined(event.nativeEvent);
    }
    _onParticipantLeft(event) {
        if (!this.props.onParticipantLeft) {
            return;
        }
        this.props.onParticipantLeft(event.nativeEvent);
    }
    _onSessionError(event) {
        if (!this.props.onSessionError) {
            return;
        }
        this.props.onSessionError(event.nativeEvent);
    }
    _onSessionEnded(event) {
        if (!this.props.onSessionEnded) {
            return;
        }
        this.props.onSessionEnded(event.nativeEvent);
    }
    _onChatMessage(event) {
        if (!this.props.onChatMessage) {
            return;
        }
        this.props.onChatMessage(event.nativeEvent);
    }
    render() {
        return <IrisRtcVideoCallView {...this.props }
        onPreviewStarted = { this._onPreviewStarted }
        onPreviewError = { this._onPreviewError }
        onSessionCreated = { this._onSessionCreated }
        onSessionConnected = { this._onSessionConnected }
        onParticipantJoined = { this._onParticipantJoined }
        onParticipantLeft = { this._onParticipantLeft }
        onSessionError = { this._onSessionError }
        onSessionEnded = { this._onSessionEnded }
        onChatMessage = { this._onChatMessage }
        />
    }

    componentDidMount() {

    }
    endCall() {
        NativeModules.IrisRtcVideoCallView.endSession();
    }
    muteAudio() {
        NativeModules.IrisRtcVideoCallView.muteAudio();
    }
    unmuteAudio() {
        NativeModules.IrisRtcVideoCallView.unmuteAudio();
    }
    startVideoPreview() {
        NativeModules.IrisRtcVideoCallView.startVideoPreview();
    }
    stopVideoPreview() {
        NativeModules.IrisRtcVideoCallView.stopVideoPreview();
    }
    sendChatMessage(id, message) {
        NativeModules.IrisRtcVideoCallView.sendChatMessage(id, message);
    }

}
/*
 ** Video View
 */
var IrisVideoView = requireNativeComponent('IrisVideoView', IrisRtcVideoView);
class IrisRtcVideoView extends Component {
    static propTypes = {
        StreamId: PropTypes.string,
        onStreamError: PropTypes.func,
    };
    constructor() {
        super();
        this._onStreamError = this._onStreamError.bind(this);
    }
    _onStreamError(event) {
        if (!this.props.onStreamError) {
            return;
        }
        this.props.onStreamError(event.nativeEvent);
    }
    render() {
        return <IrisVideoView {...this.props }
        onStreamError = { this._onStreamError }
        />
    }
}

/*
 ** Create a room container
 */
class IrisRoomContainer extends Component {
    static propTypes = {
        EnablePreview: PropTypes.bool,
        UseBackCamera: PropTypes.bool,
        UseHD: PropTypes.bool,
        Type: PropTypes.string,
        RoomId: PropTypes.string,
        audioConfig: PropTypes.object,
        videoConfig: PropTypes.object,
        sessionId: PropTypes.string,
        evmUrl: PropTypes.string,
        routingId: PropTypes.string,
        token: PropTypes.string,
        eventHistory: PropTypes.array,
        muteRemoteParticipant: PropTypes.bool,
        participantId: PropTypes.string,


        onSessionCreated: PropTypes.func,
        onSessionConnected: PropTypes.func,
        onSessionDisconnected: PropTypes.func,
        onSessionSIPStatus: PropTypes.func,
        onSessionError: PropTypes.func,
        onChatMessage: PropTypes.func,
        onChatMessageAck: PropTypes.func,
        onChatMessageError: PropTypes.func,
        onChatMessageState: PropTypes.func,
        onSessionJoined: PropTypes.func,
        onSessionParticipantJoined: PropTypes.func,
        onSessionParticipantLeft: PropTypes.func,
        onSessionParticipantConnected: PropTypes.func,
        onSessionDominantSpeakerChanged: PropTypes.func,
        onSessionTypeChanged: PropTypes.func,
        onStreamError: PropTypes.func,
        onLocalStream: PropTypes.func,
        onRemoteAddStream: PropTypes.func,
        onRemoteRemoveStream: PropTypes.func,
        onSessionParticipantAudioMuted: PropTypes.func,
        onSessionParticipantVideoMuted: PropTypes.func,
    };

    // Constructor
    constructor(props) {
        super(props);
        this._streamCreated = false;
        this._UpgradeInProgress = false;
    };

    componentDidMount() {
        console.log(" IrisRoomContainer::componentDidMount with roomId =  "+this.props.RoomId);
        //this.syncMessages();
        
        // Observe events
        this._onSessionCreatedListener = IrisRtcSdk.events.addListener('onSessionCreated', function(event) {
            if (typeof this.props.onSessionCreated !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: Session created with " + JSON.stringify(event));
                this.props.onSessionCreated(event);
            }
        }.bind(this));

        this._onSessionConnectedListener = IrisRtcSdk.events.addListener('onSessionConnected', function(event) {
            if (typeof this.props.onSessionConnected !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: Session connected with " + JSON.stringify(event));
                this.props.onSessionConnected(event);
            }
        }.bind(this));

         this._onSessionDisconnectedListener = IrisRtcSdk.events.addListener('onSessionDisconnected', function(event) {
            if (typeof this.props.onSessionDisconnected !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: Session disconnected with " + JSON.stringify(event));
                this.props.onSessionDisconnected(event);
            }
        }.bind(this));

        this._onSessionSIPStatusListener = IrisRtcSdk.events.addListener('onSessionSIPStatus', function(event) {
            if (typeof this.props.onSessionSIPStatus !== 'undefined') {
                console.log("IrisRoomContainer:: SIP status received with " + JSON.stringify(event));
                this.props.onSessionSIPStatus(event);
            }
        }.bind(this));

        this._onSessionTypeChangedListener = IrisRtcSdk.events.addListener('onSessionTypeChanged', function(event) {
            if (typeof this.props.onSessionTypeChanged !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onSessionTypeChanged with " + JSON.stringify(event));
                this.props.onSessionTypeChanged(event);
            }
        }.bind(this));

        this._onSessionErrorListener = IrisRtcSdk.events.addListener('onSessionError', function(event) {
            if (typeof this.props.onSessionError !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: Session error received with " + JSON.stringify(event));
                this.props.onSessionError(event);
            }
        }.bind(this));

        this._onChatMessageListener = IrisRtcSdk.events.addListener('onChatMessage', function(event) {
            if (typeof this.props.onChatMessage !== 'undefined' && this.props.RoomId == event.roomId) {
                console.log("IrisRoomContainer:: Chat message received with " + JSON.stringify(event));
                this.props.onChatMessage(event);
            }
        }.bind(this));

        this._onChatMessageAckListener = IrisRtcSdk.events.addListener('onChatMessageAck', function(event) {
            if (typeof this.props.onChatMessageAck !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: Chat Message ack received with " + JSON.stringify(event));
                this.props.onChatMessageAck(event);
            }
        }.bind(this));

        this._onChatMessageErrorListener = IrisRtcSdk.events.addListener('onChatMessageError', function(event) {
            if (typeof this.props.onChatMessageError !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: Chat Message error received with " + JSON.stringify(event));
                this.props.onChatMessageError(event);
            }
        }.bind(this));

        this._onChatMessageStateListener = IrisRtcSdk.events.addListener('onChatMessageState', function(event) {
            if (typeof this.props.onChatMessageState !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: Chat Message state received with " + JSON.stringify(event));
                this.props.onChatMessageState(event);
            }
        }.bind(this));
        
        this._onSessionJoinedListener = IrisRtcSdk.events.addListener('onSessionJoined', function(event) {
            if (typeof this.props.onSessionJoined !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onSessionJoined with " + JSON.stringify(event));
                this.props.onSessionJoined(event);
            }
            if (this.props.RoomId == event.SessionId)
            {
                // Check if upgrade is in process
                if (this._UpgradeInProgress == true)
                {
                    this._UpgradeInProgress = false;
                    if (this.props.Type == 'video' && this.props.RoomId != "") {
                        // upgrade to video session
                        var videoSessionConfig = { notificationData: this.props.videoConfig.NotificationData,videoCodecType: this.props.videoConfig.VideoCodecType, 
                            audioCodecType: this.props.videoConfig.AudioCodecType };
                        IrisRtcSdk.upgradeToVideo(this.props.RoomId, videoSessionConfig);
                    }
                }
            }
        }.bind(this));
        
        this._onSessionParticipantJoinedListener = IrisRtcSdk.events.addListener('onSessionParticipantJoined', function(event) {
            if (typeof this.props.onSessionParticipantJoined !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onSessionParticipantJoined with " + JSON.stringify(event));
                this.props.onSessionParticipantJoined(event);
            }
        }.bind(this));
        
        this._onSessionParticipantLeftListener = IrisRtcSdk.events.addListener('onSessionParticipantLeft', function(event) {
            if (typeof this.props.onSessionParticipantLeft !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onSessionParticipantLeft with " + JSON.stringify(event));
                this.props.onSessionParticipantLeft(event);
            }
        }.bind(this));
        
        this._onSessionParticipantConnectedListener = IrisRtcSdk.events.addListener('onSessionParticipantConnected', function(event) {
            if (typeof this.props.onSessionParticipantConnected !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onSessionParticipantConnected with " + JSON.stringify(event));
                this.props.onSessionParticipantConnected(event);
            }
        }.bind(this));
        
        this._onSessionDominantSpeakerChangedListener = IrisRtcSdk.events.addListener('onSessionDominantSpeakerChanged', function(event) {
            if (typeof this.props.onSessionDominantSpeakerChanged !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onSessionDominantSpeakerChanged with " + JSON.stringify(event));
                this.props.onSessionDominantSpeakerChanged(event);
            }
        }.bind(this));
        
        this._onStreamErrorListener = IrisRtcSdk.events.addListener('onStreamError', function(event) {
            if (typeof this.props.onStreamError !== 'undefined' ) {
                console.log("IrisRoomContainer:: onStreamError with " + JSON.stringify(event));
                this.props.onStreamError(event);
            }
        }.bind(this));
        
        this._onLocalStreamListener = IrisRtcSdk.events.addListener('onLocalStream', function(event) {
            if (typeof this.props.onLocalStream !== 'undefined') {
                console.log("IrisRoomContainer:: onLocalStream with " + JSON.stringify(event));
                this.props.onLocalStream(event);
            }
        }.bind(this));
        
        this._onRemoteAddStreamListener = IrisRtcSdk.events.addListener('onRemoteAddStream', function(event) {
            if (typeof this.props.onRemoteAddStream !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onRemoteAddStream with " + JSON.stringify(event));
                this.props.onRemoteAddStream(event);
            }
        }.bind(this));
        
        this._onRemoteRemoveStreamListener = IrisRtcSdk.events.addListener('onRemoteRemoveStream', function(event) {
            if (typeof this.props.onRemoteRemoveStream !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onRemoteRemoveStream with " + JSON.stringify(event));
                this.props.onRemoteRemoveStream(event);
            }
        }.bind(this));

        this._onSessionParticipantAudioMutedListener = IrisRtcSdk.events.addListener('onSessionParticipantAudioMuted', function(event) {
            if (typeof this.props.onSessionParticipantAudioMuted !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onSessionParticipantAudioMuted with " + JSON.stringify(event));
                this.props.onSessionParticipantAudioMuted(event);
            }
        }.bind(this));

        this._onSessionParticipantVideoMutedListener = IrisRtcSdk.events.addListener('onSessionParticipantVideoMuted', function(event) {
            if (typeof this.props.onSessionParticipantVideoMuted !== 'undefined' && this.props.RoomId == event.SessionId) {
                console.log("IrisRoomContainer:: onSessionParticipantVideoMuted with " + JSON.stringify(event));
                this.props.onSessionParticipantVideoMuted(event);
            }
        }.bind(this));

        if (!this.props.RoomId) {
            console.log("IrisRoomContainer::Room id is not valid!!");
            return;
        }
        // Start the preview based on props
        if (!this.props.EnablePreview) {
            IrisRtcSdk.stopPreview();
        } else {
            //if (!this._streamCreated)
            {
                var UseBackCamera = (typeof this.props.UseBackCamera !== 'undefined') ? this.props.UseBackCamera : false;
                var UseHD = (typeof this.props.UseHD !== 'undefined') ? this.props.UseHD : false;
                IrisRtcSdk.createVideoStream(UseBackCamera, UseHD);
                this._streamCreated = true;
            }
            IrisRtcSdk.startPreview();
        }

        // Create a session based on the type
        //this._TryAndCreateChatSession(this.props.Type, this.props.RoomId);
        if (this.props.Type == 'video') {
            console.log('Mounting with video prop is not supported yet !! ')
            return;
        }
        this._TryAndCreateSession(this.props.Type, this.props.RoomId, this.props.videoConfig);
        
        if (this.props.muteRemoteParticipant != '' && this.props.participantId != '') {
            IrisRtcSdk.muteParticipantVideo(this.props.RoomId,this.props.muteRemoteParticipant ,this.props.participantId)
        }
    }

    // Called when there is a change in props
    componentWillReceiveProps(props) {
        console.log(" IrisRoomContainer::componentWillReceiveProps ",props);

        if ((this.props.RoomId != props.RoomId) && (props.RoomId == '')) {
            console.log('IrisRoomContainer::Ending session');
            IrisRtcSdk.endSession(this.props.RoomId);
            IrisRtcSdk.closeStream();
            return;
        }

        if (this.props.muteRemoteParticipant != '' && this.props.participantId != '') {
            IrisRtcSdk.muteParticipantVideo(this.props.RoomId,this.props.muteRemoteParticipant ,this.props.participantId)
        }
        
        // Check whether preview has began or not
        if (this.props.EnablePreview !== props.EnablePreview) {
            console.log(" IrisRoomContainer:: EnablePreview  " + props.EnablePreview + ' ' + this.props.EnablePreview);

            if (typeof props.EnablePreview !== 'undefined') {
                if (!props.EnablePreview) {
                    IrisRtcSdk.stopPreview();
                } else {
                    //if (!this._streamCreated)
                    {
                        var UseBackCamera = (typeof props.UseBackCamera !== 'undefined') ? props.UseBackCamera : false;
                        var UseHD = (typeof props.UseHD !== 'undefined') ? props.UseHD : false;
                        IrisRtcSdk.createVideoStream(UseBackCamera, UseHD);
                        this._streamCreated = true;
                    }
                    IrisRtcSdk.startPreview();
                }
            }
        }

        if (this.props.token != props.token ) {
            IrisRtcSdk.setIrisToken(props.token)
        }
        
        if ((this.props.Type != props.Type) ||
            (this.props.RoomId != props.RoomId) ||
            (this.props.videoConfig != props.videoConfig)
        ) {
            if ((this.props.RoomId != props.RoomId)) {
                if(this.props.RoomId != ''){
                IrisRtcSdk.endSession(this.props.RoomId);
                }
                if (props.Type == 'chat' && props.RoomId != '') {
                    this._TryAndCreateSession(props.Type, props.RoomId, props.videoConfig);
                    return;
                }
            }

            if (this.props.Type != props.Type) {
                if (this.props.Type == 'chat' && props.Type == 'video') {
                    var videoSessionConfig = { notificationData: props.videoConfig.NotificationData,videoCodecType: props.videoConfig.VideoCodecType, 
                        audioCodecType: props.videoConfig.AudioCodecType };
                    IrisRtcSdk.upgradeToVideo(props.RoomId, videoSessionConfig);
                } else
                if (this.props.Type == 'video' && props.Type == 'chat') {
                    IrisRtcSdk.closeStream();
                    IrisRtcSdk.downgradeToChat(props.RoomId);
                } else
                if (this.props.Type == '' && props.Type == 'chat') {
                    this._TryAndCreateSession(props.Type, props.RoomId, props.videoConfig);
                } else
                if (this.props.Type == '' && props.Type == 'video') {
                    console.log('Mounting with video prop is not supported yet !! ')
                    return;
                }

            }
        }
    }

    // Start deinit here
    componentWillUnmount() {
            console.log(' IrisRoomContainer::componentWillUnmount for roomId = '+this.props.RoomId);
            this._isMounted = false;
            this._UpgradeInProgress = false;
            if (this.props.RoomId != "") {
                // Create a chat session
                //IrisRtcSdk.endChatSession(this.props.RoomId);
                IrisRtcSdk.endSession(this.props.RoomId);
                this.setState({ RoomId: '' });
            }

        console.log(' IrisRoomContainer::Removing all listeners for roomId = '+this.props.RoomId);
        this._onSessionCreatedListener.remove();
        this._onSessionConnectedListener.remove();
        this._onSessionDisconnectedListener.remove();
        this._onSessionSIPStatusListener.remove();
        this._onSessionTypeChangedListener.remove();
        this._onSessionErrorListener.remove();
        this._onChatMessageListener.remove();
        this._onChatMessageAckListener.remove();
        this._onChatMessageErrorListener.remove();
        this._onChatMessageStateListener.remove();
        this._onSessionJoinedListener.remove();
        this._onSessionParticipantJoinedListener.remove();
        this._onSessionParticipantLeftListener.remove();
        this._onSessionParticipantConnectedListener.remove();
        this._onSessionDominantSpeakerChangedListener.remove();
        this._onStreamErrorListener.remove();
        this._onLocalStreamListener.remove();
        this._onRemoteAddStreamListener.remove();
        this._onRemoteRemoveStreamListener.remove();
        this._onSessionParticipantAudioMutedListener.remove();
        this._onSessionParticipantVideoMutedListener.remove();

            //if (this._streamCreated)
            {
                IrisRtcSdk.closeStream();
                //  this._streamCreated = false;
            }
        }
        // To mute audio
    muteAudio() {
        IrisRtcSdk.mute();
    }


    // To un-mute audio
    unmuteAudio() {
            IrisRtcSdk.unmute();
        }
        // To start the view preview
    startVideoPreview() {
        IrisRtcSdk.startPreview();
    }

    // To stop the video preview
    stopVideoPreview() {
        IrisRtcSdk.stopPreview();
    }

    // To stop the video preview
    restart() {
        // Let's end the session if it has already started
        console.log('IrisRoomContainer:: Restart the session');
        if (this.props.RoomId == '') return;
        if (this.props.Type != 'chat' && this.props.Type != 'video' && this.props.Type != 'audio')
        {
          console.log('IrisRoomContainer:: Ignoring as the type is ' + this.props.Type);
          return;  
        } 

        console.log('IrisRoomContainer::Ending session');
        IrisRtcSdk.endSession(this.props.RoomId);

        setTimeout(() => {
            console.log('reconnecting in 2 seconds');
             // Create the chat session
            this._TryAndCreateSession('chat', this.props.RoomId, this.props.videoConfig);

            // if the props has 'video', then we wait for chat session to be created 
            if (this.props.Type != 'chat')
            {
                this._UpgradeInProgress = true;
            }
        }, 2000);
       

    }
    // To flip camera
    flipCamera() {
        IrisRtcSdk.flip();
    }


    // Called when creating a chat session e
    _TryAndCreateSession(Type, RoomId, Config) {
        if (Type == 'chat' && RoomId != "") {
            // Check the config to see whether we want to create
            // an incoming or outgoing session
            if (Config.SessionType && Config.SessionType == 'outgoing') {
                // For outgoing, check parameters 
                if (Config.NotificationData == 'undefined') {
                    this._throwSessionError("Missing mandatory parameters (NotificationData) for outgoing call");
                    return;
                }
             
                var videoSessionConfig = { notificationData: Config.NotificationData, videoCodecType: Config.VideoCodecType, 
                                            audioCodecType: Config.AudioCodecType };
                IrisRtcSdk.createSession(RoomId, videoSessionConfig);
                
                
                // Create a chat session
                
            } else if (Config.SessionType && Config.SessionType == 'incoming') {
                // For incoming, check parameters 
                if (!Config.RoomToken ||
                    !Config.RoomTokenExpiryTime ||
                    !Config.RtcServer) {
                    this._throwSessionError("Missing mandatory parameters (RoomToken, RoomTokenExpiryTime, RtcServer) for incoming call");
                    return;
                }

                // Join a video session
                
                var videoSessionConfig = { roomToken: Config.RoomToken,videoCodecType: Config.VideoCodecType, audioCodecType: Config.AudioCodecType, roomTokenExpiry: Config.RoomTokenExpiryTime, rtcServer: Config.RtcServer };
                IrisRtcSdk.joinSession(RoomId, videoSessionConfig);
                

            } else {
                this._throwSessionError("SessionType is incorrect on the audioConfig");
            }
        }
        if (Type == 'video' && RoomId != "") {
            // upgrade to video session
            var videoSessionConfig = { notificationData: props.videoConfig.NotificationData,videoCodecType: props.videoConfig.VideoCodecType, 
                audioCodecType: props.videoConfig.AudioCodecType };
            IrisRtcSdk.upgradeToVideo(RoomId, videoSessionConfig);
        }
    }

    // Called when there is update on type
    createAudioSession(RoomId, Config) {
        if (Config != "" && RoomId != "") {
            // Check the config to see whether we want to create
            // an incoming or outgoing session
            if (Config.SessionType && Config.SessionType == 'outgoing') {
                // For outgoing, check parameters 
                if (!Config.ParticipantId ||
                    !Config.SourceTN ||
                    !Config.DestinationTN) {
                    this._throwSessionError("Missing mandatory parameters (ParticipantId, SourceTN, DestinationTN, NotificationData) for outgoing call");
                    return;
                }

                // Create an audio session
                IrisRtcSdk.createAudioSession(RoomId,
                    Config.ParticipantId,
                    Config.SourceTN,
                    Config.DestinationTN,
                    Config.NotificationData);
            } else if (Config.SessionType && Config.SessionType == 'incoming') {
                // For incoming, check parameters 
                if (!Config.RoomToken ||
                    !Config.RoomTokenExpiryTime ||
                    !Config.RtcServer) {
                    this._throwSessionError("Missing mandatory parameters (RoomToken, RoomTokenExpiryTime, RtcServer) for incoming call");
                    return;
                }

                // Create an audio session
                IrisRtcSdk.joinAudioSession(RoomId,
                    Config.RoomToken,
                    Config.RoomTokenExpiryTime,
                    Config.RtcServer);
            } else {
                this._throwSessionError("SessionType is incorrect on the audioConfig");
            }
        }
    }


    _throwSessionError(errorMsg) {
            if (this.props.onSessionError != 'undefined') {
                var errorEvent = { error: errorMsg };
                this.props.onSessionError(errorEvent);
            }
        }
        // Send chat messages
    sendChatMessage(id, message) {
        if (this.props.RoomId != "") {
            IrisRtcSdk.sendChatMessage(this.props.RoomId, message, id);
        }
    }

     // Send chat messages
     sendChatState(state) {
        if (this.props.RoomId != "") {
            IrisRtcSdk.sendChatState(this.props.RoomId, state);
        }
    }

    // End video session
    endSession() {
            if ((this.props.Type == 'video') &&
                (this.props.videoConfig != "") &&
                (this.props.RoomId != "")) {
                // End the existing session
                IrisRtcSdk.closeStream();
                IrisRtcSdk.endSession();
            }
        }
        // End audio session
    endAudioSession(RoomId) {
            IrisRtcSdk.endAudioSession(RoomId);
        }
        // Sync chat messages
    syncMessages() {
        if (!this.props.evmUrl || !this.props.RoomId)
            return;

        var length;
        if (!this.props.historyLength) {
            length = 100;
        } else {
            length = this.props.historyLength;
        }

        console.log('Get events from event manager' + 'https://' + this.props.evmUrl + '/v1/view/routingid/' + encodeURIComponent(this.props.routingId) + '/room/' + this.props.RoomId + '/records/' + length);
        // Make the event manager call to get the list of current messages for the room
        fetch('https://' + this.props.evmUrl + '/v1/view/routingid/' + encodeURIComponent(this.props.routingId) + '/room/' + this.props.RoomId + '/records/' + length, {
                method: 'GET',
                headers: {
                    'Authorization': "Bearer " + this.props.token,
                }
            }).then(response => {
                console.log(' Get the list of current messages returned response code ' + response.status);
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
                console.log(' Get the list of current messages returned  response ' + JSON.stringify(responseData));
                this.props.onEventHistory(responseData);
            })
            .catch(function(err) {
                console.log(' Get the list of current messages returned an error  ' + err);
            })
            .done();
    }
    render() {
        return <View / >
    }
}
export { IrisVideoCallView, IrisRoomContainer, IrisRtcSdk, IrisVideoView };
export default IrisRtcSdk;
