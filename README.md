
# react-native-iris-sdk

## Getting started

`$ npm install react-native-iris-sdk --save`

### Mostly automatic installation

`$ react-native link react-native-iris-sdk`

### Embed IrisRtcSdk framework
1. Add framework (path: `./node_modules/react-native-iris-sdk/ios/IrisRtcSdk.framework`) as embedded binaries in Xcode target settings.
2. Make sure the framework is also listed in `<target>` ➜ `general` ➜ `Linked framework and libraries`
3. Go to your project target ➜ `Build Settings` ➜ `Framework search path` and add `$(SRCROOT)/../node_modules/react-native-iris-sdk/ios`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-iris-sdk` and add `RNIrisSdk.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNIrisSdk.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.RNIrisSdkPackage;` to the imports at the top of the file
  - Add `new RNIrisSdkPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-iris-sdk'
  	project(':react-native-iris-sdk').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-iris-sdk/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-iris-sdk')
  	```


## Usage - Examples

```javascript
import IrisRtcSdk from 'react-native-iris-sdk';
```
1. Make connection using `iristoken` and `routingid`
  	```javascript
	// Observe events
	IrisRtcSdk.events.addListener('onConnected', function() {
		console.log("Connection Successful with iris backend");
		// Let's make a call
	});
	IrisRtcSdk.events.addListener('onDisconnected', function() {
		console.log("Connection disconnected from iris backend");

	});
	IrisRtcSdk.events.addListener('onConnectionError', function(error) {
		console.log("Failed with error [" + JSON.stringify(error) + "]");
	});

	// Call connection method 
	IrisRtcSdk.connectUsingServer("https://evm.iris.comcast.net", irisToken, RoutingId);
  	```

2. Make an outgoing PSTN call using IRIS SDK
  	```javascript
	IrisRtcSdk.events.addListener('onSessionCreated', function(event) {
		console.log("onSessionCreated");
	});
	IrisRtcSdk.events.addListener('onSessionConnected', function(event) {
		console.log("onSessionConnected");
	});
	IrisRtcSdk.events.addListener('onSessionSIPStatus', function(event) {
		console.log("onSessionSIPStatus");
	});
	IrisRtcSdk.events.addListener('onSessionDisconnected', function(event) {
		console.log("onSessionDisconnected");
	});
	// Observe events
	IrisRtcSdk.events.addListener('onConnected', function(success) {
		console.log("Connection Successful with iris backend");

		// Let's make a call
		var config = {
				idmUrl: 'idm.iris.comcast.net',
				evmUrl: 'evm.iris.comcast.net',
				token: irisToken,
				domain: 'iristest.comcast.com',
				routingId: RoutingId,
				sourceTN: ''
				};
		IrisRtcSdk.dial("", config);
	});
  	```
3. Using `IrisRoomContainer` to initiate/accept video call or to do a chat session
		
		return (
		<View>
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
		...

Please see APIs for video call for additional information on video calling. The `example-chat-video-room` folder has a working code for this.

## APIs

<div>

### Connection APIs - Make a connection using `connectUsingServer` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.connectUsingServer(serverUrl, irisToken, routingId);
```
**Params**

* `serverUrl` **{String}**: The url to event manager
* `irisToken` **{String}**: A valid IRIS token
* `routingId` **{String}**: Routing id of the user who is trying to login

</div>
----
<div>

### Connection APIs - Disconnect using `disconnect` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.disconnect();
```
**Params**

* None

</div>
----
<div>

### Stream APIs - Create a audio only stream using `createAudioStream` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.createAudioStream();
```
**Params**

* None

</div>
----
<div>

### Stream APIs - Create a video stream using `createVideoStream` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.createVideoStream(useBackCamera, UseHD);
```
**Params**

* `useBackCamera` **{boolean}**: whether to use back camera or not
* `UseHD` **{boolean}**: whether to use HD resolution for the call or not


</div>
----
<div>

### Stream APIs - Start a preview using `startPreview` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.startPreview();
```
**Params**

* None


</div>
----
<div>

### Stream APIs - Stop a preview using `stopPreview` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.stopPreview();
```
**Params**

* None


</div>
----
<div>

### Stream APIs - Mute audio using `mute` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.mute();
```
**Params**

* None


</div>
----
<div>

### Stream APIs - Un-mute audio using `unmute` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.unmute();
```
**Params**

* None


</div>
----
<div>

### Stream APIs - Flip the camera using `flip` 

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.flip();
```
**Params**

* None


</div>
----
<div>

