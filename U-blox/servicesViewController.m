//
//  servicesViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2015-03-24.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import "servicesViewController.h"
#import "servicesTableViewCell.h"

@interface servicesViewController ()

@end

@implementation servicesViewController

@synthesize tableview, navbarButton, navbarLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralService:)
                                                 name:@"peripheralService"
                                               object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if([[[olp425 sharedInstance] currentPeripheralUUID] isEqualToString:@""])
    {
        self.navbarLabel.text = @"Not connected";
        
        self.navbarButton.hidden = YES;
    } else {
        CBPeripheral *discPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
        
        self.navbarLabel.text = discPeripheral.name;
        
        self.navbarButton.hidden = NO;
    }

    
    [tableview reloadData];
}

- (void) peripheralService:(NSNotification *) notification
{
    [tableview reloadData];
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



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    if(thisPeripheral == nil)
    {
        return 0;
    }
    return thisPeripheral.services.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"servicecell";
    
    servicesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    NSArray *thisPeripheralServices = thisPeripheral.services;
    CBMutableService *thisService = [thisPeripheralServices objectAtIndex:indexPath.row];
    CBUUID *thisServiceUUID = thisService.UUID;
    
    cell.serviceName.text = [[olp425 sharedInstance] CBUUIDString:thisServiceUUID];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"detail" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *ind = [tableview indexPathForSelectedRow];

    if ([segue.identifier isEqualToString:@"detail"])
    {
        servicesDetailViewController *vc = segue.destinationViewController;
        
        CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
        
        NSArray *thisPeripheralServices = thisPeripheral.services;
        CBMutableService *thisService = [thisPeripheralServices objectAtIndex:ind.row];
        
        
        vc.serviceUUID = thisService.UUID.UUIDString;
    }

    [tableview deselectRowAtIndexPath:ind animated:YES];

}

- (IBAction) selectDevice: (id) UIButton
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Select device"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    for(int i = 0; i < [[olp425 sharedInstance] discoveredPeripherals].count;i++)
    {
        NSMutableDictionary *thisPeripheralDict = [[[olp425 sharedInstance] discoveredPeripherals] objectAtIndex:i];
        CBPeripheral *thisPeripheral = [thisPeripheralDict objectForKey:@"peripheral"];
        
        if(thisPeripheral.state == CBPeripheralStateConnected)
        {
            [alertController addAction:[UIAlertAction
                                        actionWithTitle:thisPeripheral.name
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                                        {
                                            [[olp425 sharedInstance] setCurrentPeripheralUUID:thisPeripheral.identifier.UUIDString];
                                            
                                            [tableview reloadData];
                                            
                                        }]];
        }
    }
    
    
    [alertController addAction:[UIAlertAction
                                actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                style:UIAlertActionStyleCancel
                                handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}


@end
