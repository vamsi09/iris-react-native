//
//  RNIrisSdkVideoCallView.m
//  RNIrisSdk
//
//  Created by Ganvir, Manish (Contractor) on 7/3/17.
//

#import <Foundation/Foundation.h>
#import "RNIrisSdkVideoCallView.h"
@import AVFoundation;

@implementation RNIrisSdkVideoCallView
{
    IrisRtcRenderer     *_localRenderer;      // Local renderer to display local preview
    IrisRtcStream       *_localStream;        // Local stream
    IrisRtcMediaTrack   *_localTrack;         // Local media track

    NSMutableDictionary *_RemoteParticipants; // Remote participants
    IrisRtcSession      *_videoSession;       // Video Session
    NSString            *_sessionType;        // Session type
    NSString            *_preferredRoutingId; // Preferred routing id
    CGSize               _localVideoSize;
    BOOL                 _RemoteStreamReceived;
    BOOL                 _localVideoMuted;
    BOOL *               _enablePreviewSet;
    UILabel * label;
}

- (instancetype)initInstance
{
    RCTLogInfo(@"React::IrisRtcSdk RNIrisSdkVideoCallView initInstance !!!");

    if ((self = [super init])) {
        
        // Initialize variables
        _localStream = nil;
        _localTrack = nil;
        _RoomId = nil;
        _Config = nil;
        _videoSession = nil;
        _RemoteParticipants = [[NSMutableDictionary alloc] init];
        _preferredRoutingId = nil;
        _RemoteStreamReceived = false;
        _localVideoMuted = false;
        _enablePreviewSet = nil;
    }
    
    return self;
}

- (void)startPreview
{
    RCTLogInfo(@"React::IrisRtcSdk startPreview !!!");

    if (_localStream == nil) {
        
        // Initialize variables
        _localRenderer = [[IrisRtcRenderer alloc] initWithView:self.bounds delegate:self];
        
        // Insert the local renderer inside the present view
        [self insertSubview:_localRenderer.videoView atIndex:1];

        // Set the bounds
        _localRenderer.frame = self.frame;
        RCTLogInfo(@"React::IrisRtcSdk My bounds in startpreview %.2lf %.2lf %.2lf %.2lf", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.height, self.bounds.size.width);

        
        // Do we need transform to enable mirror view?
        _localRenderer.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        
        // Create the stream
        _localStream = [[IrisRtcStream alloc] initWithDelegate:self error:nil];
        
        // Start the local preview
        [_localStream startPreview];
        _localVideoMuted = false;
        
        RCTLogInfo(@"React::IrisRtcSdk Preview started !!!");

    }
    else if (_videoSession != nil && _localVideoMuted)
    {
        [_localStream startPreview];
        [_localRenderer.videoView setHidden:false];

        _localVideoMuted = false;
    }
    else
    {
        RCTLogInfo(@"React::IrisRtcSdk Preview has already started !!!");
    }
}
- (void)stopPreview
{
    if (_localStream == nil) {
        RCTLogInfo(@"React::IrisRtcSdk Preview hasnt started !!!");
        return;
    }
    
    RCTLogInfo(@"React::IrisRtcSdk stopPreview !!!");


    if ((_videoSession != nil && !_localVideoMuted))
    {
        [_localRenderer.videoView setHidden:true];
        [_localStream stopPreview];
        _localVideoMuted = true;
    }
    else
    {
        // Stop the preview
        [_localTrack removeRenderer:_localRenderer];
        _localTrack = nil;
        [_localRenderer.videoView removeFromSuperview];
        _localRenderer = nil;
        [_localStream stopPreview];
        _localStream = nil;

        _localVideoMuted = true;
    }
    
}

/** This method is called to start a mute audio.
 */
-(void)muteAudio
{
    RCTLogInfo(@"React::IrisRtcSdk muteAudio");

    if (_localStream)
    {
        [_localStream mute];
    }
}

/** This method is called to unmute audio.
 */
-(void)unmuteAudio
{
    RCTLogInfo(@"React::IrisRtcSdk unmuteAudio");
    if (_localStream)
    {
        [_localStream unmute];
    }
}

