//
//  RNIrisVideoView.h
//  RNIrisSdk
//
//  Created by Ganvir, Manish (Contractor) on 7/31/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#ifndef RNIrisVideoView_h
#define RNIrisVideoView_h
#if __has_include("RCTBridgeModule.h")
#import "RCTEventEmitter.h"
#else
#import <React/RCTEventEmitter.h>
#endif
#import "RCTViewManager.h"
#import <React/RCTComponent.h>

@import IrisRtcSdk;

@interface RNIrisVideoView : UIView <IrisRtcRendererDelegate>

/**-----------------------------------------------------------------------------
 * @name Initialization of the view
 * -----------------------------------------------------------------------------
 */
/** This method is called to init the view
 */
- (instancetype)initInstance NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSString *StreamId;
@property (nonatomic, copy) RCTBubblingEventBlock onStreamError;

@end


#endif /* RNIrisVideoView_h */
