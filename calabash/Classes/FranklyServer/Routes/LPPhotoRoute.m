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

@implementation LPPhotoRoute

-(BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {
    return [method isEqualToString:@"GET"] || [method isEqualToString:@"POST"];
}

- (NSDictionary *)JSONResponseForMethod:(NSString *)method URI:(NSString *)path data:(NSDictionary*)data {
    // Receive the photo data
    NSMutableString *encodedData = [data objectForKey:@"phto"];
    NSString *album = [data objectForKey:@"album"];
    
    // Decode the base64 encoded data
    [Base64 initialize];
    NSData * imageData = [Base64 decode:encodedData];
    
    // create image
    UIImage *image = [[UIImage alloc]initWithData:imageData];
    
    if(image == nil){
        // add code for failure to decode picture data
        return [NSDictionary dictionaryWithObjectsAndKeys:
                @"photo not added", @"results",
                @"FAILURE",@"outcome",
                @"Decode failed", @"reason",
                @"wrong size for decode; base64 string must be divisible by 4", @"details", nil];
    }
    
    // KEXIN'S CODE HERE //
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            @"image received", @"results",
            @"SUCCESS",@"outcome",
            nil];

}

@end
