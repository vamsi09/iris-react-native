
#import "RNIrisSdk.h"
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import "RNIrisSdkStreamManager.h"

@import IrisRtcSdk;

// Constant string for sending events
NSString *  IrisEventOnConnected = @"onConnected";
NSString *  IrisEventOnDisconnected = @"onDisconnected";
NSString *  IrisEventOnReconnecting = @"onReconnecting";
NSString *  IrisEventOnConnectionError = @"onConnectionError";
NSString *  IrisEventOnNotification = @"onNotification";

// Audio Session events
NSString *  IrisEventOnSessionCreated = @"onSessionCreated";
NSString *  IrisEventOnSessionJoined = @"onSessionJoined";

NSString *  IrisEventOnSessionConnected = @"onSessionConnected";
NSString *  IrisEventOnSessionDisconnected = @"onSessionDisconnected";
NSString *  IrisEventOnSessionSIPStatus = @"onSessionSIPStatus";
NSString *  IrisEventOnSessionError = @"onSessionError";

NSString *  IrisEventOnChatMessage = @"onChatMessage";
NSString *  IrisEventOnChatMessageAck = @"onChatMessageAck";
NSString *  IrisEventOnChatMessageState = @"onChatMessageState";
NSString *  IrisEventOnChatMessageError = @"onChatMessageError";

// Video Session events
NSString *  IrisEventOnSessionParticipantJoined = @"onSessionParticipantJoined";
NSString *  IrisEventOnSessionParticipantLeft = @"onSessionParticipantLeft";
NSString *  IrisEventOnSessionTypeChanged = @"onSessionTypeChanged";
NSString *  IrisEventOnSessionParticipantConnected = @"onSessionParticipantConnected";
NSString *  IrisEventOnSessionDominantSpeakerChanged = @"onSessionDominantSpeakerChanged";
NSString *  IrisEventOnSessionParticipantVideoMuted = @"onSessionParticipantVideoMuted";
NSString *  IrisEventOnSessionParticipantAudioMuted = @"onSessionParticipantAudioMuted";

// Video Stream events
NSString *  IrisEventOnStreamError = @"onStreamError";
NSString *  IrisEventOnLocalStream = @"onLocalStream";
NSString *  IrisEventOnRemoteAddStream = @"onRemoteAddStream";
NSString *  IrisEventOnRemoteRemoveStream = @"onRemoteRemoveStream";

@interface RNIrisSdk () <IrisRtcConnectionDelegate, IrisRtcStreamDelegate, IrisRtcAudioSessionDelegate, IrisRtcChatSessionDelegate, IrisRtcVideoSessionDelegate, IrisRtcSessionDelegate>
{
    IrisRtcStream *audioStream;
    IrisRtcStream *videoStream;
    IrisRtcAudioSession *audioSession;
    NSMutableDictionary *audioSessionArray;
    NSMutableDictionary *chatSessionArray;
    NSMutableDictionary *sessionArray;
    NSMutableDictionary *videoSessionArray;
    NSString            *localStreamId;
    BOOL                 isConnected;

}
@end
@implementation RNIrisSdk

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE(IrisRtcSdk)

- (NSArray<NSString *> *)supportedEvents {
  return @[IrisEventOnConnected, IrisEventOnDisconnected, IrisEventOnConnectionError, IrisEventOnNotification,
           IrisEventOnStreamError, IrisEventOnLocalStream, IrisEventOnRemoteAddStream, IrisEventOnRemoteRemoveStream,
           IrisEventOnSessionCreated, IrisEventOnSessionConnected, IrisEventOnSessionDisconnected, IrisEventOnSessionSIPStatus, IrisEventOnSessionError, IrisEventOnSessionJoined,
           IrisEventOnChatMessage, IrisEventOnChatMessageAck, IrisEventOnChatMessageError, IrisEventOnChatMessageState,
           IrisEventOnSessionParticipantJoined, IrisEventOnSessionParticipantLeft, IrisEventOnSessionParticipantConnected, IrisEventOnSessionDominantSpeakerChanged, IrisEventOnSessionTypeChanged, IrisEventOnSessionParticipantVideoMuted, IrisEventOnSessionParticipantAudioMuted
           ];
}

#pragma mark - Connection APIs

/**This API is used to establish a connection with the IRIS backend.
 *
 * @param serverUrl The event manager URL.
 * @param irisToken A valid IRIS token details.
 * @param routingId Self(or)Source routing ID.
 * @warning Please use this api for outgoing calls. Please use
 * connectUsingServer:irisToken:routingId:notificationPayload:delegate api for incoming calls.This api shoule be called
 * only after Retrieving the IRIS token using auth manager,Routing Id through ID manager.
 */
RCT_EXPORT_METHOD(connectUsingServer:(NSString *)serverUrl 
                irisToken:(NSString*)irisToken 
                routingId:(NSString*)routingId)
{
    RCTLogInfo(@"React::IrisRtcSdk connectUsingServer called with url %@ & routing Id %@", serverUrl, routingId);

    if ([IrisRtcConnection  sharedInstance].state != kConnectionStateDisconnected)
    {
        RCTLogInfo(@"React::IrisRtcSdk Already connected !!!");
       // [[IrisRtcConnection  sharedInstance] disconnect];
         //[self sendEventWithName:IrisEventOnConnected body:nil];
        return;

    }
    // Make the connection using Iris APIs
    [[IrisRtcConnection  sharedInstance] connectUsingServer:serverUrl irisToken:irisToken routingId:routingId delegate:self error:nil];
    isConnected = false;
}

/**This API is used to establish a connection with the IRIS backend.
 *
 * @param serverUrl The event manager URL.
 * @param irisToken A valid IRIS token details.
 * @param routingId Self routing ID.
 * @param notificationPayload This contains details like timestamp, xmpptoken, rtcServerURL.
 * @warning Please use this api for incoming calls. Please use
 * connectUsingServer:irisToken:routingId:delegate api for outgoing calls.This api shoule be called
 * only after Retrieving the IRIS token using auth manager,Routing Id through ID manager.
 */
