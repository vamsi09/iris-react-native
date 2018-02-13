// Copyright (c) 2017 Comcast

// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

package com.reactirislibrary;

import com.comcast.irisrtcsdk.IrisRtcSdk.Smack.Listener.IrisChatMessage;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import android.content.Intent;
import android.support.annotation.Nullable;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;

import org.json.JSONObject;
import org.webrtc.EglBase;

import com.comcast.irisrtcsdk.*;
import com.comcast.irisrtcsdk.IrisRtcSdk.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;


public class RNIrisSdkModule extends ReactContextBaseJavaModule implements IrisRtcConnection.IrisRtcConnectionObserver, IrisRtcStream.IrisRtcStreamObserver, IrisRtcAudioSession.IrisRtcAudioSessionObserver, IrisRtcSession.IrisRtcSessionObserver, IrisRtcVideoSession.IrisRtcVideoSessionObserver, IrisRtcChatSession.IrisRtcChatSessionObserver {

    private final ReactApplicationContext reactContext;
    private static final String TAG_RNIRISSDK = "React--IrisRtcSdk";

    // Constant string for sending events
    private static final String IrisEventOnConnected = "onConnected";
    private static final String IrisEventOnDisconnected = "onDisconnected";
    private static final String IrisEventOnConnectionError = "onConnectionError";
    private static final String IrisEventOnNotification = "onNotification";

    // Audio Session events
    private static final String IrisEventOnSessionCreated = "onSessionCreated";
    private static final String IrisEventOnSessionJoined = "onSessionJoined";

    private static final String IrisEventOnSessionConnected = "onSessionConnected";
    private static final String IrisEventOnSessionDisconnected = "onSessionDisconnected";
    private static final String IrisEventOnSessionSIPStatus = "onSessionSIPStatus";
    private static final String IrisEventOnSessionError = "onSessionError";

    private static final String IrisEventOnChatMessage = "onChatMessage";
    private static final String IrisEventOnChatMessageAck = "onChatMessageAck";
    private static final String IrisEventOnChatMessageState = "onChatMessageState";
    private static final String IrisEventOnChatMessageError = "onChatMessageError";

    // Video Session events
    private static final String IrisEventOnSessionParticipantJoined = "onSessionParticipantJoined";
    private static final String IrisEventOnSessionParticipantLeft = "onSessionParticipantLeft";
    private static final String IrisEventOnSessionTypeChanged = "onSessionTypeChanged";
    private static final String IrisEventOnSessionParticipantConnected = "onSessionParticipantConnected";
    private static final String IrisEventOnSessionDominantSpeakerChanged = "onSessionDominantSpeakerChanged";
    private static final String IrisEventOnSessionRemoteParticipantActivated = "onSessionRemoteParticipantActivated";
    private static final String IrisEventOnSessionParticipantVideoMuted = "onSessionParticipantVideoMuted";
    private static final String IrisEventOnSessionParticipantAudioMuted = "onSessionParticipantAudioMuted";
    private static final String IrisEventOnSessionParticipantProfile = "onSessionParticipantProfile";
    private static final String IrisEventOnSessionParticipantNotResponding = "onSessionParticipantNotResponding";

    // Video Stream events
    private static final String IrisEventOnStreamError = "onStreamError";
    private static final String IrisEventOnLocalStream = "onLocalStream";
    private static final String IrisEventOnRemoteAddStream = "onRemoteAddStream";
    private static final String IrisEventOnRemoteRemoveStream = "onRemoteRemoveStream";

    // Local variables
    private IrisRtcStream audioStream;
    private IrisRtcStream videoStream;
    private static EglBase rootEglBase;
    private Map<String, IrisRtcAudioSession> audioSessionArray = new HashMap<String, IrisRtcAudioSession>();
    private Map<String, IrisRtcChatSession> chatSessionArray = new HashMap<String, IrisRtcChatSession>();
    private Map<String, IrisRtcSession> sessionArray = new HashMap<String, IrisRtcSession>();
    private Map<String, IrisRtcVideoSession> videoSessionArray = new HashMap<String, IrisRtcVideoSession>();
    private String localStreamId;