/** This method is called to end session.
 */
-(void)endSession
{
    RCTLogInfo(@"React::IrisRtcSdk endSession");
    if (_videoSession)
    {
        [_videoSession close];
        _preferredRoutingId = nil;
        _videoSession = nil;
        for(NSString *key in _RemoteParticipants) {
            NSDictionary *participant = [_RemoteParticipants objectForKey:key];
            IrisRtcRenderer *renderer = participant[@"renderer"];
            IrisRtcMediaTrack *track = participant[@"track"];
            [track removeRenderer:renderer];
            [renderer.videoView removeFromSuperview];
            renderer = nil;
        }
        [_RemoteParticipants removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            _localRenderer.frame = self.frame;
        });
        // Delete all renderers?
    }

}

/** This method is called to send chat message.
 */
-(void)sendMessage:(NSString *)Id message:(NSString *)chatMessage
{
    RCTLogInfo(@"React::IrisRtcSdk sendMessage with id %@ and message %@", Id, chatMessage);
    if (_videoSession)
    {
        IrisChatMessage * msg = [[IrisChatMessage alloc] initWithMessage:chatMessage messageId:Id];
         [_videoSession sendChatMessage:msg error:nil];
    }
}

- (void)tryAndStartCall
{
    // check if we have received all the parameters
    if (_Config && _RoomId && _enablePreviewSet)
    {
        if (_videoSession == nil)
        {
            // Check if we have all the properties in the config
            if (![_Config objectForKey:@"SessionType"])
            {
                RCTLogInfo(@"React::IrisRtcSdk SessionType is missing !!!");
                if (self.onSessionError != nil)
                {
                    self.onSessionError(@{@"event": @"onSessionError",
                                          @"error": @"SessionType is missing",
                                          @"code":  [NSNumber numberWithInt:-201],
                                          @"target": self});
                }
                return;
            }
            
            // Check the session type
            _sessionType = _Config[@"SessionType"];
            if (![_sessionType isEqualToString:@"incoming"] && ![_sessionType isEqualToString:@"outgoing"])
            {
                RCTLogInfo(@"React::IrisRtcSdk SessionType is wrong !!!");
                if (self.onSessionError != nil)
                {
                    self.onSessionError(@{@"event": @"onSessionError",
                                          @"error": @"SessionType is wrong",
                                          @"code":  [NSNumber numberWithInt:-202],
                                          @"target": self});
                }
                return;
            }
            
            // Incoming call
            if ([_sessionType isEqualToString:@"incoming"])
            {
                if  (![_Config objectForKey:@"roomToken"] || ![_Config objectForKey:@"roomTokenExpiryTime"] || ![_Config objectForKey:@"rtcServer"])
                {
                    RCTLogInfo(@"React::IrisRtcSdk Incoming call, roomToken or roomTokenExpiryTime is missing !!!");
                    if (self.onSessionError != nil)
                    {
                        self.onSessionError(@{@"event": @"onSessionError",
                                              @"error": @"Incoming call, roomToken or roomTokenExpiryTime is missing",
                                              @"code":  [NSNumber numberWithInt:-203],
                                              @"target": self});
                    }
                    return;
                }
                
                // Let's accept an incoming call
                _videoSession = [[IrisRtcSession alloc] init];
                [_videoSession setIsVideoBridgeEnable:YES];
                IrisRtcSessionConfig *sessionConfig = [[IrisRtcSessionConfig alloc]init];

                 [_videoSession joinWithSessionId:_RoomId roomToken:_Config[@"roomToken"] roomTokenExpiryTime:[_Config[@"roomTokenExpiryTime"] integerValue] stream:_localStream  rtcServer:_Config[@"rtcServer"] sessionConfig:sessionConfig delegate:self error:nil];
                 
                if  ([_Config objectForKey:@"name"])
                {
                    IrisRtcUserProfile *profile = [[IrisRtcUserProfile alloc] init];
                    [profile setName:[_Config objectForKey:@"name"]];
                    //[_videoSession setUserProfile:profile];
                }
                
            }
            
            // Outgoing call
            if ([_sessionType isEqualToString:@"outgoing"])
            {
                if  (![_Config objectForKey:@"notificationPayload"])
                {
                    RCTLogInfo(@"React::IrisRtcSdk Outgoing call, notificationPayload is missing !!!");
                    if (self.onSessionError != nil)
                    {
                        self.onSessionError(@{@"event": @"onSessionError",
                                              @"error": @"Outgoing call, notificationPayload is missing",
                                              @"code":  [NSNumber numberWithInt:-204],
                                              @"target": self});
                    }
                    return;
                }
                _videoSession = [[IrisRtcSession alloc] init];
                [_videoSession setIsVideoBridgeEnable:YES];
                IrisRtcSessionConfig *sessionConfig = [[IrisRtcSessionConfig alloc]init];

                [_videoSession createWithRoomId:_RoomId notificationData:_Config[@"notificationPayload"] stream:_localStream sessionConfig:sessionConfig delegate:self error:nil];
                
                if  ([_Config objectForKey:@"name"])
                {
                    IrisRtcUserProfile *profile = [[IrisRtcUserProfile alloc] init];
                    [profile setName:[_Config objectForKey:@"name"]];
                    //[_videoSession setUserProfile:profile];
                }
            }
        }
    }
}
- (void)setEnablePreview:(BOOL)enable
{
    RCTLogInfo(@"React::IrisRtcSdk setEnablePreview %d!!!", enable);

    _EnablePreview = enable;
    _enablePreviewSet = &enable;
    if (enable)
    {
        [self startPreview];
    }
    else
    {
        [self stopPreview];
    }
    
    [self tryAndStartCall];
}

