//
//  scanViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2015-02-23.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import "scanViewController.h"
#import "scanTableViewCell.h"

@interface scanViewController ()

@end

@implementation scanViewController

@synthesize tableview,scanButton,scanIndicator;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralListChange:)
                                                 name:@"peripheralListChange"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralUpdate:)
                                                 name:@"peripheralUpdate"
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    if([[olp425 sharedInstance] scan:NO services:nil])
    {
        [scanButton setTitle:@"Scanning..." forState:UIControlStateNormal];
        scanIndicator.hidden = NO;
    } else {
        [scanButton setTitle:@"Start scan" forState:UIControlStateNormal];
        scanIndicator.hidden = YES;
    }

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

- (void) peripheralListChange:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"peripheralListChange"])
    {
        [tableview reloadData];
        
    }
    
}

- (void) peripheralUpdate:(NSNotification *) notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableview reloadData];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[olp425 sharedInstance] discoveredPeripherals].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"devicecell";
    
    scanTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSMutableDictionary *thisPeripheralDict = [[[olp425 sharedInstance] discoveredPeripherals] objectAtIndex:indexPath.row];
    
    NSNumber *thisRSSI = [thisPeripheralDict objectForKey:@"RSSI"];
    CBPeripheral *thisPeripheral = [thisPeripheralDict objectForKey:@"peripheral"];
    
    cell.name.text = [thisPeripheral name];
    
    if(thisPeripheral.state == CBPeripheralStateConnected)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.rssi.text = @"";
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        if(thisRSSI == [NSNumber numberWithInt:127] || thisRSSI == [NSNumber numberWithInt:-999])
        {
            cell.rssi.text = [NSString stringWithFormat:@"(GONE)"];
        } else {
            cell.rssi.text = [NSString stringWithFormat:@"(RSSI %@)", thisRSSI];
        }
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *thisPeripheralDict = [[[olp425 sharedInstance] discoveredPeripherals] objectAtIndex:indexPath.row];
    
    CBPeripheral *thisPeripheral = [thisPeripheralDict objectForKey:@"peripheral"];

    [[olp425 sharedInstance] connectPeripheral:thisPeripheral];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)scanButtonClick:(id)sender
{
    if([[olp425 sharedInstance] scan:![[olp425 sharedInstance] scanning] services:nil])
    {
        [scanButton setTitle:@"Scanning..." forState:UIControlStateNormal];
        scanIndicator.hidden = NO;
    } else {
        [scanButton setTitle:@"Start scan" forState:UIControlStateNormal];
        scanIndicator.hidden = YES;
    }
    
}

- (IBAction)clearButtonClick:(id)sender
{
    [[olp425 sharedInstance] scan:NO services:nil];
    [[olp425 sharedInstance] clearPeripheralList];

    [scanButton setTitle:@"Start scan" forState:UIControlStateNormal];
    scanIndicator.hidden = YES;

    [tableview reloadData];
}

@end
