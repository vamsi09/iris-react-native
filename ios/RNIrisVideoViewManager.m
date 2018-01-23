//
//  RNIrisVideoViewManager.m
//  RNIrisSdk
//
//  Created by Ganvir, Manish (Contractor) on 7/31/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RNIrisVideoViewManager.h"

@implementation RNIrisVideoViewManager
{
    RNIrisVideoView * videoView;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE(IrisVideoView)

- (UIView *)view
{
    return [[RNIrisVideoView alloc] initInstance];
}

RCT_EXPORT_VIEW_PROPERTY(StreamId,                NSString);
RCT_EXPORT_VIEW_PROPERTY(onStreamError,                 RCTBubblingEventBlock);

@end