    public RNIrisSdkModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        rootEglBase = EglBase.create();
    }

    @Override
    public String getName() {
        return "IrisRtcSdk";
    }

    /**
     * Private method to send an event
     *
     * @param eventName name of the event
     * @param params    event parameters
     */
    private void sendEvent(String eventName,
                           @Nullable WritableMap params) {
        this.reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    /**
     * To get the EGL base
     *
     * @return egl base
     */
    public static EglBase getEglBase() {
        return rootEglBase;
    }

    /**
     * Create the websocket connection with XMPP server
     *
     * @param mucId      The event manager URL
     * @param timeStamp  Timestamp when token was created
     * @param xmppToken  Xmpp token as retrieved from register call.
     * @param xmppServer Xmpp server name
     */
    @ReactMethod
    public void connectUsingServer(String serverUrl, String irisToken, String routingId) {

        Log.i(TAG_RNIRISSDK, " Calling connectUsingServer with " + serverUrl + " routingId " + routingId);
        if (IrisRtcConnection.getInstance().getState() !=
                IrisRtcConnection.IrisRtcConnectionState.kConnectionStateDisconnected) {
            IrisRtcConnection.getInstance().disconnect();
        }

        try {
            IrisRtcConnection.getInstance().connect(serverUrl, irisToken, routingId, this);
        } catch (IrisRtcSDKException e) {
            e.printStackTrace();
        }

    }

    /**
     * Observer invoked when the rtc connection is done
     */
    @Override
    public void onConnected() {
        Log.i(TAG_RNIRISSDK, " IrisRtcConnection -- onConnected ");
        this.sendEvent(IrisEventOnConnected, null);
    }

    /**
     * Observer invoked when the rtc connection is disconnected
     */
    @Override
    public void onDisconnect() {
        Log.i(TAG_RNIRISSDK, " IrisRtcConnection -- onDisconnect ");
        this.sendEvent(IrisEventOnDisconnected, null);
    }

    /**
     * Observer invoked when there is an error during the connection
     */
    @Override
    public void onError(WebRTCError.ErrorCode error, JSONObject additionalInfo) {
        Log.i(TAG_RNIRISSDK, " IrisRtcConnection -- onError with error " + error.getValue() + " - " + error.getErorDescription());

        WritableMap event = Arguments.createMap();
        event.putString("Details", additionalInfo.toString());
        event.putInt("ErrorCode", error.getValue());
        event.putString("Error", error.getErorDescription());

        this.sendEvent(IrisEventOnConnectionError, event);
    }

    /**
     * Observer invoked when there is a notification
     */
    @Override
    public void onNotification(IrisRtcConnection.IrisNotificationPayload irisNotificationPayload) {
        WritableMap event = Arguments.createMap();
        
        //this.sendEvent(IrisEventOnNotification, null);
    }

    /**
     * This method is called to create a audio stream
     */
    @ReactMethod
    public void createAudioStream() {

        Log.i(TAG_RNIRISSDK, " Calling createAudioStream ");

        // Check if the stream is already created
        if (audioStream == null) {
            audioStream = new IrisRtcStream(IrisRtcStream.IrisRtcSdkStreamType.kStreamTypeAudio,
                    IrisRtcStream.IrisRtcSdkStreamQuality.kStreamQuality_FullHD,
                    IrisRtcStream.IrisRtcCameraType.kCameraTypeFront,
                    this, this.reactContext.getApplicationContext());
        } else {
            Log.w(TAG_RNIRISSDK, " Audio stream is already created !!! ");
        }
    }

    /**
     * This method is called to create a video stream
     */
    @ReactMethod
    public void createVideoStream(boolean useBackCamera, boolean useHD) {

        Log.i(TAG_RNIRISSDK, " createVideoStream called with " + "useBackCamera:" + useBackCamera + "useHD:" + useHD);

        // Check if the stream is already created
        if (videoStream == null) {
            IrisRtcStream.IrisRtcSdkStreamQuality quality = useHD ? IrisRtcStream.IrisRtcSdkStreamQuality.kStreamQuality_FullHD : IrisRtcStream.IrisRtcSdkStreamQuality.kStreamQuality_VGA;
            IrisRtcStream.IrisRtcCameraType type = useBackCamera ? IrisRtcStream.IrisRtcCameraType.kCameraTypeBack : IrisRtcStream.IrisRtcCameraType.kCameraTypeFront;

            videoStream = new IrisRtcStream(IrisRtcStream.IrisRtcSdkStreamType.kStreamTypeVideo,
                    quality,
                    type,
                    this, this.reactContext.getApplicationContext());
            videoStream.startPreview(rootEglBase.getEglBaseContext()); // To get the EGL base context from renderers
        } else {
            Log.w(TAG_RNIRISSDK, " Video stream is already created !!! ");
        }
    }

    /**
     * This method is called to start a local preview
     */
    @ReactMethod
    public void startPreview() {

        Log.i(TAG_RNIRISSDK, " startPreview called ");

        // Check if the stream is already created
        if (videoStream != null) {
            videoStream.startPreview(rootEglBase.getEglBaseContext()); // To get the EGL base context from renderers
        }
    }

    /**
     * This method is called to stop a local preview
     */
    @ReactMethod
    public void stopPreview() {

        Log.i(TAG_RNIRISSDK, " stopPreview called ");

        // Check if the stream is already created
        if (videoStream != null) {
            videoStream.stopPreview();
        }
    }

    /**
     * This method is called to close the stream
     */
    @ReactMethod
    public void closeStream() {

        Log.i(TAG_RNIRISSDK, " closeStream called ");

        // Check if the stream is already created
        if (videoStream != null) {
            videoStream.stopPreview();
            videoStream.close();
        }

        // Code to propagate that a local stream is closed
        if (localStreamId != null) {
            // Send a notification to delete the renderer/videoview
            Intent intent = new Intent("onTrackDeleted");
            intent.putExtra("TrackId", localStreamId);
            LocalBroadcastManager.getInstance(reactContext).sendBroadcast(intent);
        }
    }

    /**
     * This method is called to mute audio
     */
    @ReactMethod
    public void mute() {

        Log.i(TAG_RNIRISSDK, " mute called ");

        // Check if the stream is already created
        if (videoStream != null) {
            videoStream.mute();
        }
    }

    /**
     * This method is called to unmute audio
     */
    @ReactMethod
    public void unmute() {

        Log.i(TAG_RNIRISSDK, " unmute called ");

        // Check if the stream is already created
        if (videoStream != null) {
            videoStream.unmute();
        }
    }

    /**
     * This method is called to flip camera
     */
    @ReactMethod
    public void flip() {

        Log.i(TAG_RNIRISSDK, " flip called ");

        // Check if the stream is already created
        if (videoStream != null) {
            videoStream.flip();
        }
    }

    /**
     * Callback: This is called when the local preview is available.
     *
     * @param mediaTrack media track that is associated with camera instance.
     */
    @Override
    public void onLocalStream(IrisRtcMediaTrack mediaTrack) {
        Log.i(TAG_RNIRISSDK, " onLocalStream ");

        // Create a unique id for track
        String uuid = UUID.randomUUID().toString();

        // Add track
        RNIrisSdkStreamManager.getInstance().addTrack(mediaTrack, uuid);

        WritableMap event = Arguments.createMap();
        event.putString("StreamId", uuid);

        this.sendEvent(IrisEventOnLocalStream, event);

        localStreamId = uuid;


    }

    /**
     * Callback: This is called when there in an error during camera capture processs.
     *
     * @param errorCode      The basic error code details
     * @param additionalData Additional error details including description
     */
    @Override
    public void onStreamError(WebRTCError.ErrorCode errorCode, JSONObject additionalData) {
        Log.i(TAG_RNIRISSDK, " onStreamError ");
        WritableMap event = Arguments.createMap();
        event.putString("description", errorCode.getErorDescription());
        event.putString("value", String.valueOf(errorCode.getValue()));

        this.sendEvent(IrisEventOnStreamError, event);
    }

    /**
     * To create audio session
     *
     * @param roomId           Room id
     * @param participantId    Participant id
     * @param sourceTN         Source TN
     * @param targetTN         Target TN
     * @param notificationData Notification data
     */
    @ReactMethod
    public void createAudioSession(String roomId,
                                   String participantId,
                                   String sourceTN,
                                   String targetTN,
                                   String notificationData) {
        Log.i(TAG_RNIRISSDK, " createAudioSession called with " + roomId + ":" + participantId + ":"
                + sourceTN + ":" + targetTN + ":" + notificationData);

        // Call createaudiostream() just in case audio stream is not already created
        createAudioStream();

        // Create the audio session
        IrisRtcAudioSession mSession = new IrisRtcAudioSession(reactContext);

        // Set the session properties
        mSession.isVideoBridge = true;

        // Create the actual session
        try {
            mSession.create(roomId, participantId, sourceTN, targetTN, notificationData, audioStream, this);
        } catch (IrisRtcSDKException e) {
            Log.e(TAG_RNIRISSDK, e.getStackTrace().toString());
        }
    }

    /**
     * This method is called to join pstn/audio session which involves joining the room using the room id recieved in notification.
     *
     * @param roomId          room name that needs to be joined which is recieved in notification.
     * @param roomToken       Room token as available in notification
     * @param roomTokenExpiry Token expiry time
     * @param rtcServer       Rtc server as available in the notification
     */
    @ReactMethod
    public void joinAudioSession(String roomId,
                                 String roomToken,
                                 int roomTokenExpiry,
                                 String rtcServer) {
        Log.i(TAG_RNIRISSDK, " joinAudioSession called with " + roomId + ":" + roomToken + ":"
                + roomTokenExpiry + ":" + rtcServer);

        // Call createaudiostream() just in case audio stream is not already created
        createAudioStream();

        // Create the audio session
        IrisRtcAudioSession mSession = new IrisRtcAudioSession(reactContext);

        // Set the session properties
        mSession.isVideoBridge = true;

        // Join the actual session
        try {
            mSession.join(roomId, roomToken, String.valueOf(roomTokenExpiry), audioStream, rtcServer, this);
        } catch (IrisRtcSDKException e) {
            Log.e(TAG_RNIRISSDK, e.getStackTrace().toString());
        }
        audioSessionArray.put(roomId, mSession);
    }

    /**
     * To hold a session
     *
     * @param sessionId Session id
     */
    @ReactMethod
    public void hold(String sessionId) {
        Log.i(TAG_RNIRISSDK, " hold called with " + sessionId);

        // Check if we have this key
        if (audioSessionArray.containsKey(sessionId)) {
            IrisRtcAudioSession mSession = audioSessionArray.get(sessionId);
            mSession.hold();
        }
    }

    /**
     * To unhold a session
     *
     * @param sessionId Session id
     */
    @ReactMethod
    public void unhold(String sessionId) {
        Log.i(TAG_RNIRISSDK, " unhold called with " + sessionId);

        // Check if we have this key
        if (audioSessionArray.containsKey(sessionId)) {
            IrisRtcAudioSession mSession = audioSessionArray.get(sessionId);
            mSession.unhold();
        }
    }

    /**
     * To merge the call
     *
     * @param sessionId Session id
     */
    @ReactMethod
    public void mergeCall(String sessionId, String sessionToBeMerged) {
        Log.i(TAG_RNIRISSDK, " mergeCall called with " + sessionId + ":" + sessionToBeMerged);

        // Check if we have this key
        if (audioSessionArray.containsKey(sessionId) && audioSessionArray.containsKey(sessionToBeMerged)) {
            IrisRtcAudioSession mSession = audioSessionArray.get(sessionId);
            mSession.mergeSession(audioSessionArray.get(sessionToBeMerged));
        }
    }

    /**
     * This method is used for sending dtmf tones.
     *
     * @param sessionId Session Identifier
     * @param tone      Tone to be sent
     */
    @ReactMethod
    public void sendDTMF(String sessionId, String tone) {
        Log.i(TAG_RNIRISSDK, " sendDTMF called with " + sessionId + ":" + tone);

        // Check if we have this key
        if (audioSessionArray.containsKey(sessionId)) {
            IrisRtcAudioSession mSession = audioSessionArray.get(sessionId);
            mSession.inserDTMFTone(tone);
        }
    }

    /**
     * This method is called to close the session
     *
     * @param sessionId Session Identifier
     */
    @ReactMethod
    public void endAudioSession(String sessionId) {
        Log.i(TAG_RNIRISSDK, " endAudioSession called with " + sessionId);

        // Check if we have this key
        if (audioSessionArray.containsKey(sessionId)) {
            IrisRtcAudioSession mSession = audioSessionArray.get(sessionId);
            mSession.close();
            audioSessionArray.remove(mSession);
        }
    }

    /**
     * To create a session
     * @param roomId Room Id
     * @param sessionConfig Session Config
     */
    @ReactMethod
    public void createSession(String roomId, ReadableMap sessionConfig)
    {
        Log.i(TAG_RNIRISSDK, " createSession called with " + roomId );

        // Check the room id
        if (sessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + roomId + " is already created");
            return;
        }

        // Get the notification data
        String notificationData=sessionConfig.getString("notificationData");
        IrisRtcSession mSession = new IrisRtcSession(reactContext);
        mSession.isVideoBridge = true;

        // Create the session
        try {
            mSession.create(roomId, notificationData,  this);
            sessionArray.put(roomId, mSession);
        } catch (IrisRtcSDKException e) {
            Log.e(TAG_RNIRISSDK, e.getStackTrace().toString());
        }
    }

    /**
     * To join a session
     * @param roomId
     * @param sessionConfig
     */
    @ReactMethod
    public void joinSession(String roomId, ReadableMap sessionConfig)
    {
        Log.i(TAG_RNIRISSDK, " joinSession called with " + roomId );

        // Check the room id
        if (sessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + roomId + " is already created");
            return;
        }

        // Check the parameters
        if (sessionConfig.getString("roomToken") == null
                || sessionConfig.getString("roomTokenExpiry") == null
                || sessionConfig.getString("rtcServer") == null)
        {
            WritableMap event = Arguments.createMap();
            event.putString("description", "React::IrisRtcSdk Missing mandatory parameters, check whether you have passed roomToken, roomTokenExpiry and rtcServer !!!");
            event.putInt("code ", -1); // To match with ios : TBD

            this.sendEvent(IrisEventOnSessionError, event);
            return;
        }

        // Get the notification data
        String notificationData=sessionConfig.getString("notificationData");
        IrisRtcSession mSession = new IrisRtcSession(reactContext);
        mSession.isVideoBridge = true;

        // Join the session
        try {
            mSession.join(roomId,
                            sessionConfig.getString("roomToken"),
                            sessionConfig.getString("roomTokenExpiry"),
                            videoStream,
                            sessionConfig.getString("rtcServer"),
                            this);
            sessionArray.put(roomId, mSession);
        } catch (IrisRtcSDKException e) {
            Log.e(TAG_RNIRISSDK, e.getStackTrace().toString());
        }

    }

    /**
     * This method is called to upgrade to video session from chat.
     * @param sessionId : Session Id
     * @param sessionConfig : Config
     */
    @ReactMethod
    public void upgradeToVideo(String sessionId, ReadableMap sessionConfig)
    {
        Log.i(TAG_RNIRISSDK, " upgradeToVideo called with " + sessionId  );

        // Check the room id
        if (!sessionArray.containsKey(sessionId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + sessionId + " is not created yet");
            return;
        }
        IrisRtcSession mSession = sessionArray.get(sessionId);
        mSession.upgradeToVideo(sessionConfig.getString("notificationData"), videoStream);
    }

    /**
     * This method is called to downgrade from video session to chat.
     * @param sessionId
     */
    @ReactMethod
    public void downgradeToChat(String sessionId)
    {
        Log.i(TAG_RNIRISSDK, " downgradeToChat called with " + sessionId  );

        // Check the room id
        if (!sessionArray.containsKey(sessionId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + sessionId + " is not created yet");
            return;
        }
        IrisRtcSession mSession = sessionArray.get(sessionId);
        mSession.downgradeToChat();

        // Send a notification to delete the renderer/videoview
        Intent intent = new Intent("onAllTracksDeleted");
        LocalBroadcastManager.getInstance(reactContext).sendBroadcast(intent);
    }

    /**
     * To end the session
     * @param sessionId Session Id
     */
    @ReactMethod
    public void endSession(String sessionId)
    {
        Log.i(TAG_RNIRISSDK, " endSession called with " + sessionId  );

        // Check the room id
        if (!sessionArray.containsKey(sessionId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + sessionId + " is not created yet");
            return;
        }

        IrisRtcSession mSession = sessionArray.get(sessionId);
        mSession.closeSession();
        sessionArray.remove(mSession);

        // TBD: Broadcast a notification to delete the renderers
        // Send a notification to delete the renderer/videoview
        Intent intent = new Intent("onAllTracksDeleted");
        LocalBroadcastManager.getInstance(reactContext).sendBroadcast(intent);
    }

    /**
     * To create a session
     * @param roomId Room Id
     * @param sessionConfig Session Config
     */
    @ReactMethod
    public void createVideoSession(String roomId, ReadableMap sessionConfig)
    {
        Log.i(TAG_RNIRISSDK, " createVideoSession called with " + roomId  );

        // Check the room id
        if (videoSessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + roomId + " is already created");
            return;
        }

        // Init the session
        IrisRtcVideoSession mSession = new IrisRtcVideoSession(reactContext);
        mSession.isVideoBridge = true;

        // Create the session
        try {
            mSession.create(roomId, sessionConfig.getString("notificationData"), videoStream, this);
            videoSessionArray.put(roomId, mSession);
        } catch (IrisRtcSDKException e) {
            Log.e(TAG_RNIRISSDK, e.getStackTrace().toString());
        }
    }

    /**
     * To join a session
     * @param roomId Room Id
     * @param sessionConfig Session Config
     */
    @ReactMethod
    public void joinVideoSession(String roomId, ReadableMap sessionConfig)
    {
        Log.i(TAG_RNIRISSDK, " joinVideoSession called with " + roomId  );

        // Check the room id
        if (videoSessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + roomId + " is already created");
            return;
        }

        // Check the parameters
        if (sessionConfig.getString("roomToken") == null
                || sessionConfig.getString("roomTokenExpiry") == null
                || sessionConfig.getString("rtcServer") == null)
        {
            WritableMap event = Arguments.createMap();
            event.putString("description", "React::IrisRtcSdk Missing mandatory parameters, check whether you have passed roomToken, roomTokenExpiry and rtcServer !!!");
            event.putInt("code ", -1); // To match with ios : TBD

            this.sendEvent(IrisEventOnSessionError, event);
            return;
        }

        // Get the notification data
        IrisRtcVideoSession mSession = new IrisRtcVideoSession(reactContext);
        mSession.isVideoBridge = true;

        // Join the session
        try {
            mSession.join(roomId,
                    sessionConfig.getString("roomToken"),
                    sessionConfig.getString("roomTokenExpiry"),
                    videoStream,
                    sessionConfig.getString("rtcServer"),
                    this);
            videoSessionArray.put(roomId, mSession);
        } catch (IrisRtcSDKException e) {
            Log.e(TAG_RNIRISSDK, e.getStackTrace().toString());
        }
    }

    /**
     * To end a video session
     * @param roomId Room Id
     */
    @ReactMethod
    public void endVideoSession(String roomId)
    {
        Log.i(TAG_RNIRISSDK, " endVideoSession called with " + roomId  );

        // Check the room id
        if (!videoSessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + roomId + " is not created yet");
            return;
        }

        // Get the video session
        IrisRtcVideoSession mSession = videoSessionArray.get(roomId);
        mSession.closeSession();
        videoSessionArray.remove(mSession);

        // TBD: Broadcast a notification to delete the renderers
        // Send a notification to delete the renderer/videoview
        Intent intent = new Intent("onAllTracksDeleted");
        LocalBroadcastManager.getInstance(reactContext).sendBroadcast(intent);
    }

    /**
     * To create a chat session
     * @param roomId Room Id
     * @param name Name
     */
    @ReactMethod
    public void createChatSession(String roomId, String name)
    {
        Log.i(TAG_RNIRISSDK, " createChatSession called with " + roomId + ":" + name );

        // Check the room id
        if (chatSessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + roomId + " is already created");
            return;
        }

        // Init the session
        IrisRtcChatSession mSession = new IrisRtcChatSession(reactContext);
        mSession.isVideoBridge = true;

        // Create the session
        try {
            mSession.create(roomId, "", this);
            chatSessionArray.put(roomId, mSession);

            // TBD profile
        } catch (IrisRtcSDKException e) {
            Log.e(TAG_RNIRISSDK, e.getStackTrace().toString());
        }
    }
    /**
     * To end a chat session
     * @param roomId Room Id
     */
    @ReactMethod
    public void endChatSession(String roomId)
    {
        Log.i(TAG_RNIRISSDK, " endChatSession called with " + roomId );

        // Check the room id
        if (!chatSessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + roomId + " is not found");
            return;
        }

        // Init the session
        IrisRtcChatSession mSession = chatSessionArray.get(roomId);
        mSession.close();
    }

    /**
     * To send a chat message
     * @param roomId Room Id
     */
    @ReactMethod
    public void sendChatMessage(String roomId, String message, String id)
    {
        Log.i(TAG_RNIRISSDK, " sendChatMessage called with " + roomId + ":" + message + ":" + id );

        // Check the room id
        if (chatSessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, " Sending message through chatsession ");
            // Init the session
            IrisRtcChatSession mSession = chatSessionArray.get(roomId);
            IrisChatMessage mMessage = new IrisChatMessage(message, id);
            mSession.sendChatMessage(mMessage);
        }
        // Check the room id
        if (videoSessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, " Sending message through videosession ");
            // Init the session
            IrisRtcVideoSession mSession = videoSessionArray.get(roomId);
            IrisChatMessage mMessage = new IrisChatMessage(message, id);
            mSession.sendChatMessage(mMessage);
        }
        // Check the room id
        if (sessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, " Sending message through video+chat session ");
            // Init the session
            IrisRtcSession mSession = sessionArray.get(roomId);
            IrisChatMessage mMessage = new IrisChatMessage(message, id);
            mSession.sendChatMessage(mMessage);
        }
    }

    /**
     * To send chat state
     * @param roomId Room id
     * @param state chat state
     */
    @ReactMethod
    public void sendChatState(String roomId, String state)
    {
        Log.i(TAG_RNIRISSDK, " sendChatState called with " + roomId + ":" + state );

        // Check the room id
        if (!chatSessionArray.containsKey(roomId))
        {
            Log.e(TAG_RNIRISSDK, "A  session with RoomId " + roomId + " is not found");
            return;
        }

        // Init the session
        IrisRtcChatSession mSession = chatSessionArray.get(roomId);
        IrisChatState chatstate;

        // Check chat state
        if (state == "composing")
        {
            chatstate = IrisChatState.COMPOSING;
        }
        else if (state == "inactive")
        {
            chatstate = IrisChatState.INACTIVE;
        }
        else if (state == "paused")
        {
            chatstate = IrisChatState.PAUSED;
        }
        else if (state == "gone")
        {
            chatstate = IrisChatState.GONE;
        }
        else if (state == "active")
        {
            chatstate = IrisChatState.ACTIVE;
        }
        else
        {
            Log.e(TAG_RNIRISSDK, " Invalid state " );
            return;
        }

        // Send chat state
        mSession.sendChatState(chatstate);
    }
    /**
     * Callback: This is called to notify SIP status during session.
     *
     * @param status Iris sip status
     * @param roomId
     */
    @Override
    public void onSessionSIPStatus(IrisRtcAudioSession.IrisSIPStatus status, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionSIPStatus called with " + String.valueOf(status));

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);

        int mStatus =0;
        switch (status)
        {
            case kInitializing:mStatus=0;break;
            case kConnecting:mStatus=1;break;
            case kConnected:mStatus=2;break;
            case kDisconnected:mStatus=3;break;
        }
        event.putInt("status", mStatus);
        this.sendEvent(IrisEventOnSessionSIPStatus, event);
    }

    /**
     * Callback: This is called when merging of active session with the held session for PSTN call.
     *
     * @param roomId room id recieved from Iris backend.
     */
    @Override
    public void onSessionMerged(String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionMerged called with " + roomId);

    }

    /**
     * Callback: This is called when the Ice connection state that is,session is connected.
     *
     * @param roomId room id.
     */
    @Override
    public void onSessionConnected(String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionConnected called with " + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);

        this.sendEvent(IrisEventOnSessionConnected, event);
    }

    /**
     * Callback: This is called when dominant speaker is changed in multiple stream.
     *
     * @param participantId participant id.
     * @param roomId        room id.
     */
    @Override
    public void onSessionDominantSpeakerChanged(String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionDominantSpeakerChanged called with " + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);

        this.sendEvent(IrisEventOnSessionDominantSpeakerChanged, event);
    }

    /**
     * Callback: This is called when stream of particular participant is activated/viewed in multiple stream.
     *
     * @param participantId participant id.
     * @param roomId        room id.
     */
    @Override
    public void onSessionRemoteParticipantActivated(String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionRemoteParticipantActivated called with " + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);

        this.sendEvent(IrisEventOnSessionRemoteParticipantActivated, event);
    }

    /**
     * Callback: This is called when video of remote participant muted or unmuted.
     *
     * @param mute          video state mute or unmute.
     * @param participantId participant id.
     * @param roomId        room id.
     */
    @Override
    public void onSessionParticipantVideoMuted(boolean mute, String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionParticipantVideoMuted called with " + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);
        event.putBoolean("Mute", mute);

        this.sendEvent(IrisEventOnSessionParticipantVideoMuted, event);
    }

    /**
     * Callback: This is called when audio of remote participant muted or unmuted.
     *
     * @param mute          audio state mute or unmute.
     * @param participantId paritcipant id.
     * @param roomId        room id.
     */
    @Override
    public void onSessionParticipantAudioMuted(boolean mute, String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionParticipantAudioMuted called with " + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);
        event.putBoolean("Mute", mute);

        this.sendEvent(IrisEventOnSessionParticipantAudioMuted, event);
    }

    /**
     * Callback: This is called when the room is created successfully.
     *
     * @param roomId room id.
     */
    @Override
    public void onSessionCreated(String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionCreated called with " + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);

        this.sendEvent(IrisEventOnSessionCreated, event);
    }

    /**
     * Callback: This is called when the room is joined successfully from Initiator.
     *
     * @param roomId room id.
     */
    @Override
    public void onSessionJoined(String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionJoined called with " + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);

        this.sendEvent(IrisEventOnSessionJoined, event);
    }

    /**
     * Callback: This is called at the sender side when the remote participant joins the room.
     *
     * @param participantId remote participant Id.
     * @param roomId        room id.
     */
    @Override
    public void onSessionParticipantJoined(String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionParticipantJoined called with " + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);

        this.sendEvent(IrisEventOnSessionParticipantJoined, event);
    }

    /**
     * Callback: This is called when the session ends.
     *
     * @param roomId room id.
     */
    @Override
    public void onSessionEnded(String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionEnded called with " + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);

        this.sendEvent(IrisEventOnSessionDisconnected, event);
    }

    /**
     * Callback: This is called when the participant leaves the room.
     *
     * @param participantId Id of the participant who left the room .
     * @param roomId        room id.
     */
    @Override
    public void onSessionParticipantLeft(String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionParticipantLeft called with " + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);

        this.sendEvent(IrisEventOnSessionParticipantLeft, event);
    }

    /**
     * Callback: This is called when there is error while the session is active.
     *
     * @param error          The basic error code details.
     * @param additionalInfo Additional error details including description.
     * @param roomId         room id.
     */
    @Override
    public void onSessionError(WebRTCError.ErrorCode error, JSONObject additionalInfo, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionError called with " + error.getErorDescription() + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("description", error.getErorDescription());
        event.putInt("value", error.getValue());

        this.sendEvent(IrisEventOnSessionError, event);
    }

    /**
     * Callback: This is called when there is any message is to be convey to the app.
     *
     * @param log    message to the app.
     * @param roomId room id.
     */
    @Override
    public void onLogAnalytics(String log, String roomId) {
        Log.i(TAG_RNIRISSDK, " onLogAnalytics called with " + roomId + ":" + log);
    }

    /**
     * Callback: This is called when participant profile is received.
     *
     * @param userProfile   IrisRtcUserProfile instance
     * @param participantId id of participant
     * @param roomId        room id.
     */
    @Override
    public void onSessionParticipantProfile(IrisRtcUserProfile userProfile, String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionParticipantProfile called with " + participantId + ":" + roomId + ":" + userProfile.getName() + ":" + userProfile.getAvatarUrl());

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);
        event.putString("Name", userProfile.getName());
        event.putString("AvatarUrl", userProfile.getAvatarUrl());

        this.sendEvent(IrisEventOnSessionParticipantProfile, event);
    }

    /**
     * Callback: This is called when remote participant is not responding.
     *
     * @param participantId paritcipant id.
     * @param roomId        room id.
     */
    @Override
    public void onSessionParticipantNotResponding(String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionParticipantNotResponding called with " + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);

        this.sendEvent(IrisEventOnSessionParticipantNotResponding, event);
    }

    /**
     * Callback: This is called when session type is changed by upgrading to video/downgrading to chat.
     *
     * @param sessionType   changed session type.
     * @param participantId id of participant.
     * @param roomId        room id.
     */
    @Override
    public void onSessionTypeChanged(String sessionType, String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionTypeChanged called with " + sessionType + ":" + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("RoutingId", participantId);
        event.putString("SessionType", sessionType);

        this.sendEvent(IrisEventOnSessionTypeChanged, event);
    }

    /**
     * Callback: This is called when the remote stream is added to peerconnection.
     *
     * @param mediaTrack    IrisRtcMediaTrack containing remote track.
     * @param participantId Participant Id.
     * @param roomId        Room Id.
     */
    @Override
    public void onAddRemoteStream(IrisRtcMediaTrack mediaTrack, String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onAddRemoteStream called with " + participantId + ":" + roomId);

        // Create a unique id for track
        String uuid = participantId;
        if (participantId.length() == 0)
        {
            uuid = UUID.randomUUID().toString();
        }

        // Add track
        RNIrisSdkStreamManager.getInstance().addTrack(mediaTrack, uuid);

        WritableMap event = Arguments.createMap();
        event.putString("StreamId", uuid);
        event.putString("RoutingId", participantId);
        event.putString("SessionId", roomId);

        this.sendEvent(IrisEventOnRemoteAddStream, event);

        // TBD broadcast notification
    }

    /**
     * Callback: This is called when the remote stream is removed from peerconnection.
     *
     * @param mediaTrack    IrisRtcMediaTrack containing remote track
     * @param participantId Participant Id.
     * @param roomId        Room Id.
     */
    @Override
    public void onRemoveRemoteStream(IrisRtcMediaTrack mediaTrack, String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onRemoveRemoteStream called with " + participantId + ":" + roomId);

        WritableMap event = Arguments.createMap();
        event.putString("StreamId", participantId);
        event.putString("SessionId", roomId);

        this.sendEvent(IrisEventOnRemoteRemoveStream, event);

        // Send a notification to delete the renderer/videoview
        Intent intent = new Intent("onTrackDeleted");
        intent.putExtra("TrackId", participantId);
        LocalBroadcastManager.getInstance(reactContext).sendBroadcast(intent);
    }

    /**
     * This method is called when the remote stream is added to peerconnection.
     *
     * @param chatMessage   message string
     * @param participantId Id sending the chat message
     * @param roomId        Identifier for the allocated  chat room for the participants
     */
    @Override
    public void onSessionParticipantMessage(IrisChatMessage chatMessage, String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onSessionParticipantMessage called with " + participantId + ":" + roomId + ":" + chatMessage.getMessageBody());

        WritableMap event = Arguments.createMap();
        event.putString("participantId", participantId);
        event.putString("roomId", roomId);
        event.putString("childNodeId", chatMessage.getChildNodeId());
        event.putString("rootNodeId", chatMessage.getRootNodeId());
        event.putString("messageId", chatMessage.getMessageId());
        event.putString("data", chatMessage.getMessageBody());

        this.sendEvent(IrisEventOnChatMessage, event);
    }

    /**
     * Callback: This is called when chat message is sent successfully.
     *
     * @param message chat message.
     * @param roomId  Identifier for the allocated  chat room for the participants.
     */
    @Override
    public void onChatMessageSuccess(IrisChatMessage message, String roomId) {
        Log.i(TAG_RNIRISSDK, " onChatMessageSuccess called with " + roomId + ":" + message.getMessageId());

        WritableMap event = Arguments.createMap();
        event.putString("SessionId", roomId);
        event.putString("childNodeId", message.getChildNodeId());
        event.putString("rootNodeId", message.getRootNodeId());
        event.putString("timeReceived", message.getTimeReceived());
        event.putString("messageId", message.getMessageId());

        this.sendEvent(IrisEventOnChatMessageAck, event);

    }

    /**
     * Callback: This is called when chat message sending fails.
     *
     * @param messageId message id.
     * @param errorInfo error info.
     * @param roomId    Identifier for the allocated  chat room for the participants.
     */
    @Override
    public void onChatMessageError(String messageId, JSONObject errorInfo, String roomId) {
        Log.i(TAG_RNIRISSDK, " onChatMessageError called with " + roomId + ":" + messageId);

        WritableMap event = Arguments.createMap();
        event.putString("messageId", messageId);
        event.putString("info", errorInfo.toString());
        event.putString("SessionId", roomId);

        this.sendEvent(IrisEventOnChatMessageError, event);
    }

    /**
     * This method is called when chat state change for the remote participant
     *
     * @param state         chat state.
     * @param participantId Id sending the chat message.
     * @param roomId        Identifier for the allocated  chat room for the participants.
     */
    @Override
    public void onChatMessageState(IrisChatState state, String participantId, String roomId) {
        Log.i(TAG_RNIRISSDK, " onChatMessageState called with " + state + ":" + participantId + ":" + roomId);

        String chatstate;

        // check the state
        if (state == IrisChatState.ACTIVE)
        {
            chatstate = "active";
        }
        else if (state == IrisChatState.COMPOSING)
        {
            chatstate = "composing";
        }
        else if (state == IrisChatState.GONE)
        {
            chatstate = "gone";
        }
        else if (state == IrisChatState.INACTIVE)
        {
            chatstate = "inactive";
        }
        else if (state == IrisChatState.PAUSED)
        {
            chatstate = "paused";
        }
        else
        {
            return;
        }

        WritableMap event = Arguments.createMap();
        event.putString("RoutingId", participantId);
        event.putString("SessionId", roomId);
        event.putString("state", chatstate);

        this.sendEvent(IrisEventOnChatMessageState, event);
    }

}