### Session APIs - Dial a number using `createAudioSession`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.createAudioSession(roomId, participantId, sourceTN, destinationTN, notifictionData);
```
**Params**

* `roomId` **{String}**: Room id created using `createroom`
* `participantId` **{String}**: Routing id
* `sourceTN` **{String}**: 10 digit telephone number
* `destinationTN` **{String}**: 10 digit telephone number
* `notifictionData` **{String}**: Notification payload

</div>
----
<div>

### Session APIs - Accept an incoming call using `joinAudioSession`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.joinAudioSession(roomId, roomToken, roomTokenExpiryTime, rtcServer);
```
**Params**

* `roomId` **{String}**: Room id to join
* `roomToken` **{String}**: Room Token 
* `roomTokenExpiryTime` **{Number}**: Token expiry time 
* `rtcServer` **{Number}**: Rtc Server

</div>
----
<div>

### Session APIs - Hold the call using `hold`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.hold(sessionId);
```
**Params**

* `sessionId` **{String}**: Session as returned in `onSessionCreated` (Same as roomid)

</div>
----
<div>

### Session APIs - Unhold the call using `unhold`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.unhold(sessionId);
```
**Params**

* `sessionId` **{String}**: Session as returned in `onSessionCreated` (Same as roomid)

</div>
----
<div>

### Session APIs - Merge the call using `mergeCall`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.mergeCall(sessionId, sessionIdToBeMerged);
```
**Params**

* `sessionId` **{String}**: Session as returned in `onSessionCreated` (Same as roomid)
* `sessionIdToBeMerged` **{String}**: Session id to be mereged with

</div>
----
<div>

### Session APIs - Send a DTMF over the call

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.sendDTMF(sessionId, "1");
```
**Params**

