//
//  AppDelegate.m
//  iOS-Offline-Demo
//
//  Created by Eric Lambrecht on 8/17/18.
//  Copyright © 2018 Feed Media. All rights reserved.
//

#import "AppDelegate.h"
#import <FeedMedia/FeedMedia.h>

@interface AppDelegate () <FMStationDownloadDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // initialize feed.fm and pull in list of remote offline stations
    [FMAudioPlayer setClientToken:@"offline" secret:@"offline"];
    
    [[FMAudioPlayer sharedPlayer] whenAvailable:^{
        // streaming stations are available here, as is the list of downloadable stations
        FMAudioPlayer *player = [FMAudioPlayer sharedPlayer];
        
        // list out stations available for download
        for (FMStation *station in player.remoteOfflineStationList) {
            NSLog(@"offline station: %@", station.name);
        }
        
        // download/update the first available offline station
        FMStation *station = player.remoteOfflineStationList[0];
        [player downloadAndSyncStation:station withDelegate:self];
        
    } notAvailable:^{
        // couldn't contact feed.fm - we must be offline!
        FMAudioPlayer *player = [FMAudioPlayer sharedPlayer];
        
        // play the first station we've downloaded
        if (player.localOfflineStationList.count > 0) {
            player.activeStation = player.localOfflineStationList[0];
            [player play];
        }
    }];
    
    return YES;
}


- (void)stationDownloadComplete:(FMStation *)station {
    FMAudioPlayer *player = [FMAudioPlayer sharedPlayer];

    player.activeStation = station;
    [player play];
}

- (void)stationDownloadProgress:(FMStation *)station pendingCount:(int)pendingCount failedCount:(int)failedCount totalCount:(int)totalCount {
    NSLog(@"Station download in progress.. %d of %d files remaining to download", pendingCount, totalCount);
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