- (void)setRoomId:(NSString *)RoomId
{
    RCTLogInfo(@"React::IrisRtcSdk setRoomId %@!!!", RoomId);
    _RoomId = RoomId;
    
    [self tryAndStartCall];
    
}
- (void)setConfig:(NSDictionary *)Config
{
    RCTLogInfo(@"React::IrisRtcSdk SetConfig %@!!!", [Config description]);
    _Config = Config;
    
    [self tryAndStartCall];
    
}

- (void)layoutSubviews
{
    RCTLogInfo(@"React::IrisRtcSdk layoutSubviews!!!");
    RCTLogInfo(@"React::IrisRtcSdk My bounds in layoutSubviews %.2lf %.2lf %.2lf %.2lf", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.height, self.bounds.size.width);

    [super layoutSubviews];
    
    [self adjustView];
    // Insert the local renderer inside the present view
   // [self insertSubview:_localRenderer.videoView atIndex:0];
    
    // Set the bounds
    //_localRenderer.frame = self.bounds;
    //_localRenderer.frame = [[UIScreen mainScreen] bounds];//CGRectMake(0, 0, 360, 640);

}


- (void)insertReactSubview:(UIView *)view atIndex:(NSInteger)atIndex
{
    RCTLogInfo(@"React::IrisRtcSdk insertReactSubview");

    //[self insertSubview:view atIndex:atIndex + 1];
    [super insertReactSubview:view atIndex:atIndex];
    return;
}

- (void)removeReactSubview:(UIView *)subview
{
    RCTLogInfo(@"React::IrisRtcSdk removeReactSubview");

    //[subview removeFromSuperview];
    [super removeReactSubview:subview];
    return;
}

- (void)removeFromSuperview
{
    RCTLogInfo(@"React::IrisRtcSdk removeFromSuperview");

    [super removeFromSuperview];
}



/** This method is called when the local preview is available
 *
 * @param stream Pointer to the stream object.
 * @param mediaTrack Media track that is associated with the camera instance.
 */
-(void)onLocalStream:(IrisRtcStream *)stream mediaTrack:(IrisRtcMediaTrack *)mediaTrack
{
    RCTLogInfo(@"React::IrisRtcSdk onLocalStream");

    _localTrack = mediaTrack;
    [_localTrack addRenderer:_localRenderer delegate:self];

    if (self.onPreviewStarted != nil)
    {
        self.onPreviewStarted(@{@"event": @"onPreviewStarted", @"target": self});
    }

}

