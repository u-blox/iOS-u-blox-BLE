//
//  ChatMessage.h
//  BLEDemo
//
//  Created by Tomas Henriksson on 1/4/12.
//  Copyright (c) 2012 connectBlue. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ChatMessage : NSObject

@property (nonatomic, strong) NSString *from;
@property (nonatomic, strong) NSString *time;
@property (nonatomic, strong) NSString *message;

- (ChatMessage*) initWithFrom: (NSString*)from andMessage: (NSString*) msg;

@end