RCT_EXPORT_METHOD(connectUsingNotificationPayload:(NSString*)serverUrl 
                irisToken:(NSString*)irisToken 
                routingId:(NSString*)routingId 
                )
{
    RCTLogInfo(@"React::IrisRtcSdk connectUsingNotificationPayload called with url %@ & routing Id %@", serverUrl, routingId);
    if ([IrisRtcConnection  sharedInstance].state != kConnectionStateDisconnected)
    {
        RCTLogInfo(@"React::IrisRtcSdk Already connected !!!");
         //[self sendEventWithName:IrisEventOnConnected body:nil];
        return;
        
    }
    // Make the connection using Iris APIs
    [[IrisRtcConnection  sharedInstance] connectUsingServer:serverUrl irisToken:irisToken routingId:routingId delegate:self error:nil];
    isConnected = false;

}

/**
 * This method is called to renew Iris token.
 * @return Nothing
 */
RCT_EXPORT_METHOD(setIrisToken:(NSString*)token)
{
    RCTLogInfo(@"React::setIrisToken ");
    if([token length] != 0){
        [[IrisRtcConnection  sharedInstance]setIrisToken:token error:nil];
        
    }

}
/**
 * This method is called to disconnect from IRIS backend.
 * @return Nothing
 */
RCT_EXPORT_METHOD(disconnect)
{
    RCTLogInfo(@"React::IrisRtcSdk disconnect called ");

    [[IrisRtcConnection  sharedInstance] disconnect];
    isConnected = false;
}


/** This method is called when the connection is established
 *
 */
- (void)onConnected
{
    RCTLogInfo(@"React::IrisRtcSdk onConnected");
    isConnected = true;
    [self sendEventWithName:IrisEventOnConnected body:nil];
}

/** This method is called when the connection is disconnected
 *
 */
- (void)onDisconnected
{
    RCTLogInfo(@"React::IrisRtcSdk onDisconnected");
    isConnected = false;
    [self sendEventWithName:IrisEventOnDisconnected body:nil];
}

/** This method is called when the connection is broken and trying to reconnect back
 *
 */
- (void)onReconnecting
{
    RCTLogInfo(@"React::IrisRtcSdk onReconnecting");
    isConnected = false;
    [self sendEventWithName:IrisEventOnReconnecting body:nil];
}

/** This method is called when there is an error
 *
 * @param error The basic error code details
 * @param info Additional details for debugging.
 */
- (void)onError:(NSError *)error withAdditionalInfo:(nullable NSDictionary *)info
{
    isConnected = false;
    RCTLogInfo(@"React::IrisRtcSdk error with info %@", [error description]);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:RCTJSErrorFromNSError(error) forKey:@"Error"];
    [details setValue:[NSNumber numberWithInteger:error.code]forKey:@"ErrorCode"];
    
    [self sendEventWithName:IrisEventOnConnectionError body:details];
}

/** This method is called when there is an notification via xmpp
 *
 * @param data The dictionary containing notification payload
 */
- (void)onNotification:(NSDictionary *)data
{
    RCTLogInfo(@"React::IrisRtcSdk onNotification %@", [data description]);
    [self sendEventWithName:IrisEventOnNotification body:data];
    
}

#pragma mark - Stream APIs

/** This method is called to create a audio stream
 *
 */
RCT_EXPORT_METHOD(createAudioStream)
{
    RCTLogInfo(@"React::IrisRtcSdk createAudioStream called ");

    audioStream = [[IrisRtcStream alloc] initWithType:kStreamTypeAudio quality:kStreamQualityFullHD
                                   cameraType:kCameraTypeFront delegate:self error:nil];
    RCTLogInfo(@"React::IrisRtcSdk createAudioStream done ");

}

/** This method is called to create a video stream
 *
 */
RCT_EXPORT_METHOD(createVideoStream:(BOOL)useBackCamera useHD:(BOOL)useHD)
{
    RCTLogInfo(@"React::IrisRtcSdk createVideoStream called with %d", useBackCamera);
    
    IrisRtcCameraType cameraType=useBackCamera ? kCameraTypeBack: kCameraTypeFront;
    IrisRtcSdkStreamQuality streamQuality = useHD ? kStreamQualityHD: kStreamQualityVGA;

    videoStream = [[IrisRtcStream alloc] initWithType:kStreamTypeVideo quality:streamQuality cameraType:cameraType delegate:self error:nil];
    [videoStream startPreview];
    
    
    RCTLogInfo(@"React::IrisRtcSdk createVideoStream done ");
}

/** This method is called to start a local preview
 *
 */
RCT_EXPORT_METHOD(startPreview)
{
    RCTLogInfo(@"React::IrisRtcSdk startPreview called ");
    
    // Check if the localstream is created or not
    if (videoStream)
    {
        [videoStream startPreview];
    }
}

/** This method is called to start a local preview
 *
 */
RCT_EXPORT_METHOD(closeStream)
{
    RCTLogInfo(@"React::IrisRtcSdk closeStream called ");
    
    // Check if the localstream is created or not
    if (videoStream)
    {
        RCTLogInfo(@"React::IrisRtcSdk videoStream close called ");
        [videoStream stopPreview];
        [videoStream close];
        videoStream = nil;
        if (localStreamId)
        {
            //[[RNIrisSdkStreamManager getInstance] removeTrack:localStreamId];
            NSDictionary *userInfo = @{ @"TrackId": localStreamId };
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"onTrackDeleted"
             object:self userInfo:userInfo];
        }
    }
}

/** This method is called to start a local preview
 *
 */
RCT_EXPORT_METHOD(stopPreview)
{
    RCTLogInfo(@"React::IrisRtcSdk stopPreview called ");
    
    // Check if the localstream is created or not
    if (videoStream)
    {
        [videoStream stopPreview];
    }
}

/** This method is called to mute audio
 *
 */
RCT_EXPORT_METHOD(mute)
{
    RCTLogInfo(@"React::IrisRtcSdk mute called ");
    
    // Check if the localstream is created or not
    if (videoStream)
    {
        [videoStream mute];
    }
    
    if (audioStream)
    {
        [audioStream mute];
    }
}

/** This method is called to unmute audio
 *
 */
RCT_EXPORT_METHOD(unmute)
{
    RCTLogInfo(@"React::IrisRtcSdk unmute called ");
    
    // Check if the localstream is created or not
    if (videoStream)
    {
        [videoStream unmute];
    }
    
    if (audioStream)
    {
        [audioStream unmute];
    }
}

/** This method is called to flip camera
 *
 */
RCT_EXPORT_METHOD(flip)
{
    RCTLogInfo(@"React::IrisRtcSdk flip called ");
    
    // Check if the localstream is created or not
    if (videoStream)
    {
        [videoStream flip];
    }
}

