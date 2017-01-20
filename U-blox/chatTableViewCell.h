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
