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

    if([[[ublox sharedInstance] currentPeripheralUUID] isEqualToString:@""])
    {
        self.navbarLabel.text = @"Not connected";
        
        self.navbarButton.hidden = YES;
    } else {
        CBPeripheral *discPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
        
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
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
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
    
    CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    NSArray *thisPeripheralServices = thisPeripheral.services;
    CBMutableService *thisService = [thisPeripheralServices objectAtIndex:indexPath.row];
    CBUUID *thisServiceUUID = thisService.UUID;
    
    cell.serviceName.text = [[ublox sharedInstance] CBUUIDString:thisServiceUUID];
    
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
        
        CBPeripheral *thisPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
        
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
    
    for(int i = 0; i < [[ublox sharedInstance] discoveredPeripherals].count;i++)
    {
        NSMutableDictionary *thisPeripheralDict = [[[ublox sharedInstance] discoveredPeripherals] objectAtIndex:i];
        CBPeripheral *thisPeripheral = [thisPeripheralDict objectForKey:@"peripheral"];
        
        if(thisPeripheral.state == CBPeripheralStateConnected)
        {
            [alertController addAction:[UIAlertAction
                                        actionWithTitle:thisPeripheral.name
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                                        {
                                            [[ublox sharedInstance] setCurrentPeripheralUUID:thisPeripheral.identifier.UUIDString];
                                            
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
