//
//  RNIrisSdkStreamManager.h
//  RNIrisSdk
//
//  Created by Ganvir, Manish (Contractor) on 7/31/17.
//

#ifndef RNIrisSdkStreamManager_h
#define RNIrisSdkStreamManager_h
@import IrisRtcSdk;

// Add a delegate to inform everyone that 
@interface RNIrisSdkStreamManager : NSObject

// Call this to get access to the factory
+ (RNIrisSdkStreamManager *)getInstance;

// Call this to shutdown the factory
+ (void)destroy;

- (void)addTrack: (NSString *)uuid track:(IrisRtcMediaTrack *)track;
- (void)removeTrack: (NSString *)uuid;
- (IrisRtcMediaTrack *)getTrack: (NSString *)uuid;
- (BOOL)isTrackExist:(NSString*)streamId;

@end

#endif /* RNIrisSdkStreamManager_h */
