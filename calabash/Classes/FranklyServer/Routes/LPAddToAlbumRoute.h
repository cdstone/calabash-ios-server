//
//  LPAddToAlbumRoute.h
//  calabash
//
//  Created by Karl Krukow on 29/01/12.
//  Copyright (c) 2013 LessPainful. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LPGenericAsyncRoute.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface LPAddToAlbumRoute : LPGenericAsyncRoute

@property (strong, atomic) ALAssetsLibrary* library;

@end
