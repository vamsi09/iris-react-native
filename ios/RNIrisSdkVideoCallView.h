//
//  RNIrisSdkVideoCallView.h
//  RNIrisSdk
//
//  Created by Ganvir, Manish (Contractor) on 7/3/17.
//

#ifndef RNIrisSdkVideoCallView_h
#define RNIrisSdkVideoCallView_h
#if __has_include("RCTBridgeModule.h")
#import "RCTEventEmitter.h"
#else
#import <React/RCTEventEmitter.h>
#endif
#import "RCTViewManager.h"
#import <React/RCTComponent.h>

@import IrisRtcSdk;

@class RCTEventDispatcher;

@interface RNIrisSdkVideoCallView : UIView <IrisRtcStreamDelegate, IrisRtcRendererDelegate, IrisRtcSessionDelegate>

/**-----------------------------------------------------------------------------
 * @name Initialization of the view
 * -----------------------------------------------------------------------------
 */
/** This method is called to init the view
 */
- (instancetype)initInstance NS_DESIGNATED_INITIALIZER;

/**-----------------------------------------------------------------------------
 * @name Management of the preview
 * -----------------------------------------------------------------------------
 */
/** This method is called to start a local preview for the chosen camera.
 */
-(void)startPreview;

/** This method is called to stop a local preview for the chosen camera.
 *
 */
-(void)stopPreview;

/** This method is called to start a mute audio.
 */
-(void)muteAudio;

/** This method is called to unmute audio.
 */
-(void)unmuteAudio;

/** This method is called to end session.
 */
-(void)endSession;

/** This method is called to send chat message.
 */
-(void)sendMessage:(NSString *)Id message:(NSString *)chatMessage;

@property (nonatomic, assign) BOOL EnablePreview;
@property (nonatomic, assign) NSString *RoomId;
@property (nonatomic, assign) NSDictionary *Config;
@property (nonatomic, copy) RCTBubblingEventBlock onPreviewStarted;
@property (nonatomic, copy) RCTBubblingEventBlock onPreviewError;
@property (nonatomic, copy) RCTBubblingEventBlock onSessionCreated;
@property (nonatomic, copy) RCTBubblingEventBlock onSessionConnected;
@property (nonatomic, copy) RCTBubblingEventBlock onParticipantJoined;
@property (nonatomic, copy) RCTBubblingEventBlock onParticipantLeft;
@property (nonatomic, copy) RCTBubblingEventBlock onSessionError;
@property (nonatomic, copy) RCTBubblingEventBlock onSessionEnded;
@property (nonatomic, copy) RCTBubblingEventBlock onChatMessage;

@end

#endif /* RNIrisSdkVideoCallView_h */
