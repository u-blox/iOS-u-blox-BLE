//
//  FirstViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2015-02-23.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import "FirstViewController.h"
#import "olp425.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /*
    olp425 *myOLP = [olp425 init];
    
    [myOLP dostuff];
    */
    
    
    
}

-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"ViewController: %d",[[olp425 sharedInstance] myVar]);
    
    //[[olp425 sharedInstance] scan];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
