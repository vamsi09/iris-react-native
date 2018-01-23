//
//  RNIrisSdkVideoCallViewManager.m
//  RNIrisSdk
//
//  Created by Ganvir, Manish (Contractor) on 7/3/17.
//

#import "RNIrisSdkVideoCallViewManager.h"

@implementation RNIrisSdkVideoCallViewManager
{
    RNIrisSdkVideoCallView * videoCallView;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE(IrisRtcVideoCallView)

- (UIView *)view
{
    videoCallView = [[RNIrisSdkVideoCallView alloc] initInstance];
    return videoCallView;
}

RCT_EXPORT_VIEW_PROPERTY(EnablePreview,         BOOL);
RCT_EXPORT_VIEW_PROPERTY(RoomId,                NSString);
RCT_EXPORT_VIEW_PROPERTY(Config,                NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(onPreviewStarted,      RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onPreviewError,        RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onSessionCreated,      RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onSessionConnected,    RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onParticipantJoined,   RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onParticipantLeft,     RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onSessionError,        RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onSessionEnded,        RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onChatMessage,         RCTBubblingEventBlock);

RCT_EXPORT_METHOD(muteAudio)
{
    [videoCallView muteAudio];
}
RCT_EXPORT_METHOD(unmuteAudio)
{
    [videoCallView unmuteAudio];
}
RCT_EXPORT_METHOD(stopVideoPreview)
{
    [videoCallView stopPreview];
}
RCT_EXPORT_METHOD(startVideoPreview)
{
    [videoCallView startPreview];
}
RCT_EXPORT_METHOD(endSession)
{
    [videoCallView endSession];
}

RCT_EXPORT_METHOD(sendChatMessage:(NSString*)Id
                  Message:(NSString*)Message)
{
    [videoCallView sendMessage:Id message:Message];
}

@end
