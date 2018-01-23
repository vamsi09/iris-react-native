import React, { Component, PropTypes } from 'react';
import {
  AppRegistry,
  Text,
  View,
  requireNativeComponent,
  NativeModules
} from 'react-native';

var IrisVideoCallView = React.createClass({
  constructor(props) {
      super(props);
       this.state = {
         apis: IrisRtcVideoCallView
       }
  },
  propTypes: {
    /*
      native only
    */
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
    },
  render() {
    return (
            <IrisRtcVideoCallView 
             {...this.props} 
            />
          );
  }
});

var IrisRtcVideoCallView = requireNativeComponent('IrisRtcVideoCallView', IrisVideoCallView);
module.exports = IrisVideoCallView;
