//
//  LPPhotoRoute.h
//  calabash
//
//  Created by Ian Lukens on 06/06/13.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import "LPHTTPResponse.h"
#import "LPGenericAsyncRoute.h"

@interface LPPhotoRoute : LPGenericAsyncRoute

- (NSData*)addPhoto;
@end