#pragma mark - Audio Session APIs

/** This method is called to create a audio session
 *
 */
RCT_EXPORT_METHOD(createAudioSession:(NSString*)roomId participantId:(NSString*)participantId _sourceTelephoneNum:(NSString*)sourceTN _targetTelephoneNumber:(NSString*)targetTN  notificationData:(NSString*)notificationData)
                  
{
    RCTLogInfo(@"React::IrisRtcSdk createAudioSession called with roomid %@ & participant id %@ Src TN %@ Target TN %@ notificationdata %@", roomId, participantId, sourceTN, targetTN, notificationData );
    
    if (audioStream == nil)
    {
        audioStream = [[IrisRtcStream alloc] initWithType:kStreamTypeAudio quality:kStreamQualityFullHD
                                               cameraType:kCameraTypeFront delegate:self error:nil];
        RCTLogInfo(@"React::IrisRtcSdk createAudioStream done ");
        
    }
    [audioStream startPreview];
    audioSession = [[IrisRtcAudioSession alloc] init];
    audioSession.autoDisconnect = true;

    audioSession.isVideoBridgeEnable = true;
    IrisRtcSessionConfig *sessionConfig = [[IrisRtcSessionConfig alloc] init];
    
    [audioSession createWithRoomId:roomId participantId:participantId _sourceTelephoneNum:sourceTN _targetTelephoneNumber:targetTN notificationData:notificationData stream:audioStream sessionConfig:sessionConfig delegate:self error:nil];
    
    
    if (audioSessionArray == nil)
    {
        audioSessionArray = [[NSMutableDictionary alloc] init];
    }
    audioSessionArray[roomId] = audioSession;
}

/** This method is called to create a audio session
 *
 */
RCT_EXPORT_METHOD(createAudioSession1:(NSString*)targetTN _sourceTelephoneNumber:(NSString*)sourceTN  notificationData:(NSString*)notificationData)

{
    RCTLogInfo(@"React::IrisRtcSdk createAudioSession1 called with Src TN %@ Target TN %@ notificationdata %@", sourceTN, targetTN, notificationData );
    
    if (audioStream == nil)
    {
        audioStream = [[IrisRtcStream alloc] initWithType:kStreamTypeAudio quality:kStreamQualityFullHD
                                               cameraType:kCameraTypeFront delegate:self error:nil];
        RCTLogInfo(@"React::IrisRtcSdk createAudioStream1 done ");
        
    }
    if([[IrisRtcConnection sharedInstance]state] != kConnectionStateAuthenticated){
        RCTLogInfo(@"React::IrisRtcSdk IrisRtcConnection is not connected ");
        return;
    }
    
    if([IrisRtcConnection sharedInstance] )
    [audioStream startPreview];
    audioSession = [[IrisRtcAudioSession alloc] init];
    audioSession.autoDisconnect = true;
    
    audioSession.isVideoBridgeEnable = true;
    IrisRtcSessionConfig *sessionConfig = [[IrisRtcSessionConfig alloc] init];
    
    [audioSession createWithTN:targetTN _sourceTelephoneNum:sourceTN notificationData:notificationData stream:audioStream sessionConfig:sessionConfig delegate:self error:nil];
    
    
    if (audioSessionArray == nil)
    {
        audioSessionArray = [[NSMutableDictionary alloc] init];
    }
    audioSessionArray[targetTN] = audioSession;
}


/**
 * This method is called to join pstn/audio session which involves joining the room using the room id recieved in notification.
 *
 * @param sessionId    room name that needs to be joined which is recieved in notification.
 * @param stream       local audio stream.
 * @param delegate     delegate object for IrisRtcAudioSession,used to receive the callbacks
 * @param outError Provides error code and basic error description when any exception occured in api call.
 */
RCT_EXPORT_METHOD(joinAudioSession:(NSString*)roomId roomToken:(NSString*)roomToken roomTokenExpiryTime:(NSInteger)roomTokenExpiry rtcServer:(NSString*)_rtcServer targetTN:(NSString*)targetTN)
{
    RCTLogInfo(@"React::IrisRtcSdk joinAudioSession called with roomId %@ & roomToken %@ roomTokenExpiryTime %ld", roomId, roomToken, (long)roomTokenExpiry);
    
    if (audioStream == nil)
    {
        audioStream = [[IrisRtcStream alloc] initWithType:kStreamTypeAudio quality:kStreamQualityFullHD
                                               cameraType:kCameraTypeFront delegate:self error:nil];
        RCTLogInfo(@"React::IrisRtcSdk createAudioStream done ");
    }
     [audioStream startPreview];
    audioSession = [[IrisRtcAudioSession alloc] init];
    audioSession.autoDisconnect = true;

    [audioSession setIsVideoBridgeEnable:true];

    IrisRtcSessionConfig *sessionConfig = [[IrisRtcSessionConfig alloc]init];

    [audioSession joinWithSessionId:roomId roomToken:roomToken roomTokenExpiryTime:roomTokenExpiry stream:audioStream rtcServer:_rtcServer sessionConfig:sessionConfig delegate:self error:nil];
    
    if (audioSessionArray == nil)
    {
        audioSessionArray = [[NSMutableDictionary alloc] init];
    }
    audioSessionArray[targetTN] = audioSession;
}



/**
 * This method is to reject the incoming call
 */
RCT_EXPORT_METHOD(reject:(NSString*)sessionId toId:(NSString *) toId traceId:(NSString *) traceId server:(NSString *) server)
{
    if ([IrisRtcConnection  sharedInstance].state != kConnectionStateAuthenticated)
    {
        RCTLogInfo(@"React::RTC connection is not connected");
        // [[IrisRtcConnection  sharedInstance] disconnect];
        //[self sendEventWithName:IrisEventOnConnected body:nil];
        return;
        
    }
    
    [IrisRtcAudioSession reject:sessionId toId:toId traceId:traceId server:server error:nil];
}

/**
 * This method is called to hold the pstn session
 */
