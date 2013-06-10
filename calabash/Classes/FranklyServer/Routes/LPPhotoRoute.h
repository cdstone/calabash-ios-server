//
//  LPPhotoRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2012 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPRoute.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface LPPhotoRoute : NSObject<LPRoute>

@property (strong, atomic) ALAssetsLibrary* library;

@end
