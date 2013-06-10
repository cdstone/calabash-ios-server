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

- (NSObject<LPHTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    LPHTTPDataResponse* drsp = [[LPHTTPDataResponse alloc] initWithData:[self addPhoto]];
    return [drsp autorelease];
}


-(NSData*)addPhoto
{
    // Receive the photo data
    NSMutableString *data = [self.data objectForKey:@"phto"];
    // strip new line characters for decoding
    for (NSInteger i = 0; i < data.length; i++) {
        if ([data characterAtIndex:i] == '\n'){
            NSRange range = NSMakeRange(i, 1);
            [data deleteCharactersInRange:range];
            }
    }
    
    // Decode the base64 encoded data
    [Base64 initialize];
    NSData * imageData = [Base64 decode:data];
    
    // create image
    UIImage *image = [[UIImage alloc]initWithData:imageData];
        
    // KEXIN'S CODE HERE
    
    return UIImagePNGRepresentation(image);
}

@end