/** This method is called when there in an error during camera capture processs
 *
 * @param stream Pointer to the stream object.
 * @param error Error code and basic description.
 * @param info Additional details for debugging.
 */
-(void)onStreamError:(IrisRtcStream *)stream error:(NSError*)error withAdditionalInfo:(NSDictionary *)info
{
    RCTLogInfo(@"React::IrisRtcSdk Error in preview %@", [error localizedDescription]);
    if (self.onPreviewError != nil)
    {
        self.onPreviewError(@{@"event": @"onPreviewError",
                              @"code":[NSNumber numberWithInteger:error.code],
                              @"error":[info description],
                              @"target": self});
    }

}
-(void)onVideoSizeChange:(IrisRtcRenderer *)renderer size:(CGSize)size
{
    RCTLogInfo(@"React::IrisRtcSdk onVideoSizeChange size %.2fx%.2f", size.width, size.height);
    if (renderer.videoView != _localRenderer.videoView)
    {
        _RemoteStreamReceived = true;
        
        for(NSString *key in _RemoteParticipants) {
            NSMutableDictionary *participant = [_RemoteParticipants objectForKey:key];
            if (participant[@"renderer"] == renderer)
            {
                participant[@"size"] = [NSValue valueWithCGSize:size];
            }
        }
    }
    else
    {
        _localVideoSize = size;
    }
    
    // Check if the remote stream received
    [self adjustView];
}

- (void)updateVideoViewLayout {
    /*static CGFloat const kLocalViewPadding = 20;

    CGSize defaultAspectRatio = CGSizeMake(16, 9);
    CGSize localAspectRatio = CGSizeEqualToSize(_localVideoSize, CGSizeZero) ?
    defaultAspectRatio : _localVideoSize;
    CGSize remoteAspectRatio = CGSizeEqualToSize(_remoteVideoSize, CGSizeZero) ?
    defaultAspectRatio : _remoteVideoSize;
    CGRect bounds = [[UIScreen mainScreen] bounds];
    // This is needed as the resolution has to be divisible by 16 for perfect decoding
    // so in order to fit in the screen, the following code is required
    float aspectRatioOfBounds = (bounds.size.width/bounds.size.height);
    float aspectRatioOfRemote = (remoteAspectRatio.width/remoteAspectRatio.height);
    NSLog(@" updateVideoViewLayout %f %f %f %f", remoteAspectRatio.width, remoteAspectRatio.height, bounds.size.width, bounds.size.height);
    NSLog(@" updateVideoViewLayout %f %f %f %f", aspectRatioOfBounds, aspectRatioOfRemote,(aspectRatioOfBounds * 1.05), (aspectRatioOfBounds * 0.95));
    if((aspectRatioOfRemote <= (aspectRatioOfBounds * 1.05)) && (aspectRatioOfRemote >= (aspectRatioOfBounds * 0.95)))
    {
        _remoteRenderer.frame = bounds;
    }
    else
    {
        CGRect remoteVideoFrame = AVMakeRectWithAspectRatioInsideRect(remoteAspectRatio,
                                            bounds);
        _remoteRenderer.frame = remoteVideoFrame;
        
    }
    
    CGRect localVideoFrame = AVMakeRectWithAspectRatioInsideRect(localAspectRatio,
                                        bounds);
    if(_RemoteStreamReceived)
    {
            localVideoFrame.size.width = localVideoFrame.size.width / 4;
            localVideoFrame.size.height = localVideoFrame.size.height / 4;
            localVideoFrame.origin.x = CGRectGetMaxX(bounds)
            - localVideoFrame.size.width - kLocalViewPadding;
            localVideoFrame.origin.y = CGRectGetMaxY(bounds)
            - localVideoFrame.size.height - kLocalViewPadding;
    }
    else
    {
            localVideoFrame = bounds;
            
    }
    _localRenderer.frame = localVideoFrame;*/
    
}


