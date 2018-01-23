//
//  RNIrisVideoView.m
//  RNIrisSdk
//
//  Created by Ganvir, Manish (Contractor) on 7/31/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RNIrisVideoView.h"
#import "RNIrisSdkStreamManager.h"
@import AVFoundation;

@implementation RNIrisVideoView
{
    IrisRtcRenderer *renderer;
    CGSize videoSize;
    NSString *internalStreamId;
}
@synthesize StreamId;

- (instancetype)initInstance
{
    RCTLogInfo(@"React::IrisRtcSdk RNIrisVideoView initInstance !!!");
    
    if ((self = [super init])) {
        
        // Initialize variables
        renderer = [[IrisRtcRenderer alloc] initWithView:self.bounds delegate:self];
        
        // Add observer
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onTrackDeleted:)
                                                     name:@"onTrackDeleted"
                                                   object:nil];
        
        // Add observer
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onAllTracksDeleted:)
                                                     name:@"onAllTracksDeleted"
                                                   object:nil];
        
        // Insert the local renderer inside the present view
        [self insertSubview:renderer.videoView atIndex:0];
        internalStreamId = nil;
    }
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

/**
 * This method is called to set the streamid to the view.
 *
 * @param track pointer to the IrisRtcMediaTrack containing remote track.
 */
- (void)setStreamId:(NSString *)Id
{
    RCTLogInfo(@"React::IrisRtcSdk Id %@ for object Id = %@", Id,self);
    RCTLogInfo(@"React::IrisRtcSdk setStreamId %@ ", StreamId);
    if (StreamId == Id )
    {
        RCTLogInfo(@"React::IrisRtcSdk already set");
        return;
    }
    
    if (!Id || [Id isEqualToString:@""])
    {
        RCTLogInfo(@"React::IrisRtcSdk Default init");
        return;
    }
    StreamId = Id;
    
    if (StreamId != nil)
    {
        IrisRtcMediaTrack *track = [[RNIrisSdkStreamManager getInstance] getTrack:StreamId];
        [track removeRenderer:renderer];
        [renderer.videoView removeFromSuperview];
        renderer = nil;
        // Insert the local renderer inside the present view
        renderer = [[IrisRtcRenderer alloc] initWithView:self.bounds delegate:self];
        [self insertSubview:renderer.videoView atIndex:0];
    }
    
    
    
    // Check whether a stream id exists
    IrisRtcMediaTrack *track = [[RNIrisSdkStreamManager getInstance] getTrack:Id];
    if (track == nil)
    {
        RCTLogInfo(@"React::IrisRtcSdk StreamId not found %@ !!!", Id);
        if (self.onStreamError != nil)
        {
            self.onStreamError(@{@"event": @"onError",
                                  @"code":[NSNumber numberWithInteger:-1],
                                  @"error":@"StreamId not found ",
                                  @"target": self});
        }
        return;
    }
    
    // Add the renderer
    [track addRenderer:renderer delegate:self];
}

-(void)adjustView
{
    if (StreamId)
    {
        CGSize defaultAspectRatio = CGSizeMake(16, 9);
        CGSize localAspectRatio = CGSizeEqualToSize(videoSize, CGSizeZero) ?
        defaultAspectRatio : videoSize;
        
        renderer.frame = AVMakeRectWithAspectRatioInsideRect(localAspectRatio,
                                                             self.bounds);
        RCTLogInfo(@"React::IrisRtcSdk Set the frame as %.2lf %.2lf %.2lf %.2lf", renderer.frame.origin.x, renderer.frame.origin.y, renderer.frame.size.height, renderer.frame.size.width);

    }
}


- (void)layoutSubviews
{
    if (StreamId)
    {
        RCTLogInfo(@"React::IrisRtcSdk _ %@ _ layoutSubviews %.2lf %.2lf %.2lf %.2lf", StreamId, self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.height, self.bounds.size.width);
    }
    else
    {
        RCTLogInfo(@"React::IrisRtcSdk _  _ layoutSubviews %.2lf %.2lf %.2lf %.2lf", self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.height, self.bounds.size.width);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self adjustView];
    });
    
}
/** This method is called when there is change in size coordinates of remote or local video
 *
 * @param renderer Pointer to the renderer object.
 * @param size size coordinates of view.
 */

-(void)onVideoSizeChange:(IrisRtcRenderer *)renderer size:(CGSize)size
{
    videoSize = size;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self adjustView];
    });

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
/**
 * This method is called to when track is deleted
 *
 * @param uuid - track id.
 */
- (void)onTrackDeleted:(NSNotification *) notify
{
    RCTLogInfo(@"React::IrisRtcSdk onTrackDeleted with name %@ and userInfo %@", notify.name, notify.userInfo.description);

    if ([StreamId isEqualToString:notify.userInfo[@"TrackId"]])
    {
        IrisRtcMediaTrack *track = [[RNIrisSdkStreamManager getInstance] getTrack:StreamId];
        [track removeRenderer:renderer];
        [renderer.videoView removeFromSuperview];
        renderer = nil;
        
        [[RNIrisSdkStreamManager getInstance] removeTrack:StreamId];
        RCTLogInfo(@"React::IrisRtcSdk deleting track with StreamId %@ ", StreamId);
        StreamId = nil;
    }
}

/**
 * This method is called to when track is deleted
 *
 * @param uuid - track id.
 */
- (void)onAllTracksDeleted:(NSNotification *) notify
{
    RCTLogInfo(@"React::IrisRtcSdk onAllTracksDeleted with name %@ ", notify.name);
    
    if (StreamId != nil)
    {
        IrisRtcMediaTrack *track = [[RNIrisSdkStreamManager getInstance] getTrack:StreamId];
        [track removeRenderer:renderer];
        [renderer.videoView removeFromSuperview];
        renderer = nil;
        
        [[RNIrisSdkStreamManager getInstance] removeTrack:StreamId];
        RCTLogInfo(@"React::IrisRtcSdk deleting track with StreamId %@ ", StreamId);
        StreamId = nil;
    }
}
@end