* `sessionId` **{String}**: Session as returned in `onSessionCreated` (Same as roomid)
* `tone` **{String}**: Characters (0-9, A, B, C, D, *, #)

</div>
----
<div>

### Session APIs - End the call using `endAudioSession`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.endAudioSession(sessionId);
```
**Params**

* `sessionId` **{String}**: Session as returned in `onSessionCreated` (Same as roomid)

</div>
----
<div>

### Session APIs - Create a video session using `createVideoSession`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.createVideoSession(roomId, videoSessionConfig);
```
**Params**

* `roomId` **{String}**: Session as returned by `createroom`
* `videoSessionConfig` **{JSON}**: Video Session config
	* `notificationData` **{String}**: Notification payload

</div>
----
<div>

### Session APIs - Join a video session using `joinVideoSession`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.joinVideoSession(roomId, videoSessionConfig);
```
**Params**

* `roomId` **{String}**: Session as returned by `createroom`
* `videoSessionConfig` **{JSON}**: Video Session config
	* `roomToken` **{String}**: Room Token 
	* `roomTokenExpiryTime` **{Number}**: Token expiry time 
	* `rtcServer` **{Number}**: Rtc Server

</div>
----
<div>

### Session APIs - End the video call using `endVideoSession`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.endVideoSession(sessionId);
```
**Params**

* `sessionId` **{String}**: Session as returned in `onSessionCreated` (Same as roomid)

</div>
----
<div>

### Session APIs - Create a chat session using `createChatSession`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.createChatSession(RoomId, name);
```
**Params**

* `roomId` **{String}**: RoomId as returned by createroom
* `name` **{String}**: Profile name

</div>
----
<div>

### Session APIs - End a chat session using `endChatSession`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.endChatSession(RoomId);
```
**Params**

* `roomId` **{String}**: RoomId as returned by createroom

</div>
----
<div>

### Session APIs - Send a chat message using `sendChatMessage`

**Example**

```js
import IrisRtcSdk from 'react-native-iris-sdk';
IrisRtcSdk.sendChatMessage(RoomId, message, id);
```
**Params**

* `roomId` **{String}**: RoomId as returned by createroom
* `message` **{String}**: Message to be sent
* `id` **{String}**: Message id

</div>

## Callbacks

| Callback | Parameters | Description |
|:-------------:|:-------------:|:-----:|
| `onConnected` | None |When connection to backend is sucessful |
| `onDisconnected`| None |When connection to backend is disconnected |
| `onConnectionError`| None |Called when there is a connection error |
| `onSessionCreated`| `sessionId` |Called when the call is connecting |
| `onSessionConnected`| `sessionId` |Called when the call is connected |
| `onSessionDisconnected`| `sessionId` |Called when the call is disconnected |
| `onSessionSIPStatus`| <div style align=left> <ul><li>`event.status`  for status <li>`0`: When the call is connecting</li><li> `1`: When the call is connecting</li><li> `2`: When the call is connected </li><li>`3`: When the call is disconnected </li></ul></div> |Called when there is a change in SIP status || `onSessionError`| `sessionId`,`error` |Called when session has an error |
| `onChatMessage` | <div style align=left> <ul><li>`event.messageId`  for message id</li><li>`event.roomId` for Room id</li><li> `event.rootNodeId` for Root node id</li><li>`event.childNodeId` for child node id</li><li>`event.timeReceived` for received time</li><li>`event.data` for the actual message</li><li>`event.participantId` for participant id</li></ul></div>| Called when a chat message arrives |
| `onChatMessageAck`| <div style align=left> <ul><li>`event.messageId`  for message id </li></ul></div> |Called to ack to sent message |
| `onChatMessageError`| <div style align=left> <ul><li>`event.messageId`  for message id </li><li>`event.info`  for error information </li></ul></div> |Called when there is a message error |
| `onSessionParticipantJoined`| <div style align=left> <ul><li>`event.SessionId`  for session/room id </li><li>`event.RoutingId`  for Routing Id of the participant </li></ul></div> |Called when someone joins the call |
| `onSessionParticipantLeft`| <div style align=left> <ul><li>`event.SessionId`  for session/room id </li><li>`event.RoutingId`  for Routing Id of the participant </li></ul></div> |Called when someone left the call |
| `onSessionParticipantConnected`| <div style align=left> <ul><li>`event.SessionId`  for session/room id </li></ul></div> |Called when the session is connected with a given participant |
| `onSessionDominantSpeakerChanged`| <div style align=left> <ul><li>`event.RoutingId`  for Routing Id of the participant </li></ul></div> |Called when dominant speaker changes |
| `onStreamError`| None |Called when there is a error getting the stream |
| `onLocalStream`| <div style align=left> <ul><li>`event.StreamId`  for stream id </li></ul></div> |Called when local stream is created, use `IrisVideoView` to render the same |
| `onRemoteAddStream`| <div style align=left> <ul><li>`event.StreamId`  for stream id </li><li>`event.RoutingId`  for Routing Id of the participant </li></ul></div> |Called when remote stream is created, use `IrisVideoView` to render the same |
| `onRemoteRemoveStream`| <div style align=left> <ul><li>`event.StreamId`  for stream id </li></ul></div> |Called when remote stream is deleted |

### Video Calling APIs - `IrisVideoCallView` react component

`Deprecated`

### Video Calling APIs - `IrisRoomContainer` react component

This is a react component which gives flexibility to create chat, video and audio session. It allows to upgrade from chat to video and vice versa. 

## Usage

```
import {IrisRoomContainer, IrisRtcSdk} from 'react-native-iris-sdk';
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
```

The view has following props:

## Props

| Name | Type | Description |
|:-------------:|:-------------:|:-----:|
| `Type` | String |<div style align=left> <ul><li>`chat`: Start a chat session</li><li>`video`: Ends the chat session and starts the video session</li><li>`audio`: Ends the chat session and starts the audio session</li></ul> </div>|
| `EnablePreview` | boolean |<div style align=left> <ul><li>`true`: Starts a local preview when component is mounted</li><li>`false`: Does not start a local preview when component is mounted</li></ul> </div>|
| `audioConfig`| JSON |<div style align=left><ul><li>`SessionType`: `outgoing` for outgoing audio calls Or `incoming` for incoming audio calls. </li><li>`notificationPayload`: Mandatory when session is `outgoing`. This includes the payload you need to use while making the calls. For anonymous calls, please use "".</li><li>`ParticipantId`: Routing id for 'outgoing' call.</li><li>`SourceTN`: Source Telephone number.</li><li>`DestinationTN`: Destination Telephone number.</li><li>`roomToken`: Mandatory when session is `incoming`. This is part of the incoming notification.</li><li>`roomTokenExpiryTime`: Mandatory when session is `incoming`. This is part of the incoming notification.</li><li>`rtcServer`: Mandatory when session is `incoming`. This is part of the incoming notification.</li></ul></div>  |
| `videoConfig`| JSON |<div style align=left><ul><li>`SessionType`: `outgoing` for outgoing video calls Or `incoming` for incoming video calls. </li><li>`VideoCodecType`: `vp8` for VP8 video codec Or `h264` for H264 codec. </li><li>`AudioCodecType`: can be `opus` `isac16k` `isac30k` </li><li>`notificationPayload`: Mandatory when session is `outgoing`. This includes the payload you need to use while making the calls. For anonymous calls, please use "".</li><li>`roomToken`: Mandatory when session is `incoming`. This is part of the incoming notification.</li><li>`roomTokenExpiryTime`: Mandatory when session is `incoming`. This is part of the incoming notification.</li><li>`rtcServer`: Mandatory when session is `incoming`. This is part of the incoming notification.</li></ul></div>
| `RoomId`| String |<div style align=left>A room Id is retrieved through event manager `createroom` API </div>|
| `evmUrl`| String |<div style align=left>Event manager url such as `evm.iris.comcast.net`.</div>|
| `routingId`| String |<div style align=left>Routing id </div>|
| `token`| String |<div style align=left>A valid Iris token </div>|

## Callback Props

| Callback | Parameters | Description |
|:-------------:|:-------------:|:-----:|
| `onSessionCreated`| `sessionId` |Called when the call is connecting |
| `onSessionConnected`| `sessionId` |Called when the call is connected |
| `onSessionDisconnected`| `sessionId` |Called when the call is disconnected |
| `onSessionSIPStatus`| <div style align=left> <ul><li>`event.status`  for status <li>`0`: When the call is connecting</li><li> `1`: When the call is connecting</li><li> `2`: When the call is connected </li><li>`3`: When the call is disconnected </li></ul></div> |Called when there is a change in SIP status || `onSessionError`| `sessionId`,`error` |Called when session has an error |
| `onChatMessage` | <div style align=left> <ul><li>`event.messageId`  for message id</li><li>`event.roomId` for Room id</li><li> `event.rootNodeId` for Root node id</li><li>`event.childNodeId` for child node id</li><li>`event.timeReceived` for received time</li><li>`event.data` for the actual message</li><li>`event.participantId` for participant id</li></ul></div>| Called when a chat message arrives |
| `onChatMessageAck`| <div style align=left> <ul><li>`event.messageId`  for message id </li></ul></div> |Called to ack to sent message |
| `onChatMessageError`| <div style align=left> <ul><li>`event.messageId`  for message id </li><li>`event.info`  for error information </li></ul></div> |Called when there is a message error |
| `onSessionParticipantJoined`| <div style align=left> <ul><li>`event.SessionId`  for session/room id </li><li>`event.RoutingId`  for Routing Id of the participant </li></ul></div> |Called when someone joins the call |
| `onSessionParticipantLeft`| <div style align=left> <ul><li>`event.SessionId`  for session/room id </li><li>`event.RoutingId`  for Routing Id of the participant </li></ul></div> |Called when someone left the call |
| `onSessionParticipantConnected`| <div style align=left> <ul><li>`event.SessionId`  for session/room id </li></ul></div> |Called when the session is connected with a given participant |
| `onSessionDominantSpeakerChanged`| <div style align=left> <ul><li>`event.RoutingId`  for Routing Id of the participant </li></ul></div> |Called when dominant speaker changes |
| `onStreamError`| None |Called when there is a error getting the stream |
| `onLocalStream`| <div style align=left> <ul><li>`event.StreamId`  for stream id </li></ul></div> |Called when local stream is created, use `IrisVideoView` to render the same |
| `onRemoteAddStream`| <div style align=left> <ul><li>`event.StreamId`  for stream id </li><li>`event.RoutingId`  for Routing Id of the participant </li></ul></div> |Called when remote stream is created, use `IrisVideoView` to render the same |
| `onRemoteRemoveStream`| <div style align=left> <ul><li>`event.StreamId`  for stream id </li></ul></div> |Called when remote stream is deleted |
| `onEventHistory` | <div style align=left> Called  with array of events as returned by event manager </div>|Called when event history is retrieved |

## Methods

You can use a ref to access the methods. See an example below:

		<IrisRoomContainer 
			ref={(IrisRoomContainer) => { this._IrisRoomContainer = IrisRoomContainer; }}
			...
		/>
		...
		// When user ends the call, call the end call method
		this._IrisRoomContainer.endVideoSession();


| Name | Type | Description |
|:-------------:|:-------------:|:-----:|
| `muteAudio` | function |<div style align=left> <ul><li>To mute audio. Has no parameter</li></ul></div>|
| `unmuteAudio` | function |<div style align=left> <ul><li>To unmute audio. Has no parameter</li></ul></div>|
| `startVideoPreview` | function |<div style align=left> <ul><li>To start the preview. Has no parameter.</li></ul></div>|
| `stopVideoPreview` | function |<div style align=left> <ul><li>To stop the preview. Has no parameter.</li></ul> </div>|
| `flipCamera` | function |<div style align=left> <ul><li>To flip the camera. Has no parameter.</li></ul> </div>|
| `sendChatMessage` | function |<div style align=left> <ul><li>To send a chat message to all participants. </li><li>Has two parameters. `id`: Message id to track. `message`: The actual chat message</li></ul> </div> </div>|
| `endChatSession` | function |<div style align=left> <ul><li>To end the chat session. Need `roomId` as a parameter </li></ul> </div> </div>|
| `endAudioSession` | function |<div style align=left> <ul><li>To end the audio session. Need `roomId` as a parameter </li></ul> </div> </div>|
| `endVideoSession` | function |<div style align=left> <ul><li>To end the video session. Need `roomId` as a parameter </li></ul> </div> </div>|
| `syncMessages` | function |<div style align=left> <ul><li>Get the recent events from event manager. This will trigger `onEventHistory` </li></ul> </div> </div>|
