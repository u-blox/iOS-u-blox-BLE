//
//  servicesViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2015-03-24.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "olp425.h"
#import "servicesDetailViewController.h"

@interface servicesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
   
}

@property (strong, nonatomic) IBOutlet UILabel *navbarLabel;
@property (strong, nonatomic) IBOutlet UIButton *navbarButton;

@property (strong, nonatomic) IBOutlet UITableView *tableview;

- (IBAction) selectDevice: (id) UIButton;

@end
