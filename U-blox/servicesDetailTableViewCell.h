//
//  servicesDetailTableViewCell.h
//  U-blox
//
//  Created by Bill Martensson on 2015-04-10.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface servicesDetailTableViewCell : UITableViewCell
{
}

@property (strong, nonatomic) IBOutlet UILabel *characteristicName;
@property (strong, nonatomic) IBOutlet UILabel *characteristicValue;
@property (strong, nonatomic) IBOutlet UILabel *characteristicType;

@end