-(void)setMainView: (IrisRtcRenderer *) renderer remoteVideoSize:(CGSize)_remoteVideoSize
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize defaultAspectRatio = CGSizeMake(16, 9);
        CGSize remoteAspectRatio = CGSizeEqualToSize(_remoteVideoSize, CGSizeZero) ?
        defaultAspectRatio : _remoteVideoSize;
        CGRect bounds = self.frame;
        // This is needed as the resolution has to be divisible by 16 for perfect decoding
        // so in order to fit in the screen, the following code is required
        float aspectRatioOfBounds = (bounds.size.width/bounds.size.height);
        float aspectRatioOfRemote = (remoteAspectRatio.width/remoteAspectRatio.height);
        NSLog(@" setMainView %f %f %f %f", remoteAspectRatio.width, remoteAspectRatio.height, bounds.size.width, bounds.size.height);
        NSLog(@" setMainView %f %f %f %f", aspectRatioOfBounds, aspectRatioOfRemote,(aspectRatioOfBounds * 1.05), (aspectRatioOfBounds * 0.95));
        if((aspectRatioOfRemote <= (aspectRatioOfBounds * 1.05)) && (aspectRatioOfRemote >= (aspectRatioOfBounds * 0.95)))
        {
            renderer.frame = bounds;
        }
        else
        {
            CGRect remoteVideoFrame = AVMakeRectWithAspectRatioInsideRect(remoteAspectRatio,
                                                                          bounds);
            renderer.frame = remoteVideoFrame;
            
        }

        [self sendSubviewToBack:renderer.videoView];

    });
}
-(void)adjustView
{
    int iCount =0;
    int thumbnailCount =0;
    CGRect bounds = self.frame;
    CGFloat hGapBetweenVideos = bounds.size.width/20;
    CGFloat vGapBetweenVideos = bounds.size.height/20;
    CGFloat ThumbnailWidth = bounds.size.width/6;
    CGFloat ThumbnailHeight = bounds.size.height/6;
    
    // If there is more than one participant, shrink the local preview
    if ([_RemoteParticipants count] > 0)
    {
        CGFloat x = (bounds.size.width - ThumbnailWidth - hGapBetweenVideos);
        CGFloat y = (bounds.size.height - ThumbnailHeight - vGapBetweenVideos);
        
        _localRenderer.frame = CGRectMake(x, y, ThumbnailWidth, ThumbnailWidth);
        [self bringSubviewToFront:_localRenderer.videoView];

        thumbnailCount ++;
    }
    else
    {
        //_localRenderer.frame = self.frame;
        //[self bringSubviewToFront:_localRenderer.videoView];
        //[self setMainView:_localRenderer remoteVideoSize:_localVideoSize];

    }
    
    CGSize defaultAspectRatio = CGSizeMake(16, 9);
    CGSize localAspectRatio = CGSizeEqualToSize(_localVideoSize, CGSizeZero) ?
    defaultAspectRatio : _localVideoSize;
    
    CGRect localVideoFrame = AVMakeRectWithAspectRatioInsideRect(localAspectRatio,
                                                                 bounds);
    if ([_RemoteParticipants count] > 0)
    {
        localVideoFrame.size.width = localVideoFrame.size.width / 6;
        localVideoFrame.size.height = localVideoFrame.size.height / 6;
        localVideoFrame.origin.x = CGRectGetMaxX(bounds)
        - localVideoFrame.size.width - hGapBetweenVideos;
        localVideoFrame.origin.y = CGRectGetMaxY(bounds)
        - localVideoFrame.size.height - vGapBetweenVideos;
        
        [self bringSubviewToFront:_localRenderer.videoView];
        
        thumbnailCount ++;
    }
    
    _localRenderer.frame = localVideoFrame;
    
    
    for(NSString *key in _RemoteParticipants) {
        NSDictionary *participant = [_RemoteParticipants objectForKey:key];
        iCount++;
        
        if (_preferredRoutingId != nil)
        {
            if ([key isEqualToString:_preferredRoutingId])
            {
                // This is the main view
                [self setMainView:participant[@"renderer"] remoteVideoSize:[participant[@"size"] CGSizeValue]];
                RCTLogInfo(@"React::IrisRtcSdk Setting the mainview to participant %@", key);

                continue;
            }
        }
        else if (iCount == 1)
        {
            // Let's make this participant as the main view for now
            [self setMainView:participant[@"renderer"] remoteVideoSize:[participant[@"size"] CGSizeValue]];
            _preferredRoutingId = key;
            RCTLogInfo(@"React::IrisRtcSdk Setting the mainview to participant %@", key);

            continue;
        }
        
        IrisRtcRenderer *renderer = participant[@"renderer"];
        CGFloat x =  (bounds.size.width - ( thumbnailCount * (ThumbnailWidth + hGapBetweenVideos) ) );
        CGFloat y = (bounds.size.height - ( (ThumbnailHeight + vGapBetweenVideos) ) );
        
        // Check if we have crossed the screen
        if (x < 0)
        {
            RCTLogInfo(@"React::IrisRtcSdk Too many thumbnails !!!  thumbnailCount %d", thumbnailCount);
            return;
        }

        CGSize defaultAspectRatio = CGSizeMake(16, 9);
        CGSize remoteVideoSize = [participant[@"size"] CGSizeValue];
        CGSize remoteAspectRatio = CGSizeEqualToSize(remoteVideoSize, CGSizeZero) ?
        defaultAspectRatio : remoteVideoSize;

        CGRect remoteVideoFrame = AVMakeRectWithAspectRatioInsideRect(remoteAspectRatio,
                                                                      bounds);
        remoteVideoFrame.size.width = remoteVideoFrame.size.width / 6;
        remoteVideoFrame.size.height = remoteVideoFrame.size.height / 6;
        remoteVideoFrame.origin.x = CGRectGetMaxX(bounds)
         - ( thumbnailCount * (ThumbnailWidth + hGapBetweenVideos) );
        remoteVideoFrame.origin.y = CGRectGetMaxY(bounds)
        - remoteVideoFrame.size.height - vGapBetweenVideos;
        
        renderer.frame = remoteVideoFrame;
        thumbnailCount ++;
        RCTLogInfo(@"React::IrisRtcSdk Setting renderer to frame (%lf, %lf, %lf, %lf) for %@", remoteVideoFrame.origin.x, remoteVideoFrame.origin.y, remoteVideoFrame.size.width, remoteVideoFrame.size.height, key);


        [self bringSubviewToFront:renderer.videoView];
    }
}

