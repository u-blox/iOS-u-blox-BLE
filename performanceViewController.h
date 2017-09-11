//
//  performanceViewController.h
//  U-blox
//
//  Created by Bill Martensson on 2017-05-19.
//  Copyright © 2017 U-blox. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface performanceViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
    
}

@property (weak, nonatomic) IBOutlet UITableView *pTableView;


@end
