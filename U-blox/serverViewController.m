/*
 * Copyright (C) u-blox 
 * 
 * u-blox reserves all rights in this deliverable (documentation, software, etc.,
 * hereafter “Deliverable”). 
 * 
 * u-blox grants you the right to use, copy, modify and distribute the
 * Deliverable provided hereunder for any purpose without fee.
 * 
 * THIS DELIVERABLE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY. IN PARTICULAR, NEITHER THE AUTHOR NOR U-BLOX MAKES ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY OF THIS
 * DELIVERABLE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 * 
 * In case you provide us a feedback or make a contribution in the form of a
 * further development of the Deliverable (“Contribution”), u-blox will have the
 * same rights as granted to you, namely to use, copy, modify and distribute the
 * Contribution provided to us for any purpose without fee.
 */

#import "serverViewController.h"

@interface serverViewController ()

@end

void * refToSelf;

@implementation serverViewController
@synthesize native, logginTextview, startstopButton, portTextfield, isTesting;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    serverOn = NO;
    
    logginTextview.layer.borderWidth = 1;
    logginTextview.layer.borderColor = UIColor.blackColor.CGColor;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralListChange:)
                                                 name:@"peripheralListChange"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralUpdate:)
                                                 name:@"peripheralUpdate"
                                               object:nil];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(updateTestInfo)
                                   userInfo:nil
                                    repeats:YES];
    
    refToSelf = (__bridge void *)(self);
    
    
    
    //void CFStreamCreatePairWithSocketToHost(CFAllocatorRef alloc, CFStringRef host, UInt32 port, CFReadStreamRef *readStream, CFWriteStreamRef *writeStream);
    
    //CFSocketNativeHandle sock = *(CFSocketNativeHandle *) data;
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            [sp close];
        }
    }
    
    
    [super viewWillDisappear:animated];
}

- (void)logging:(NSString*)logtext
{
    logginTextview.text = [NSString stringWithFormat:@"%@\n%@", logginTextview.text, logtext];
    
    NSRange bottom = NSMakeRange(logginTextview.text.length -1, 1);
    [logginTextview scrollRangeToVisible:bottom];
}

- (IBAction)startstopServer:(id)sender {
    if(serverOn)
    {
        serverOn = NO;
        [self logging:@"Server stop"];
        [startstopButton setTitle:@"Start" forState:UIControlStateNormal];
    } else {
        serverOn = YES;
        [self logging:@"Server start"];
        [startstopButton setTitle:@"Stop" forState:UIControlStateNormal];

        const CFSocketContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
        CFSocketRef myipv4cfsock = CFSocketCreate(
                                                  kCFAllocatorDefault,
                                                  PF_INET,
                                                  SOCK_STREAM,
                                                  IPPROTO_TCP,
                                                  kCFSocketAcceptCallBack, serverAcceptCallback, &context); //handleConnect
        
        CFSocketRef myipv6cfsock = CFSocketCreate(
                                                  kCFAllocatorDefault,
                                                  PF_INET6,
                                                  SOCK_STREAM,
                                                  IPPROTO_TCP,
                                                  kCFSocketAcceptCallBack, serverAcceptCallback, NULL); //handleConnect
        
        
        struct sockaddr_in sin;
        
        memset(&sin, 0, sizeof(sin));
        sin.sin_len = sizeof(sin);
        sin.sin_family = AF_INET; /* Address family */
        sin.sin_port = htons([portTextfield.text intValue]); /* Or a specific port */
        sin.sin_addr.s_addr= INADDR_ANY;
        
        CFDataRef sincfd = CFDataCreate(
                                        kCFAllocatorDefault,
                                        (UInt8 *)&sin,
                                        sizeof(sin));
        
        CFSocketSetAddress(myipv4cfsock, sincfd);
        CFRelease(sincfd);
        
        struct sockaddr_in6 sin6;
        
        memset(&sin6, 0, sizeof(sin6));
        sin6.sin6_len = sizeof(sin6);
        sin6.sin6_family = AF_INET6; /* Address family */
        sin6.sin6_port = htons(55123); /* Or a specific port */
        sin6.sin6_addr = in6addr_any;
        
        CFDataRef sin6cfd = CFDataCreate(
                                         kCFAllocatorDefault,
                                         (UInt8 *)&sin6,
                                         sizeof(sin6));
        
        CFSocketSetAddress(myipv6cfsock, sin6cfd);
        CFRelease(sin6cfd);
        
        
        CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(
                                                                      kCFAllocatorDefault,
                                                                      myipv4cfsock,
                                                                      0);
        
        CFRunLoopAddSource(
                           CFRunLoopGetCurrent(),
                           socketsource,
                           kCFRunLoopDefaultMode);
        
        CFRunLoopSourceRef socketsource6 = CFSocketCreateRunLoopSource(
                                                                       kCFAllocatorDefault,
                                                                       myipv6cfsock,
                                                                       0);
        
        CFRunLoopAddSource(
                           CFRunLoopGetCurrent(),
                           socketsource6,
                           kCFRunLoopDefaultMode);
        

        
        // DEVICENAME;CREDITS;PACKAGESIZE;BYTECOUNT
        //[self readIn:@"OLP425-ECC3;1;0;10000"];
    }
}