/**
 * This method is called when the remote stream is added to peerconnection.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 */
-(void)onAddRemoteStream:(IrisRtcMediaTrack *)track routingId:(NSString *)routingid
{
    RCTLogInfo(@"React::IrisRtcSdk onAddRemoteStream %@", routingid);
    
    if (routingid == nil)
        return;
    /*if ([_RemoteParticipants count] > 1)
    {
        RCTLogInfo(@"React::IrisRtcSdk Multiple participants arent supported yet ");
        return;
    }*/
    
    // This login should be run on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *participant = [[NSMutableDictionary alloc] init];
        IrisRtcRenderer* renderer = [[IrisRtcRenderer alloc] initWithView:self.bounds delegate:self];
        [self insertSubview:renderer.videoView atIndex:0];
        [track addRenderer:renderer delegate:self];
        [participant setValue:track forKey:@"track"];
        [participant setValue:renderer forKey:@"renderer"];
        [_RemoteParticipants setValue:participant forKey:routingid];
               
        // Adjust the view as now we have a new renderer
        [self adjustView];
    });
}

/**
 * This method is called when the remote stream is removed from the peerconnection.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 */
-(void)onRemoveRemoteStream:(IrisRtcMediaTrack *)track routingId:(NSString *)routingid
{
    RCTLogInfo(@"React::IrisRtcSdk onRemoveRemoteStream %@", routingid);

    dispatch_async(dispatch_get_main_queue(), ^{

        NSDictionary *participant = _RemoteParticipants[routingid];
        IrisRtcRenderer *remoteRenderer = (IrisRtcRenderer *)participant[@"renderer"];
        
        [track removeRenderer:remoteRenderer];
        [remoteRenderer.videoView removeFromSuperview];
        remoteRenderer = nil;
        [_RemoteParticipants removeObjectForKey:routingid];
        
        [self adjustView];
    });

}

