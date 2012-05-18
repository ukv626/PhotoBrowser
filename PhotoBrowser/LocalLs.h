//
//  LocalLs.h
//  PhotoBrowser
//
//  Created by ukv on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseLs.h"

@interface LocalLs : BaseLs

- (id)initWithURL:(NSURL *)url;

- (void)startReceive;

@end
