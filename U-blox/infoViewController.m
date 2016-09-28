//
//  infoViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2015-05-04.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import "infoViewController.h"

@interface infoViewController ()

@end

@implementation infoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)closeInfo:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openWeb:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://u-blox.com"]];
}

@end
