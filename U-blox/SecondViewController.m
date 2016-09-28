//
//  SecondViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2015-02-23.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import "SecondViewController.h"
#import "olp425.h"

@interface SecondViewController ()

@end

@implementation SecondViewController
@synthesize name;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self listServices];
}

-(void)viewDidAppear:(BOOL)animated {
    //[connectedPeripheral discoverServices:arr];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralService:)
                                                 name:@"peripheralService"
                                               object:nil];

}

- (void) peripheralService:(NSNotification *) notification
{
    [self listServices];
}

- (void) listServices
{
    CBPeripheral *discPeripheral;
    
    NSMutableDictionary *peripheralDict = [[NSMutableDictionary alloc] init];
    
    for(int i = 0; (i < [[olp425 sharedInstance] discoveredPeripherals].count); i++)
    {
        discPeripheral = [[[[olp425 sharedInstance] discoveredPeripherals] objectAtIndex:i] objectForKey:@"peripheral"];
        
        if(discPeripheral.state == CBPeripheralStateConnected)
        {
            for(int i = 0; (i < discPeripheral.services.count); i++)
            {
                CBService *thisService = discPeripheral.services[i];
                NSLog(@"FOUND A SERVICE %@", [[olp425 sharedInstance] CBUUIDString:thisService.UUID]);
                
                for(int j = 0; j < thisService.characteristics.count;j++)
                {
                    CBCharacteristic *thisCharacteristic = [thisService.characteristics objectAtIndex:j];
                    
                    NSLog(@"CHAR %@ ", thisCharacteristic.description);
                }
            }
            
        }
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
