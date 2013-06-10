//
//  LPPhotoRoute.m
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import "LPPhotoRoute.h"
#import "LPHTTPDataResponse.h"
#import <QuartzCore/QuartzCore.h>
#import "Base64.h"
#import "AddPhotoToAlbum.h"

@implementation LPPhotoRoute

@synthesize library;

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"GET"] || [method isEqualToString:@"POST"];
}

- (UIImage*) decodePhoto:(NSMutableString*)data{
    if (data != nil){
    // Decode the base64 encoded data
    [Base64 initialize];
    NSData * imageData = [Base64 decode:data];
    
    // create image
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    return image;
    }
    else{
        return nil;
    }
}

- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    // Receive the photo data
    NSMutableString *encodedData = [data objectForKey:@"phto"];
    NSString *album = [data objectForKey:@"album"];
    UIImage *image = [self decodePhoto:encodedData];
    
    if(encodedData != nil && image == nil){
            return [NSDictionary dictionaryWithObjectsAndKeys:
                @"photo not added", @"results",
                @"FAILURE",@"outcome",
                @"Decode failed", @"reason",
                @"wrong size for decode; base64 string must be divisible by 4", @"details", nil];
    }
    // TODO: Error handling for album section
    if(album != nil){
        self.library = [[ALAssetsLibrary alloc] init];
        // if have an image add it to that album
        if(image != nil){
            [self.library saveImage:image toAlbum:album withCompletionBlock:^(NSError *error) {
                if (error!=nil) {
                    NSLog(@"Big error: %@", [error description]);
                }
            }];
        }
        // otherwise, just create an album
        else{
            [library addAssetsGroupAlbumWithName:album
                                 resultBlock:^(ALAssetsGroup *group) {
                                     NSLog(@"added album:%@", album);
                                 }
         
                                failureBlock:^(NSError *error) {
                                    NSLog(@"error adding album");
                                }
            ];
        }

    }
    else {
        // save to default photos
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"photo added", @"results",
            @"SUCCESS",@"outcome",
            nil];
}

@end
