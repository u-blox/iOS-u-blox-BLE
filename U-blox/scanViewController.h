//
//  scanViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2015-02-23.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "olp425.h"

@interface scanViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
}

@property (strong, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) IBOutlet UIButton *scanButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *scanIndicator;

- (IBAction)scanButtonClick:(id)sender;
- (IBAction)clearButtonClick:(id)sender;

@end