RCT_EXPORT_METHOD(hold:(NSString*)sessionId)
{
    if (audioSessionArray[sessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk audioSession not created yet ");
        return;
    }
    
    [audioSessionArray[sessionId] hold];
}

/**
 * This method is called to hold the pstn session
 */
RCT_EXPORT_METHOD(unhold:(NSString*)sessionId)
{
    if (audioSessionArray[sessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk audioSession not created yet ");
        return;
    }
    
    [audioSessionArray[sessionId] unhold];
}

/**
 * This method is called to hold the pstn session
 */
RCT_EXPORT_METHOD(mergeCall:(NSString*)mySessionId sessionToBeMerged:(NSString*)sessionToBeMerged)
{
    if (audioSessionArray[mySessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk audioSession not created yet ");
        return;
    }
    
    [audioSessionArray[mySessionId] mergeSession:audioSessionArray[sessionToBeMerged]];
}

/**
 * This method is used for sending dtmf tones.
 */
RCT_EXPORT_METHOD(sendDTMF:(NSString*)sessionId tone:(NSString*)tone)
{
    if (audioSessionArray[sessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk audioSession not created yet ");
        return;
    }
    


    // DTMF key map
    NSDictionary<NSString*,NSNumber*> * DTMFKeyMap = @{
                                @"1": @(kNumber1),
                                @"2": @(kNumber2),
                                @"3": @(kNumber3),
                                @"4": @(kNumber4),
                                @"5": @(kNumber5),
                                @"6": @(kNumber6),
                                @"7": @(kNumber7),
                                @"8": @(kNumber8),
                                @"9": @(kNumber9),
                                @"0": @(kNumber0),
                                @"*": @(kStar),
                                @"#": @(kHash),
                                @"A": @(kLetterA),
                                @"B": @(kLetterB),
                                @"C": @(kLetterC),
                                @"D": @(kLetterD),
                                };
    
    if (DTMFKeyMap[tone] != nil)
    {
        //NSNumber toneValue =
        [audioSessionArray[sessionId] insertDTMFtone:DTMFKeyMap[tone].integerValue];
    }
    else
    {
        RCTLogInfo(@"React::IrisRtcSdk wrong DTMF key ");
        return;
    }
    
}

/**
 * This method is called to close the session
 */
RCT_EXPORT_METHOD(endAudioSession:(NSString*)sessionId)
{
    RCTLogInfo(@"React::IrisRtcSdk endAudioSession with %@ ", sessionId);

    if (audioSessionArray[sessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk audioSession not created yet ");
        return;
    }
    
    [audioSessionArray[sessionId] close];
    [audioSessionArray removeObjectForKey:sessionId];

}

#pragma mark - Chat-Video Session APIs

/** This method is called to create a video session
 *
 */
RCT_EXPORT_METHOD(createSession:(NSString*)roomId sessionConfig:(NSDictionary *)sessionConfig)
{
    NSString *notificationData = nil;
    RCTLogInfo(@"React::IrisRtcSdk createSession with %@", roomId);
    if (sessionArray == nil)
    {
        sessionArray = [[NSMutableDictionary alloc] init];
    }
    // Check if chat session is already created for this room id
    if ( [sessionArray objectForKey:roomId] != nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk A  session with RoomId %@ is already created", roomId);
        return;
    }
    IrisRtcSession * session = [[IrisRtcSession alloc] init];
    session.autoDisconnect = false;
    
    [session setIsVideoBridgeEnable:true];
    [sessionArray setObject:session forKey:roomId];
    
    // Check if the session has config
    if (sessionConfig)
    {
        notificationData = [sessionConfig objectForKey:@"notificationData"];
        if(session != nil){
            NSString* videoCodecType = [sessionConfig objectForKey:@"videoCodecType"];
            
            if(videoCodecType != nil){
                if(![videoCodecType compare:@"h264" options:NSCaseInsensitiveSearch]){
                    session.preferredVideoCodecType = kCodecTypeH264;
                }
                else
                    if(![videoCodecType compare:@"vp8" options:NSCaseInsensitiveSearch]){
                        session.preferredVideoCodecType = kCodecTypeVP8;
                    }
            }
            
            NSString* audioCodecType = [sessionConfig objectForKey:@"audioCodecType"];
            if(audioCodecType != nil){
                
                if(![audioCodecType compare:@"opus" options:NSCaseInsensitiveSearch]){
                    session.preferredAudioCodecType = kCodecTypeOPUS;
                }
                else
                    if(![audioCodecType compare:@"isac16k" options:NSCaseInsensitiveSearch]){
                        session.preferredAudioCodecType = kCodecTypeISAC16000;
                    }
                    else
                        if(![audioCodecType compare:@"isac30k" options:NSCaseInsensitiveSearch]){
                            session.preferredAudioCodecType = kCodecTypeISAC32000;
                        }
            }
            
        }
    }
    IrisRtcSessionConfig *rtcSessionConfig = [[IrisRtcSessionConfig alloc]init];
    
    if (![session createWithRoomId:roomId sessionConfig:rtcSessionConfig delegate:self error:nil])
    {
        // Handle error
    }
}

/** This method is called to accept a video session
 *
 */
RCT_EXPORT_METHOD(joinSession:(NSString*)roomId sessionConfig:(NSDictionary *)sessionConfig)
{
    RCTLogInfo(@"React::IrisRtcSdk joinVideoSession with %@", roomId);
    if (sessionArray == nil)
    {
        sessionArray = [[NSMutableDictionary alloc] init];
    }
    // Check if chat session is already created for this room id
    if ( [sessionArray objectForKey:roomId] != nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk A video session with RoomId %@ is already created", roomId);
        return;
    }
    IrisRtcSession * session = [[IrisRtcSession alloc] init];
    session.autoDisconnect = false;
    
    [session setIsVideoBridgeEnable:true];
    [videoSessionArray setObject:session forKey:roomId];
    
    // Check if the session has config
    if (!sessionConfig ||
        ![sessionConfig objectForKey:@"roomToken"] ||
        ![sessionConfig objectForKey:@"roomTokenExpiry"] ||
        ![sessionConfig objectForKey:@"rtcServer"])
    {
        RCTLogInfo(@"React::IrisRtcSdk Missing mandatory parameters !!!");
        NSString *errorMessage = @"React::IrisRtcSdk Missing mandatory parameters, check whether you have passed roomToken, roomTokenExpiry and rtcServer !!!";
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        [self sendEventWithName:IrisEventOnSessionError body:RCTJSErrorFromNSError([NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo])];
        return;
        
    }
    
    if(sessionConfig != nil && session != nil){
        NSString* videoCodecType = [sessionConfig objectForKey:@"videoCodecType"];
        RCTLogInfo(@"upgradeToVideo::createSession::videoCodecType = %@",videoCodecType);
        if(videoCodecType != nil){
            if(![videoCodecType compare:@"h264" options:NSCaseInsensitiveSearch]){
                session.preferredVideoCodecType = kCodecTypeH264;
            }
            else
                if(![videoCodecType compare:@"vp8" options:NSCaseInsensitiveSearch]){
                    session.preferredVideoCodecType = kCodecTypeVP8;
                }
        }
        
        NSString* audioCodecType = [sessionConfig objectForKey:@"audioCodecType"];
        if(audioCodecType != nil){
            
            if(![audioCodecType compare:@"opus" options:NSCaseInsensitiveSearch]){
                session.preferredAudioCodecType = kCodecTypeOPUS;
            }
            else
                if(![audioCodecType compare:@"isac16k" options:NSCaseInsensitiveSearch]){
                    session.preferredAudioCodecType = kCodecTypeISAC16000;
                }
                else
                    if(![audioCodecType compare:@"isac30k" options:NSCaseInsensitiveSearch]){
                        session.preferredAudioCodecType = kCodecTypeISAC32000;
                    }
        }
        
    }
    
    IrisRtcSessionConfig *rtcSessionConfig = [[IrisRtcSessionConfig alloc]init];
    
    // Join the video call
    if (![session joinWithSessionId:roomId roomToken:[sessionConfig objectForKey:@"roomToken"] roomTokenExpiryTime:[[sessionConfig objectForKey:@"roomTokenExpiry"] integerValue]  stream:videoStream rtcServer:[sessionConfig objectForKey:@"rtcServer"] sessionConfig:rtcSessionConfig delegate:self error:nil])
    {
        // Handle error
    }
}

/**
 * This method is called to upgrade to video session from chat.
 */
RCT_EXPORT_METHOD(upgradeToVideo:(NSString*)sessionId sessionConfig:(NSDictionary *)sessionConfig)
{
    RCTLogInfo(@"React::IrisRtcSdk upgradeToVideo with %@", sessionId);
    
    if (sessionArray[sessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk videoSession not created yet ");
        return;
    }
    NSString* notificationData;
     IrisRtcSession *session = [sessionArray objectForKey:sessionId];
    if (sessionConfig != nil && session != nil)
    {
        notificationData = [sessionConfig objectForKey:@"notificationData"];
        
        NSString* videoCodecType = [sessionConfig objectForKey:@"videoCodecType"];
        if(videoCodecType != nil){
            if(![videoCodecType compare:@"h264" options:NSCaseInsensitiveSearch]){
                session.preferredVideoCodecType = kCodecTypeH264;
            }
            else
                if(![videoCodecType compare:@"vp8" options:NSCaseInsensitiveSearch]){
                    session.preferredVideoCodecType = kCodecTypeVP8;
                }
        }
        
        NSString* audioCodecType = [sessionConfig objectForKey:@"audioCodecType"];
        if(audioCodecType != nil){
            
            if(![audioCodecType compare:@"opus" options:NSCaseInsensitiveSearch]){
                session.preferredAudioCodecType = kCodecTypeOPUS;
            }
            else
                if(![audioCodecType compare:@"isac16k" options:NSCaseInsensitiveSearch]){
                    session.preferredAudioCodecType = kCodecTypeISAC16000;
                }
                else
                    if(![audioCodecType compare:@"isac30k" options:NSCaseInsensitiveSearch]){
                        session.preferredAudioCodecType = kCodecTypeISAC32000;
                    }
        }
        
    }
    
    if (session != nil)
    {
        [session upgradeToVideo:videoStream notificationData:notificationData];
    }
}

/**
 * This method is called to upgrade to video session from chat.
 */
RCT_EXPORT_METHOD(downgradeToChat:(NSString*)sessionId)
{
    RCTLogInfo(@"React::IrisRtcSdk downgradeToChat with %@", sessionId);
    
    if (sessionArray[sessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk videoSession not created yet ");
        return;
    }
    
    IrisRtcSession *session = [sessionArray objectForKey:sessionId];
    if (session != nil)
    {
        // Delete all renderers
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"onAllTracksDeleted"
         object:self];
        
        [session downgradeToChat];
    }
}

/**
 * This method is called to close the session
 */
RCT_EXPORT_METHOD(endSession:(NSString*)sessionId)
{
    RCTLogInfo(@"React::IrisRtcSdk endSession with %@", sessionId);
    
    if (sessionArray[sessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk videoSession not created yet ");
        return;
    }
    
    [sessionArray[sessionId] close];
    [sessionArray removeObjectForKey:sessionId];
    
    // Delete all renderers
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"onAllTracksDeleted"
     object:self];
}

/**
 * This method is called to mute remote participant video.
 */

RCT_EXPORT_METHOD(muteParticipantVideo:(NSString*)sessionId muteStatus:(BOOL)status participantId:(NSString*)participantId)
{
    RCTLogInfo(@"React::IrisRtcSdk muteParticipantVideo for %@", participantId);
    
    if (sessionArray[sessionId] == nil || participantId == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk videoSession not created yet or participantId is null");
        return;
    }
    
    if(status){
        [sessionArray[sessionId] muteVideo:participantId];
    }
    else{
        [sessionArray[sessionId] unmuteVideo:participantId];
    }
    
}


#pragma mark - Video Session APIs

/** This method is called to create a video session
 *
 */
RCT_EXPORT_METHOD(createVideoSession:(NSString*)roomId videoSessionConfig:(NSDictionary *)videoSessionConfig)
{
    NSString *notificationData = nil;
    RCTLogInfo(@"React::IrisRtcSdk createVideoSession with %@", roomId);
    if (videoSessionArray == nil)
    {
        videoSessionArray = [[NSMutableDictionary alloc] init];
    }
    // Check if chat session is already created for this room id
    if ( [videoSessionArray objectForKey:roomId] != nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk A video session with RoomId %@ is already created", roomId);
        return;
    }
    IrisRtcVideoSession * videoSession = [[IrisRtcVideoSession alloc] init];
    videoSession.autoDisconnect = false;

    [videoSession setIsVideoBridgeEnable:true];
    [videoSessionArray setObject:videoSession forKey:roomId];
    
    // Check if the session has config
    if (videoSessionConfig)
    {
        notificationData = [videoSessionConfig objectForKey:@"notificationData"];
    }
    IrisRtcSessionConfig *sessionConfig = [[IrisRtcSessionConfig alloc]init];

    if (![videoSession createWithRoomId:roomId notificationData:notificationData stream:videoStream sessionConfig:sessionConfig delegate:self error:nil])
    {
        // Handle error
    }
}

/** This method is called to accept a video session
 *
 */
RCT_EXPORT_METHOD(joinVideoSession:(NSString*)roomId videoSessionConfig:(NSDictionary *)videoSessionConfig)
{
    RCTLogInfo(@"React::IrisRtcSdk joinVideoSession with %@", roomId);
    if (videoSessionArray == nil)
    {
        videoSessionArray = [[NSMutableDictionary alloc] init];
    }
    // Check if chat session is already created for this room id
    if ( [videoSessionArray objectForKey:roomId] != nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk A video session with RoomId %@ is already created", roomId);
        return;
    }
    IrisRtcVideoSession * videoSession = [[IrisRtcVideoSession alloc] init];
    videoSession.autoDisconnect = false;

    [videoSession setIsVideoBridgeEnable:true];
    [videoSessionArray setObject:videoSession forKey:roomId];
    
    // Check if the session has config
    if (!videoSessionConfig ||
        ![videoSessionConfig objectForKey:@"roomToken"] ||
        ![videoSessionConfig objectForKey:@"roomTokenExpiry"] ||
        ![videoSessionConfig objectForKey:@"rtcServer"])
    {
        RCTLogInfo(@"React::IrisRtcSdk Missing mandatory parameters !!!");
        NSString *errorMessage = @"React::IrisRtcSdk Missing mandatory parameters, check whether you have passed roomToken, roomTokenExpiry and rtcServer !!!";
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorMessage, NSLocalizedDescriptionKey, errorMessage, NSLocalizedFailureReasonErrorKey, nil];
        [self sendEventWithName:IrisEventOnSessionError body:RCTJSErrorFromNSError([NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo])];
        return;

    }
    IrisRtcSessionConfig *sessionConfig = [[IrisRtcSessionConfig alloc]init];

    // Join the video call
    if (![videoSession joinWithSessionId:roomId roomToken:[videoSessionConfig objectForKey:@"roomToken"] roomTokenExpiryTime:[[videoSessionConfig objectForKey:@"roomTokenExpiry"] integerValue]  stream:videoStream rtcServer:[videoSessionConfig objectForKey:@"rtcServer"] sessionConfig:sessionConfig delegate:self error:nil])
    {
        // Handle error
    }
}


/**
 * This method is called to close the session
 */
RCT_EXPORT_METHOD(endVideoSession:(NSString*)sessionId)
{
    RCTLogInfo(@"React::IrisRtcSdk endVideoSession with %@", sessionId);

    if (videoSessionArray[sessionId] == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk videoSession not created yet ");
        return;
    }
    
    [videoSessionArray[sessionId] close];
    [videoSessionArray removeObjectForKey:sessionId];
    
    // Delete all renderers
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"onAllTracksDeleted"
     object:self];
}

/**
 * This method is called to create a chat session
 */
RCT_EXPORT_METHOD(createChatSession:(NSString*)RoomId name:(NSString*)_name)
{
    RCTLogInfo(@"React::IrisRtcSdk createChatSession with %@", RoomId);
    if (chatSessionArray == nil)
    {
        chatSessionArray = [[NSMutableDictionary alloc] init];
    }
    // Check if chat session is already created for this room id
    if ( [chatSessionArray objectForKey:RoomId] != nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk A chat session with RoomId %@ is already created", RoomId);
        return;
    }
    IrisRtcChatSession * chatSession = [[IrisRtcChatSession alloc] init];
    chatSession.autoDisconnect = false;
    [chatSession setIsVideoBridgeEnable:true];
    [chatSessionArray setObject:chatSession forKey:RoomId];
    
    // Create the actual session now
    if (![chatSession createWithRoomId:RoomId notificationData:nil delegate:self error:nil])
    {
       // Handle error
    }
    
    IrisRtcUserProfile *profile = [[IrisRtcUserProfile alloc] init];
    [profile setName:_name];
    //[chatSession setUserProfile:profile];

}

/**
 * This method is called to end a chat session
 */
RCT_EXPORT_METHOD(endChatSession:(NSString*)RoomId)
{
    RCTLogInfo(@"React::IrisRtcSdk : endChatSession %@", RoomId);
    IrisRtcChatSession *session = [chatSessionArray objectForKey:RoomId];
    if (session != nil)
    {
        [session close];
        session = nil;
        [chatSessionArray removeObjectForKey:RoomId];
    }
    else
    {
        RCTLogInfo(@"React::IrisRtcSdk : Invalid room id or already deleted %@", RoomId);

    }
    
}

/**
 * This method is called to send a chat message
 */
RCT_EXPORT_METHOD(sendChatMessage:(NSString*)RoomId message:(NSString *)_message id:(NSString *)_id)
{
    // Send a chat message
    IrisChatMessage *message = [[IrisChatMessage alloc] initWithMessage:_message messageId:_id];

    IrisRtcChatSession *chatsession = [chatSessionArray objectForKey:RoomId];
    if (chatsession != nil)
    {
        [chatsession sendChatMessage:message error:nil];
    }
    
    IrisRtcChatSession *videoSession = [videoSessionArray objectForKey:RoomId];
    if (videoSession != nil)
    {
        [videoSession sendChatMessage:message error:nil];
    }
    
    IrisRtcSession *session = [sessionArray objectForKey:RoomId];
    if (session != nil)
    {
        [session sendChatMessage:message error:nil];
    }
}


/**
 * This method is called to send a chat message
 */
RCT_EXPORT_METHOD(sendChatState:(NSString*)RoomId state:(NSString *)_state)
{
    // Send a chat message
    IrisChatState state;
    if(![_state compare:@"composing" options:NSCaseInsensitiveSearch]){
        state = COMPOSING;
    }else
    if(![_state compare:@"inactive" options:NSCaseInsensitiveSearch]){
        state = INACTIVE;
    }else
    if(![_state compare:@"paused" options:NSCaseInsensitiveSearch]){
        state = PAUSED;
    }else
    if(![_state compare:@"gone" options:NSCaseInsensitiveSearch]){
        state = GONE;
    }
    else
    if(![_state compare:@"active" options:NSCaseInsensitiveSearch]){
        state = ACTIVE;
    }
    else{
        NSLog(@"Invalid chat state !!");
        return;
    }
    
    IrisRtcChatSession *chatsession = [chatSessionArray objectForKey:RoomId];
    if (chatsession != nil)
    {
        [chatsession sendChatState:state];
    }
    
    IrisRtcChatSession *videoSession = [videoSessionArray objectForKey:RoomId];
    if (videoSession != nil)
    {
        [videoSession sendChatState:state];
    }
    
    IrisRtcSession *session = [sessionArray objectForKey:RoomId];
    if (session != nil)
    {
        [session sendChatState:state];
    }
}


/** This method is called when the local preview is available
 *
 * @param stream Pointer to the stream object.
 * @param mediaTrack Media track that is associated with the camera instance.
 */
-(void)onLocalStream:(IrisRtcStream *)stream mediaTrack:(IrisRtcMediaTrack *)mediaTrack
{
    RCTLogInfo(@"React::IrisRtcSdk : onLocalStream");

    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    // Add the code to manage the local stream
    [[RNIrisSdkStreamManager getInstance] addTrack:uuid track:mediaTrack];
    
    // Send the event that the stream is ready
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:uuid forKey:@"StreamId"];
    localStreamId = uuid;
    [self sendEventWithName:IrisEventOnLocalStream body:details];
    
}

/** This method is called when there in an error during camera capture processs
 *
 * @param stream Pointer to the stream object.
 * @param error Error code and basic description.
 * @param info Additional details for debugging.
 */
-(void)onStreamError:(IrisRtcStream *)stream error:(NSError*)error withAdditionalInfo:(NSDictionary *)info
{
    [self sendEventWithName:IrisEventOnStreamError body:RCTJSErrorFromNSError(error)];
}

/**
 * Callback:This method is called when the room is created successfully.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 */
-(void)onSessionCreated:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnSessionCreated body:details];

}

/**
 * Callback: This is called when the room is joined successfully from reciever.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 */
-(void)onSessionJoined:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnSessionJoined body:details];
}

