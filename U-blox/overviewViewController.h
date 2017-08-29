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
#import <SceneKit/SceneKit.h>

@interface overviewViewController : UIViewController <UIAlertViewDelegate>
{
    SCNNode *myObject;
    
    int gyroXval;
    int gyroYval;
    int gyroZval;
    int accXval;
    int accYval;
    int accZval;
    
    int tempTimeVal;
}

@property (strong, nonatomic) IBOutlet UILabel *navbarLabel;
@property (strong, nonatomic) IBOutlet UIButton *navbarButton;

@property (strong, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (strong, nonatomic) IBOutlet UILabel *rssiLabel;
@property (strong, nonatomic) IBOutlet UILabel *batteryLabel;
@property (strong, nonatomic) IBOutlet UILabel *accelerometerLabel;

@property (strong, nonatomic) IBOutlet UIView *accelerometerXview;
@property (strong, nonatomic) IBOutlet UIView *accelerometerYview;
@property (strong, nonatomic) IBOutlet UIView *accelerometerZview;

@property (strong, nonatomic) IBOutlet UISwitch *ledRedSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *ledGreenSwitch;

@property (weak, nonatomic) IBOutlet SCNView *modelScene;


- (IBAction) toggleRedLedSwitch: (id) UISwitch;
- (IBAction) toggleGreenLedSwitch: (id) UISwitch;

- (IBAction) selectDevice: (id) UIButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *modelHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *modelTop;
@property (weak, nonatomic) IBOutlet UIButton *modelButton;


- (IBAction)tapModel:(id)sender;
- (IBAction)pressModel:(id)sender;
- (IBAction)modelButtonSwitch:(id)sender;

-(void)calculateAngle;

@end
