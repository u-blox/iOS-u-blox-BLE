//
//  ChatMessage.m
//  BLEDemo
//
//  Created by Tomas Henriksson on 1/4/12.
//  Copyright (c) 2012 connectBlue. All rights reserved.
//

#import "ChatMessage.h"
#import <Foundation/NSDate.h>

@implementation ChatMessage
{
    NSDateFormatter* dateFormatter;
}

@synthesize from;
@synthesize time;
@synthesize message;

- (ChatMessage*) initWithFrom: (NSString*)fr andMessage: (NSString*) msg
{
    NSDate* date = [NSDate date];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.from = fr;
    self.message = msg;
    self.time = [dateFormatter stringFromDate: date];
    
    return self;
}

@end