/**
 * Callback: This is called when the room is joined successfully from reciever.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 */
-(void)onSessionParticipantConnected:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnSessionParticipantConnected body:details];
}


/**
 * Callback: This is called at the sender side when the remote participant joins the room.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 * @param participantName remote participant name.
 */
-(void)onSessionParticipantJoined:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSLog(@"onSessionParticipantJoined participantId = %@ RoomId = %@",participantId,roomId);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"SessionId"];
    [details setValue:participantId forKey:@"RoutingId"];

    [self sendEventWithName:IrisEventOnSessionParticipantJoined body:details];
}

/**
 * Callback: This is called when the Ice connection state that is,session is connected.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 */
-(void)onSessionConnected:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnSessionConnected body:details];

}


/**
 * Callback: This is called at the sender side when the remote participant joins the room.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 * @param routingId target routingId.
 * @param message   Text from message.
 */
-(void)onSessionParticipantMessage:(IrisChatMessage*)message participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;
{
    NSLog(@"onSessionParticipantMessage participantId = %@ RoomId = %@ message = %@",participantId,roomId,message.data);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"roomId"];
    [details setValue:message.childNodeId forKey:@"childNodeId"];
    [details setValue:message.rootNodeId forKey:@"rootNodeId"];
    [details setValue:message.timeReceived forKey:@"timeReceived"];
    [details setValue:message.messageId forKey:@"messageId"];
    [details setValue:message.data forKey:@"data"];
    [details setValue:participantId forKey:@"participantId"];

    [self sendEventWithName:IrisEventOnChatMessage body:details];
    
}

