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