/**
 * This method is called when the remote stream is added to peerconnection.
 *
 * @param Chat message string
 * @param Participant Id sending the chat message
 * @param Room Identifier for the allocated  chat room for the participants
 */
-(void)onSessionParticipantMessage:(IrisChatMessage*)message participantId:(NSString*)participantId roomId:(NSString*)roomId
{
    RCTLogInfo(@"React::IrisRtcSdk onChatMessage message %@ %@", [message messageId], [message data]);

    if (self.onChatMessage != nil)
    {
        self.onChatMessage(@{@"event": @"onChatMessage",
                             @"childNodeId": message.childNodeId,
                             @"rootNodeId": message.rootNodeId,
                             @"timeReceived": message.timeReceived,
                             @"messageId": message.messageId,
                             @"data": message.data,
                             @"participantId":  participantId,
                             @"roomId":  roomId,
                             @"target": self});
    }
}

/**
 * Callback:This method is called when the room is created successfully.
 *
 * @param sessionId room id.
 */
-(void)onSessionCreated:(NSString *)sessionId
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionCreated sessionId %@", sessionId);
    if (self.onSessionCreated != nil)
    {
        self.onSessionCreated(@{@"event": @"onSessionCreated",
                              @"sessionId":sessionId,
                              @"target": self});
    }
}

/**
 * Callback: This is called when the room is joined successfully from reciever.
 *
 * @param sessionId room id.
 */
-(void)onSessionJoined:(NSString *)sessionId
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionJoined sessionId %@", sessionId);
    if (self.onSessionCreated != nil)
    {
        self.onSessionCreated(@{@"event": @"onSessionJoined",
                                @"sessionId":sessionId,
                                @"target": self});
    }
}

/**
 * Callback: This is called when the room is joined successfully from reciever.
 *
 * @param sessionId room id.
 */
-(void)onSessionParticipantConnected:(NSString *)sessionId
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionParticipantConnected sessionId %@", sessionId);

}


/**
 * Callback: This is called at the sender side when the remote participant joins the room.
 *
 * @param sessionId room id.
 * @param participantName remote participant name.
 */
-(void)onSessionParticipantJoined:(NSString *)sessionId participantName:(NSString*)name
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionParticipantJoined sessionId %@ name %@", sessionId, name);
    if (name != nil)
    {
        if (self.onParticipantJoined != nil)
        {
            self.onParticipantJoined(@{@"event": @"onParticipantJoined",
                                    @"sessionId":sessionId,
                                    @"name": name,
                                    @"target": self});
        }
    }
    else
    {
        if (self.onParticipantJoined != nil)
        {
            self.onParticipantJoined(@{@"event": @"onParticipantJoined",
                                       @"sessionId":sessionId,
                                       @"name": @"",
                                       @"target": self});
        }
    }

}

/**
 * Callback: This is called when the Ice connection state that is,session is connected.
 *
 * @param sessionId room id.
 */
-(void)onSessionConnected:(NSString *)sessionId
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionConnected sessionId %@", sessionId);

    if (self.onSessionConnected != nil)
    {
        self.onSessionConnected(@{@"event": @"onParticipantJoined",
                                   @"sessionId":sessionId,
                                   @"target": self});
    }
}


/**
 * Callback: This is called at the sender side when the remote participant joins the room.
 *
 * @param sessionId room id.
 * @param routingId target routingId.
 * @param message   Text from message.
 */
- (void)onSessionParticipantMessage:(NSString *)sessionId  routingId:(NSString*)routingId message:(NSData*)message
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionParticipantMessage sessionId %@ routingId %@ message %@", sessionId, routingId, message );

}

/**
 * Callback: This is called when the session ends.
 *
 * @param sessionId room id.
 */
- (void)onSessionEnded:(NSString*)sessionId
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionEnded sessionId %@", sessionId);
    if (self.onSessionEnded != nil)
    {
        self.onSessionEnded(@{@"event": @"onSessionEnded",
                                  @"sessionId":sessionId,
                                  @"target": self});
    }
}