/**
 * Callback: This is called when the session ends.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 */
- (void)onSessionEnded:(NSString*)roomId traceId:(NSString *)traceId;
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnSessionDisconnected body:details];
}

/**
 * Callback: This is called when the participant leaves the room.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 * @param participantName  name of the participant who left the room .
 */
-(void)onSessionParticipantLeft:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSLog(@"onSessionParticipantLeft participantId = %@ RoomId = %@",participantId,roomId);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"SessionId"];
    [details setValue:participantId forKey:@"RoutingId"];
    [self sendEventWithName:IrisEventOnSessionParticipantLeft body:details];
}

/**
 * Callback: This is called when the participant is not responding.
 *
 * @param session   pointer to IrisRtcSession.
 * @param sessionId room id.
 * @param participantName  name of the participant who left the room .
 */
-(void)onSessionParticipantNotResponding:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    
}
-(void)onSessionTypeChanged:(NSString *)sessionType participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSLog(@"RNIrisSdk::onSessionTypeChanged to %@ for %@",sessionType,participantId);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:roomId forKey:@"SessionId"];
    [details setValue:sessionType forKey:@"SessionType"];
    [details setValue:participantId forKey:@"RoutingId"];
    
    [self sendEventWithName:IrisEventOnSessionTypeChanged body:details];
}

