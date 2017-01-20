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
