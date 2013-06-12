//
//  LPPhotoCountRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import "LPMediaCountRoute.h"

@implementation LPMediaCountRoute

@synthesize library;

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"POST"];
}

- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    self.library = [[ALAssetsLibrary alloc] init];
    NSAssert(library, @"Unable to open ALAssetsLibrary");
    NSString *album = [data objectForKey:@"album"];
    __block NSString *filter = [data objectForKey:@"filter"];
    
    // set up blocks and flags for enumerating through the albums
    __block int count = -1;
    __block NSString *errorMsg;
    __block BOOL failure = false;
    __block BOOL albumWasFound = false;
    __block BOOL done = false;
    
    
    
    // runs on each album to see if it's the right one
    void (^countBlock)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
        if ([album compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
            //target album is found!
            albumWasFound = true;
            
            // set corresponding filter to the album
            if([filter isEqualToString:@"photo"]){
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
            }
            else if([filter isEqualToString:@"video"]){
                [group setAssetsFilter:[ALAssetsFilter allVideos]];
            }
            else {
                [group setAssetsFilter:[ALAssetsFilter allAssets]];
            }
            
            //then set count to number of media objects in album according to the filter
            count = group.numberOfAssets;
            return;
        }
        else if (group == nil){
            done = true;
        }
    };
    
    // runs if some failure
    void (^failBlock)(NSError *) = ^(NSError *error) {
        failure = true;
        errorMsg = [error description];
    };
    
    // the asset group of albums
    int arg1 = ALAssetsGroupAlbum;
    
    // set up backgroud method to search for album and count # of photos
    NSMethodSignature *sig = [library methodSignatureForSelector:@selector(enumerateGroupsWithTypes:usingBlock:failureBlock:)];
    NSInvocation *invoke = [NSInvocation invocationWithMethodSignature:sig];
    [invoke setTarget:library];
    [invoke setSelector:@selector(enumerateGroupsWithTypes:usingBlock:failureBlock:)];
    [invoke setArgument:&arg1 atIndex:2];
    [invoke setArgument:&countBlock atIndex:3];
    [invoke setArgument:&failBlock atIndex:4];
    [invoke performSelectorInBackground:@selector(invoke) withObject:nil];

    // wait until the background method completes
    while(!done){
        // busily
    }
    
    // couldn't find album, report the error
    if(!albumWasFound){
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"album not found", @"results",
                @"FAILURE",@"outcome",
                @"album not found", @"reason",
                nil];
    }
    // some weird failure (probably access), send it back
    if(failure){
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"count failed", @"results",
                @"FAILURE",@"outcome",
                @"error", @"reason",
                errorMsg, @"details",
                nil];
    }

    // actually got the count?  Convert it to string for JSON
    NSString * countString = [NSString stringWithFormat:@"%i", count];
    
    // return success!
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"album exists", @"results",
            @"SUCCESS",@"outcome",
            countString, @"count",
            nil];
}

@end