-(void)onSessionRemoteParticipantActivated:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    
}

- (void)onSessionParticipantProfile:(NSString *)participantId userProfile:(IrisRtcUserProfile *)userprofile roomId:(NSString *)roomid traceId:(NSString *)traceId;
{
    
}
/**
 * Callback: This is called when there is error while the session is active.
 *
 * @param session   pointer to IrisRtcSession.
 * @param error The basic error code details.
 * @param additionalInfo  Additional error details including description.
 */
-(void)onSessionError:(NSError *)error withAdditionalInfo:(NSDictionary *)info roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    RCTLogInfo(@"React::onSessionError = %@ for roomId : %@", error.description,roomId);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:RCTJSErrorFromNSError(error) forKey:@"Error"];
    [details setValue:[NSNumber numberWithInteger:error.code]forKey:@"ErrorCode"];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnSessionError body:details];

}
/**
 * Callback: This is called when there is any message is to be convey to the app.
 *
 * @param log message to the app.
 */
-(void)onLogAnalytics:(NSString *)log roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    RCTLogInfo(@"React::IrisRtcSdk onLogAnalytics called with %@ for roomId : %@", log,roomId);

}

/**
 * This method is called when merging of active session with the held session for PSTN call.
 *
 * @param IrisRtcSession pointer to the IrisRtcSession
 * @param sessionId room id recieved from Iris backend.
 */
-(void)onSessionMerged:(NSString *)roomId traceId:(NSString *)traceId;
{
    
}
-(void)onSessionSIPStatus:(IrisSIPStatus)status roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionSIPStatus called with %lu", (unsigned long)status);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:[NSNumber numberWithInt:status] forKey:@"status"];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnSessionSIPStatus body:details];

}

