
//
//  RNIrisSdkStreamManager.m
//  RNIrisSdk
//
//  Created by Ganvir, Manish (Contractor) on 7/31/17.
//

#import <Foundation/Foundation.h>
#import <React/RCTLog.h>

#import "RNIrisSdkStreamManager.h"

/**
 * The stream manager keeps tracks of renderers and uuids
 *
 */
@implementation RNIrisSdkStreamManager
{
    NSMutableDictionary *streamInfo;
}

// Shared factory for all the classes
static RNIrisSdkStreamManager *FactoryInstance = nil;

+ (RNIrisSdkStreamManager *)getInstance{
    
    if (FactoryInstance == nil)
    {
        FactoryInstance = [[RNIrisSdkStreamManager alloc] init];
    }
    return FactoryInstance;
}

+ (void)destroy
{
    if (FactoryInstance != nil)
    {
        FactoryInstance = nil;
    }
}

- (instancetype)init
{
    if ((self = [super init])) {
        
        // Initialize variables
        streamInfo = [[NSMutableDictionary alloc] init];
        RCTLogInfo(@"React::IrisRtcSdkStreamManager instance created !!!");
    }
    
    return self;
}

/** This method is called to add a track to the list
 *
 * @param uuid uuid to keep track.
 * @param mediaTrack Media track that is associated with the camera instance.
 */
- (void)addTrack: (NSString *)uuid track:(IrisRtcMediaTrack *)track
{
    // Check if the streaminfo is created
    if (streamInfo)
    {
        RCTLogInfo(@"React::IrisRtcSdkStreamManager adding stream with uuid %@ ", uuid);
        [streamInfo setValue:track forKey:uuid];
    }
}

/** This method is called to remove a track from the list
 *
 * @param uuid uuid to keep track.
 */
- (void)removeTrack: (NSString *)uuid
{
    // Check if the streaminfo is created
    if (streamInfo)
    {
        RCTLogInfo(@"React::IrisRtcSdkStreamManager remove stream with uuid %@ ", uuid);
        [streamInfo removeObjectForKey:uuid];
    }
}

/** This method is called to check if track already exist
 *
 * @param uuid uuid to keep track.
 */
- (BOOL)isTrackExist:(NSString*)streamId
{
    // Check if the streaminfo is created
    
        RCTLogInfo(@"isTrackExist ");
        if([streamInfo objectForKey:streamId] != nil){
            return true;
        }
        return false;
    
}

/** This method is called to get a track from the list
 *
 * @param uuid uuid to keep track.
 */
- (IrisRtcMediaTrack *)getTrack: (NSString *)uuid
{
    // Check if the streaminfo is created
    if (streamInfo)
    {
        RCTLogInfo(@"React::IrisRtcSdkStreamManager get track with uuid %@ ", uuid);
        return [streamInfo objectForKey:uuid];
    }
    
    return nil;
}
@end