/**
 * Callback: This is called when the participant leaves the room.
 *
 * @param sessionId room id.
 * @param participantName  name of the participant who left the room .
 */
- (void)onSessionParticipantLeft:(NSString*)sessionId participantName:(NSString*)name
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionParticipantLeft sessionId %@ name %@", sessionId, name);

    if (name != nil)
    {
        if (self.onParticipantLeft != nil)
        {
            self.onParticipantLeft(@{@"event": @"onParticipantLeft",
                                     @"sessionId":sessionId,
                                     @"name": name,
                                     @"target": self});
        }
    }
    else
    {
        if (self.onParticipantLeft != nil)
        {
            self.onParticipantLeft(@{@"event": @"onParticipantLeft",
                                       @"sessionId":sessionId,
                                       @"name": @"",
                                       @"target": self});
        }

    }
}

/**
 * Callback: This is called when the participant is not reachable.
 *
 * @param sessionId room id.
 * @param participantName  name of the participant who left the room .
 */
- (void)onSessionParticipantNotReachable:(NSString*)sessionId participantName:(NSString*)name
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionParticipantNotReachable sessionId %@ name %@", sessionId, name);

}
/**
 * Callback: This is called when the participant profile is changed.
 *
 * @param rotingId participant routingid.
 * @param userprofile  IriRtcuserProfile object containing participant's name and image url .
 */
- (void)onSessionParticipantProfile:(NSString*)routingId userProfile:(IrisRtcUserProfile*)userprofile
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionParticipantProfile routingId %@ name %@", routingId, [userprofile name]);

}
/**
 * Callback: This is called when dominant speaker is changed in multiple stream.
 *
 * @param rotingId dominant speaker routingid.
 *
 */
- (void)onSessionDominantSpeakerChanged:(NSString*)routingId
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionDominantSpeakerChanged called with %@", routingId);
    dispatch_async(dispatch_get_main_queue(), ^{

        NSArray * splitString = [routingId componentsSeparatedByString:@"/"];
        if (splitString)
        {
            NSDictionary *participant = [_RemoteParticipants objectForKey:splitString[0]];
            if (participant)
            {
                _preferredRoutingId = splitString[0];
                [self adjustView];
            }
        }
    });
    
}

/**
 * Callback: This is called when there is error while the session is active.
 *
 * @param error The basic error code details.
 * @param additionalInfo  Additional error details including description.
 */
- (void)onSessionError:(NSError*)error withAdditionalInfo:(NSDictionary *)info
{
    RCTLogInfo(@"React::IrisRtcSdk onSessionError error %@ info %@", [error description], [info description]);
    if (self.onSessionError != nil)
    {
        self.onSessionError(@{@"event": @"onSessionError",
                              @"error": [error description],
                              @"code":  [NSNumber numberWithInteger:[error code]],
                              @"target": self});
    }

}
/**
 * Callback: This is called when there is any message is to be convey to the app.
 *
 * @param log message to the app.
 */
- (void)onLogAnalytics:(NSString*)log
{
    NSLog(@"React::IrisRtcSdk onLogAnalytics log %@", log);
    RCTLogInfo(@"React::IrisRtcSdk onLogAnalytics log %@", log);

}
/**
 * This method is called as an  acknowledggment of  chat message sent to participant.
 *
 *
 * @param ChatAck message string
 */
-(void)onChatMessageSuccess:(IrisChatMessage*)message
{
    RCTLogInfo(@"React::IrisRtcSdk onChatMessageSuccess message %@", [message data]);

}

/**
 * This method is called as when  chat message is not sent to participant.
 *
 *
 * @param messageId messageid of chat message
 * @param info additional info about error.
 */
-(void)onChatMessageError:(NSString*)messageId withAdditionalInfo:(NSDictionary *)info
{
    RCTLogInfo(@"React::IrisRtcSdk onChatMessageError messageId %@ withAdditionalInfo %@", messageId, [info description]);

}

@end