- (void)updateTestInfo
{
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            if(sp.isTestingTX || sp.isTestingRX)
            {
                [self logging:[NSString stringWithFormat:@"TX: %ld", sp.testTxByteCount]];
                [self logging:[NSString stringWithFormat:@"RX: %ld", sp.testRxByteCount]];
            } else {
                if(self.isTesting)
                {
                    self.isTesting = NO;
                    [self logging:@"RESULT:"];
                    
                    NSTimeInterval testSeconds = [sp.testRXEndTime timeIntervalSinceDate:sp.testRXStartTime];
                    [self logging:[NSString stringWithFormat:@"%f seconds", testSeconds]];
                    [self logging:[NSString stringWithFormat:@"%ld TX Bytes", sp.testTxByteCount]];
                    [self logging:[NSString stringWithFormat:@"%ld RX Bytes", sp.testRxByteCount]];
                    
                    [self writeOut:[NSString stringWithFormat:@"%f;%ld;%ld", testSeconds, sp.testTxByteCount, sp.testRxByteCount]];
                    
                }
            }
        }
    }
}

- (void) peripheralListChange:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"peripheralListChange"])
    {
        for(int i = 0;i < [[ublox sharedInstance] discoveredPeripherals].count;i++)
        {
            NSMutableDictionary *thisPeripheralDict = [[[ublox sharedInstance] discoveredPeripherals] objectAtIndex:i];
            
            CBPeripheral *thisPeripheral = [thisPeripheralDict objectForKey:@"peripheral"];
            
            if([[thisPeripheral name] isEqualToString:testDevicename])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self logging:@"Found device"];
                });
                
                [[ublox sharedInstance] scan:NO services:nil];
                if([[ublox sharedInstance] getCurrentPeripheral].state == CBPeripheralStateConnected)
                {
                    [self logging:@"Connected"];
                    [self performSelector:@selector(doTest) withObject:nil afterDelay:2];
                } else {
                    [[ublox sharedInstance] connectPeripheral:thisPeripheral];
                }
                
            }
        }
    }
    
}

- (void) peripheralUpdate:(NSNotification *) notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if([[ublox sharedInstance] getCurrentPeripheral].state == CBPeripheralStateConnected)
        {
            [self logging:@"Connected"];
            [self performSelector:@selector(doTest) withObject:nil afterDelay:2];
        }
    });
}

- (void)doTest
{
    [self logging:@"Start test"];
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            if(testPackagesize > 0)
            {
                [sp setPackageMax:testPackagesize];
            }
            sp.useCredits = testCredits;
            sp.testLimitTXcount = testTXBytes;
            
            [sp open];
            [sp startRXTest];
            [sp startTXTest];
            isTesting = YES;
        }
    }

}

- (void) handleCallback
{
    NSLog(@"HANDLE CALLBACK");
    
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, native, &readStream, &writeStream);
    
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
}

void serverAcceptCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    NSLog(@"serverAcceptCallback");
    // We can only process "connection accepted" calls here
    if ( type != kCFSocketAcceptCallBack )
    {
        NSLog(@"kCFSocketAcceptCallBack return");
        return;
    }
    
    serverViewController *pvc = (__bridge serverViewController *)info;
    pvc.native = *(CFSocketNativeHandle*)data;
    
    [pvc handleCallback];
    
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event {
    NSLog(@"Stream triggered.");
    
    switch(event) {
            
            
        case NSStreamEventHasSpaceAvailable: {
            if(stream == outputStream) {
                NSLog(@"outputStream is ready.");
            }
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            if(stream == inputStream) {
                NSLog(@"inputStream is ready.");
                
                uint8_t buf[1024];

                long len = 0;
                
                len = [inputStream read:buf maxLength:1024];
                
                if(len > 0) {
                    NSMutableData* data=[[NSMutableData alloc] initWithLength:0];
                    
                    [data appendBytes: (const void *)buf length:len];
                    
                    NSString *s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                    
                    [self readIn:s];
                }
            }
            break;
        }
        default: {
            NSLog(@"Stream is sending an Event: %lu", event);
            
            break;
        }
    }
}

- (void)readIn:(NSString *)s {
    NSLog(@"Reading in the following:");
    NSLog(@"%@", s);
    
    if(self.isTesting)
    {
        return;
    }
    
    NSArray *stringArray = [s componentsSeparatedByString:@";"];
    // DEVICENAME;CREDITS;PACKAGESIZE;BYTECOUNT
    
    testDevicename = [stringArray objectAtIndex:0];
    if([[stringArray objectAtIndex:1] isEqualToString:@"0"])
    {
        testCredits = NO;
    } else {
        testCredits = YES;
    }
    
    NSString *packageSizeString = [stringArray objectAtIndex:2];
    testPackagesize = [packageSizeString longLongValue];
    testTXBytes = [[stringArray objectAtIndex:3] intValue];
    
    [[ublox sharedInstance] scan:YES services:nil];
}

- (void)writeOut:(NSString *)s {
    uint8_t *buf = (uint8_t *)[s UTF8String];
    
    [outputStream write:buf maxLength:strlen((char *)buf)];
    
    NSLog(@"Writing out the following:");
    NSLog(@"%@", s);
}

@end
