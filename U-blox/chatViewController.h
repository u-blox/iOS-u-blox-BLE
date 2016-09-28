//
//  chatViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2015-04-13.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "chatTableViewCell.h"
#import "olp425.h"

@interface chatViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    
}

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *messageViewDistance;

@property (strong, nonatomic) IBOutlet UILabel *navbarLabel;
@property (strong, nonatomic) IBOutlet UIButton *navbarButton;

@property (strong, nonatomic) IBOutlet UITableView *tableview;

@property (strong, nonatomic) IBOutlet UIView *messageView;
@property (strong, nonatomic) IBOutlet UITextField *messageTextfield;
@property (strong, nonatomic) IBOutlet UIButton *sendButton;



- (IBAction) sendMessage: (id) UIButton;

@end
