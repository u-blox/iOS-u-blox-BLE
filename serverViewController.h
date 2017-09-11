//
//  serverViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2017-06-27.
//  Copyright © 2017 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <CoreFoundation/CoreFoundation.h>
#import "ublox.h"

@interface serverViewController : UIViewController <NSStreamDelegate>
{
    id thisClass;
    
    BOOL serverOn;
    
    NSString *testDevicename;
    NSDate *testStartTime;
    BOOL testCredits;
    long testPackagesize;
    int testTXBytes;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    CFSocketNativeHandle nativeSocketHandle;
}

@property (nonatomic) BOOL isTesting;

@property (nonatomic) CFSocketNativeHandle native;

@property (weak, nonatomic) IBOutlet UITextView *logginTextview;
@property (weak, nonatomic) IBOutlet UITextField *portTextfield;

@property (weak, nonatomic) IBOutlet UIButton *startstopButton;

- (IBAction)startstopServer:(id)sender;


@end
