//
//  scanTableViewCell.h
//  U-blox
//
//  Created by Bill Martensson on 2015-02-23.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface scanTableViewCell : UITableViewCell
{

}

@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *rssi;

@end
