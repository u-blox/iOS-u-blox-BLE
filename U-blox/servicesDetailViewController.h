//
//  servicesDetailViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2015-04-10.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "olp425.h"
#import "servicesDetailTableViewCell.h"
#import "editViewController.h"

@interface servicesDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    
}

@property (strong, nonatomic) NSString *serviceUUID;
@property (strong, nonatomic) IBOutlet UITableView *tableview;

@end
