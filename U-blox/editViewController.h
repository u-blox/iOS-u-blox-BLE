//
//  editViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2015-04-10.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "olp425.h"

@interface editViewController : UIViewController <UITextFieldDelegate>
{
}

@property (strong, nonatomic) NSString *serviceUUID;
@property (strong, nonatomic) NSString *characteristicUUID;

@property (strong, nonatomic) IBOutlet UILabel *serviceLabel;
@property (strong, nonatomic) IBOutlet UILabel *characteristicLabel;
@property (strong, nonatomic) IBOutlet UILabel *valueLabel;

@property (strong, nonatomic) IBOutlet UITextField *textTextfield;
@property (strong, nonatomic) IBOutlet UITextField *hexTextfield;
@property (strong, nonatomic) IBOutlet UITextField *intTextfield;

@end
