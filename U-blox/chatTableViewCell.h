//
//  chatTableViewCell.h
//  U-blox
//
//  Created by Bill Martensson on 2015-04-13.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface chatTableViewCell : UITableViewCell
{
}

@property (strong, nonatomic) IBOutlet UILabel *userFromLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateFromLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageFromLabel;
@property (strong, nonatomic) IBOutlet UIView *messageFromView;

@property (strong, nonatomic) IBOutlet UILabel *userToLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateToLabel;
@property (strong, nonatomic) IBOutlet UILabel *messageToLabel;
@property (strong, nonatomic) IBOutlet UIView *messageToView;

@property (strong, nonatomic) IBOutlet UIImageView *imageFrom;
@property (strong, nonatomic) IBOutlet UIImageView *imageTo;


@end
