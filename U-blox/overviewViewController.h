//
//  overviewViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2015-03-31.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "olp425.h"
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
