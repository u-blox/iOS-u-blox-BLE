//
//  performanceTestViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2017-05-19.
//  Copyright © 2017 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ublox.h"

@interface performanceTestViewController : UIViewController
{
    BOOL isSending;
    long sendByteCount;
    long receiveByteCount;
    
    NSDate *testStartTime;
}

@property (weak, nonatomic) IBOutlet UILabel *maxPacketLabel;
@property (weak, nonatomic) IBOutlet UITextField *packetSizeTextfield;

@property (weak, nonatomic) IBOutlet UILabel *bytesTxLabel;
@property (weak, nonatomic) IBOutlet UILabel *performanceTxLabel;
@property (weak, nonatomic) IBOutlet UILabel *bytesRxLabel;
@property (weak, nonatomic) IBOutlet UILabel *performanceRxLabel;
@property (weak, nonatomic) IBOutlet UILabel *errorsRxLabel;
@property (weak, nonatomic) IBOutlet UISwitch *creditsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rxSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *txSwitch;


@property (weak, nonatomic) IBOutlet UIButton *startStopButton;

- (IBAction)startStopTest:(UIButton *)sender;
- (IBAction)closeKeyboardTap:(UITapGestureRecognizer *)sender;

- (IBAction)creditsSwitched:(UISwitch *)sender;

- (IBAction)rxSwitched:(id)sender;
- (IBAction)txSwitched:(id)sender;


@end
