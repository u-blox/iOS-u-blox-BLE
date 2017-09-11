//
//  performanceTestViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2017-05-19.
//  Copyright © 2017 U-blox. All rights reserved.
//

#import "performanceTestViewController.h"

@interface performanceTestViewController ()

@end

@implementation performanceTestViewController
@synthesize maxPacketLabel, packetSizeTextfield, performanceTxLabel, performanceRxLabel, bytesRxLabel, bytesTxLabel, errorsRxLabel, startStopButton, creditsSwitch, rxSwitch, txSwitch;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    isSending = NO;
    sendByteCount = 0;
    receiveByteCount = 0;
    
    [NSTimer scheduledTimerWithTimeInterval:0.25
                                     target:self
                                   selector:@selector(updateTestInfo)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    CBPeripheral *currentPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    [startStopButton setEnabled:NO];
    
    if(currentPeripheral != nil)
    {
        long maxValWithout = [currentPeripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse];
        
        maxPacketLabel.text = [NSString stringWithFormat:@"(Max: %ld)", maxValWithout];
        
        packetSizeTextfield.text = [NSString stringWithFormat:@"%ld", maxValWithout];
        
        for(int i = 0; i < currentPeripheral.services.count;i++)
        {
            CBService *checkService = [currentPeripheral.services objectAtIndex:i];
            
            if([[checkService.UUID data] isEqualToData:[[NSData alloc] initWithBytes:serialPortServiceUuid length:16]])
            {
                [startStopButton setEnabled:YES];
            }
        }
    } else {
        maxPacketLabel.text = @"NOT CONNECTED";
    }
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            [sp open];
        }
    }
}

- (void)updateTestInfo
{
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            if(sp.isTestingRX)
            {
                bytesRxLabel.text = [NSString stringWithFormat:@"RX Bytes: %ld", sp.testRxByteCount];
                
                NSDate *dateNow = [NSDate date];
                NSTimeInterval testRXSeconds = [dateNow timeIntervalSinceDate:sp.testRXStartTime];
                
                int RXbytesPerSecond = ((sp.testRxByteCount/1024)*8)/testRXSeconds;
                
                performanceRxLabel.text = [NSString stringWithFormat:@"RX Rate: %d kb/s", RXbytesPerSecond];
                
                errorsRxLabel.text = [NSString stringWithFormat:@"RX Errors: %ld", sp.testRxErrorCount];
                
            }
            if(sp.isTestingTX)
            {
                bytesTxLabel.text = [NSString stringWithFormat:@"TX Bytes: %ld", sp.testTxByteCount];
                
                NSDate *dateNow = [NSDate date];
                NSTimeInterval testTXSeconds = [dateNow timeIntervalSinceDate:sp.testTXStartTime];
                
                int TXbytesPerSecond = ((sp.testTxByteCount/1024)*8)/testTXSeconds;
                
                performanceTxLabel.text = [NSString stringWithFormat:@"TX Rate: %d kb/s", TXbytesPerSecond];
            }
            
            
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

/*
- (IBAction)startStopTest:(UIButton *)sender {
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            if(sp.isTesting)
            {
                [sp stopTest];
                [startStopButton setTitle:@"Start" forState:UIControlStateNormal];
                [packetSizeTextfield setEnabled:YES];
                [creditsSwitch setEnabled:YES];
            } else {
                [sp startTest];
                [startStopButton setTitle:@"Stop" forState:UIControlStateNormal];
                [packetSizeTextfield setEnabled:NO];
                [creditsSwitch setEnabled:NO];
                testStartTime = [NSDate date];
            }
            
            
            
        }
    }
}
*/

- (IBAction)closeKeyboardTap:(UITapGestureRecognizer *)sender {
    [self.view endEditing:YES];
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            [sp setPackageMax:[packetSizeTextfield.text longLongValue]];
        }
    }
}

- (IBAction)creditsSwitched:(UISwitch *)sender {
    
    [creditsSwitch setEnabled:NO];
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            [sp close];
            sp.useCredits = sender.isOn;
            [self performSelector:@selector(reconnectSerial) withObject:nil afterDelay:2];
        }
    }
}

- (IBAction)rxSwitched:(id)sender {
    if(rxSwitch.isOn == NO && txSwitch.isOn == NO)
    {
        [packetSizeTextfield setEnabled:YES];
        [creditsSwitch setEnabled:YES];
    } else {
        [packetSizeTextfield setEnabled:NO];
        [creditsSwitch setEnabled:NO];
    }
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            if(sp.isTestingRX)
            {
                [sp stopRXTest];
            } else {
                [sp startRXTest];
            }
        }
    }

}

- (IBAction)txSwitched:(id)sender {
    if(rxSwitch.isOn == NO && txSwitch.isOn == NO)
    {
        [packetSizeTextfield setEnabled:YES];
        [creditsSwitch setEnabled:YES];
    } else {
        [packetSizeTextfield setEnabled:NO];
        [creditsSwitch setEnabled:NO];
    }
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            if(sp.isTestingTX)
            {
                [sp stopTXTest];
            } else {
                [sp startTXTest];
            }
        }
    }
}

-(void)reconnectSerial
{
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            [sp open];
        }
    }
    
    [creditsSwitch setEnabled:YES];
}

- (void) sendtestData
{
    if(isSending == NO)
    {
        return;
    }
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];

    NSString *textMessage = @"";
    
    long maxValWithout = [thisPeripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse];
    
    for(SerialPort* sp in [[ublox sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            maxValWithout = [sp getPackageMax];
        }
    }
    
    for (int i=0; i < maxValWithout; i++) {
        textMessage = [NSString stringWithFormat:@"%@x",textMessage];
    }
    
    
    
    [[ublox sharedInstance] serialSendMessageToPeripheralUUID:thisPeripheral.identifier.UUIDString message:textMessage];
}

@end
