
## Offline playback

The Feed Media SDK now supports offline music playback. This is done
by exposing to SDK users a list of stations available for offline
playback and a new method to download the contents of those stations.
Offline stations, once downloaded, can be played using the exact
same controls as streaming music stations. Reporting of offline
music playback is handled invisibly by the SDK when Internet connectivity
is available.

### SDK

Version 4.2.0-beta of the iOS SDK has offline support. The Appledocs
for this version are at http://demo.feed.fm/sdk/docs/ios/4.2.0-beta/html/
and the best way to get the library is via CocoaPods (use 'FeedMedia'
version '4.2.0-beta') or Carthage (use 'github "feedfm/iOS-SDK"').

### Overview

In previous versions of the SDK, the `stationList` property of the
`FMAudioPlayer` held a list of all the stations that were available
for playback, and that list was populated only after the SDK was
able to contact the Feed.fm servers. The new version of the SDK
exposes two additional lists of stations to support offline music
playback: `localOfflineStationList` and `remoteOfflineStationList`.

`remoteOfflineStationList` holds a list of stations that can be
downloaded for offline playback. This list is only available when
the SDK is able to contact the Feed.fm servers, so it is populated
at the same time that `stationList` is populated, and is otherwise
an empty list. The stations in this list cannot be assigned to
`activeStation` for playback - instead they must be
passed to `downloadAndSyncStation:withDelegate:`, which will download
the contents of the station and then add an entry to
`localOfflineStationList`. The `remoteOfflineStationList` stations
may be presented to users to select music they want to download, or
apps may choose to download the contents of all of these stations.

`localOfflineStationList` holds a list of stations that have music
stored locally that can be assigned to `activeStation` for immediate
playback. This list differs from `stationList` and `remoteOfflineStationList`
in that the array is populated as soon as the `FMAudioPlayer` is
constructed, and before any attempt is made to contact Feed.fm, so
this propery can be used even when there is no Internet connection.

Playback of offline music works exactly like streaming music.
The `play`, `pause`, `skip`, e.t.c. methods function exactly the
same as with streaming music, so any music playback interface will
work just a well online as offline.

The `FMAudioPlayer` has an additional state:
`FMAudioPlayerPlaybackStateOfflineOnly`. This state indicates that
the SDK is not able to contact the Feed.fm servers, but music had
been previously stored on the device and is immediately available
for playback.

### Sample

This demo app has enough code to download an offline station and begin playback.
If the app is run while offline, it will play any music it previously downloaded.
If the app is run while online, it will contact Feed.fm to make sure it
has a local copy of the first offline station available to it.

First, we initialize the library by passing our credentials to the SDK.
We'll use some demo credentials that point to a demo app:

```
 [FMAudioPlayer setClientToken:@"offline" secret:@"offline"];
```

That causes the SDK to contact Feed.fm and retrieve the list of available
stations and offline stations.

We'll know when the app has reached Feed.fm via the `whenAvailable:notAvailable`
callback:

```
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
        // ...
    }];
```

When the `whenAvailable:` function is called, the `remoteOfflineStationList`
has been populated with a list of stations. We take the first station and
ask the player to download its contents. This AppDelegate class implements 
FMStationDownloadDelegate and is passed as the delegate to
`downloadAndSyncStation:withDelegate` to receive notice while files are downloaded.

Downloading events are sent to the `stationDownloadProgress:pendingCount:failedCount:totalCount
method:

```
- (void)stationDownloadProgress:(FMStation *)station pendingCount:(int)pendingCount failedCount:(int)failedCount totalCount:(int)totalCount {
    NSLog(@"Station download in progress.. %d of %d files remaining to download", pendingCount, totalCount);
}
```

When all the files in the station have been downloaded, a final call is made to
`stationDownloadComplete:`, where we tune the player to the offline station and
begin music playback:

```
- (void)stationDownloadComplete:(FMStation *)station {
    FMAudioPlayer *player = [FMAudioPlayer sharedPlayer];
    player.activeStation = station;
    [player play];

}
```

When you first run the app, it will spend some time pulling down the songs in 
that first station and then begin playback. Future runs will happen more quickly,
as the client will only download updates to the station it has downloaded.

If the app starts up and is unable to contact feed.fm, it calls the `notAvailable:`
callback:

```
    [[FMAudioPlayer sharedPlayer] whenAvailable:^{
       ...

    } notAvailable:^{
        // couldn't contact feed.fm - we must be offline!
        FMAudioPlayer *player = [FMAudioPlayer sharedPlayer];

        // play the first station we've downloaded
        if (player.localOfflineStationList.count > 0) {
            player.activeStation = player.localOfflineStationList[0];
            [player play];
        }
    }];
``` 

In this case, we serach for the station we previously downloaded and
immediately begin playback in that station.

### Reporting 

Feed.fm records play counts for licensing purposes. This information is
recorded on the device while offline. When Internet connectivity
becomes available, the SDK will automatically send the reporting events
to feed.fm and remove them from the local device.

### Expiration

Offline content has varying expiration dates. Every time the SDK is
initialized, it asks the server to extend the expiration date on downloaded
content. If the server cannot be reached, and the expiration date is
hit, then the files will automatically be deleted off the device and the
offline station will no longer be available.

### Target Minutes

There is a variant of the downloading function called
`downloadAndSyncStation:forTargetMinutes:withDelegate:`. The `targetMinutes`
argument is used to ask the server to limit the amount of music transferred
during this request. If the app only plans to play up to 10 minutes of
music while offline, this number can be passed to the server to ensure the
app doesn't download the full contents of a potentially large offline station
all at once. The SDK might not download any music if it already has enough.
The SDK might download 10 minutes of music, even if it already has music,
to swap out old songs the user has heard with newer songs.