- (void)onSessionEarlyMedia:(NSString *)roomId traceId:(NSString *)traceId {
    
}


/**
 * Callback: This is called when dominant speaker is changed in multiple stream.
 *
 * @param rotingId dominant speaker routingid.
 *
 */
-(void)onSessionDominantSpeakerChanged:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionDominantSpeakerChanged called with %@", participantId);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:participantId forKey:@"RoutingId"];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnSessionDominantSpeakerChanged body:details];
}

/**
 * This method is called as an  acknowledggment of  chat message sent to participant.
 *
 *
 * @param ChatAck message string
 */
-(void)onChatMessageSuccess:(IrisChatMessage *)message roomId:(NSString *)roomId traceId:(NSString *)traceId;
{

    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:message.messageId forKey:@"messageId"];
    [details setValue:roomId forKey:@"SessionId"];
    [details setValue:message.rootNodeId forKey:@"rootNodeId"];
    [details setValue:message.childNodeId forKey:@"childNodeId"];
    [details setValue:message.timeReceived forKey:@"timeReceived"];
    
    [self sendEventWithName:IrisEventOnChatMessageAck body:details];
}
/**
 * This method is called as when  chat message is not sent to participant.
 *
 *
 * @param messageId messageid of chat message
 * @param info additional info about error.
 */
-(void)onChatMessageError:(NSString *)messageId withAdditionalInfo:(NSDictionary *)info roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:messageId forKey:@"messageId"];
    [details setValue:info forKey:@"info"];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnChatMessageError body:details];
}

/**
 * This method is called to indicate typing status for the participant.
 *
 *
 * @param IrisChatState chat state
 * @param roomId  recieved from Iris backend.
 * @param participantId  recieved from Iris backend.
 */
-(void)onChatMessageState:(IrisChatState)state participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;
{
    
    NSString* stateString;
    if(state == COMPOSING){
        stateString = @"composing";
    }
    else
    if(state == ACTIVE){
        stateString = @"active";
    }
    else
    if(state == PAUSED){
        stateString = @"paused";
    }
    else
    if(state == INACTIVE){
        stateString = @"inactive";
    }
    else
    if(state == GONE){
        stateString = @"gone";
    }
    else{
        NSLog(@"Invalid state");
        return;
    }
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:participantId forKey:@"RoutingId"];
    [details setValue:roomId forKey:@"SessionId"];
    [details setValue:stateString forKey:@"state"];

    
    [self sendEventWithName:IrisEventOnChatMessageState body:details];
}
/**
 * This method is called when the remote stream is added to peerconnection.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 */
-(void)onAddRemoteStream:(IrisRtcMediaTrack *)track participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSString *uuid = participantId;
    if (uuid == nil)
    {
        NSLog(@"onAddRemoteStream::uuid is null");
        uuid = [[NSUUID UUID] UUIDString];
    }
    NSLog(@"RNirisSdk::onAddRemoteStream for participantId = %@",participantId);
    // Add the code to manage the local stream
    if([[RNIrisSdkStreamManager getInstance] isTrackExist:uuid]){
        NSDictionary *userInfo = @{ @"TrackId": uuid };
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"onTrackDeleted"
         object:self userInfo:userInfo];

        uuid = [uuid stringByAppendingString:@"screenshare"];
    
    }
    else
    if([[RNIrisSdkStreamManager getInstance] isTrackExist:[uuid stringByAppendingString:@"screenshare"]]){
            NSDictionary *userInfo = @{ @"TrackId": [uuid stringByAppendingString:@"screenshare"] };
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"onTrackDeleted"
             object:self userInfo:userInfo];

        }

    
    [[RNIrisSdkStreamManager getInstance] addTrack:uuid track:track];
    
    
    NSLog(@"RNirisSdk::onAddRemoteStream = %@",uuid);

    // Send the event that the stream is ready
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:uuid forKey:@"StreamId"];
    [details setValue:participantId forKey:@"RoutingId"];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnRemoteAddStream body:details];
}

/**
 * This method is called when the remote stream is removed from the peerconnection.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 */
-(void)onRemoveRemoteStream:(IrisRtcMediaTrack *)track participantId:(NSString *)participantId roomId:(NSString *)roomId traceId:(NSString *)traceId;
{
    NSString *uuid = participantId;
    RCTLogInfo(@"React::IrisRtcSdk onRemoveRemoteStream called with %@", participantId);

    // Add the code to manage the local stream
    //[[RNIrisSdkStreamManager getInstance] removeTrack:uuid];
    NSDictionary *userInfo = @{ @"TrackId": uuid };
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"onTrackDeleted"
     object:self userInfo:userInfo];
    
    // Send the event that the stream is ready
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:uuid forKey:@"StreamId"];
    [details setValue:roomId forKey:@"SessionId"];
    
    [self sendEventWithName:IrisEventOnRemoteRemoveStream body:details];
}

/**
 * Callback: This is called when audio of remote participant muted or unmuted.
 *
 * @param mute audio state mute or unmute.
 * @param participantId paritcipant id.
 * @param roomId room id.
 *
 */

- (void)onSessionParticipantAudioMuted:(BOOL)mute participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;{
    RCTLogInfo(@"React::IrisRtcSdk onSessionParticipantAudioMuted called with %@", participantId);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:participantId forKey:@"RoutingId"];
    [details setValue:roomId forKey:@"SessionId"];
    [details setValue:[NSNumber numberWithBool:mute] forKey:@"muteStatus"];
    [self sendEventWithName:IrisEventOnSessionParticipantAudioMuted body:details];
}
/**
 * Callback: This is called when video of remote participant muted or unmuted.
 *
 * @param mute video state mute or unmute.
 * @param participantId paritcipant id.
 * @param roomId room id.
 */

- (void)onSessionParticipantVideoMuted:(BOOL)mute participantId:(NSString*)participantId roomId:(NSString*)roomId traceId:(NSString *)traceId;{
    RCTLogInfo(@"React::IrisRtcSdk onSessionParticipantVideoMuted called with %@", participantId);
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:participantId forKey:@"RoutingId"];
    [details setValue:roomId forKey:@"SessionId"];
    [details setValue:[NSNumber numberWithBool:mute] forKey:@"muteStatus"];
    
    [self sendEventWithName:IrisEventOnSessionParticipantVideoMuted body:details];
}


@end
  
