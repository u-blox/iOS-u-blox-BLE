//
//  servicesDetailViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2015-04-10.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import "servicesDetailViewController.h"
#import "BLEDefinitions.h"

@interface servicesDetailViewController ()

@end

@implementation servicesDetailViewController
@synthesize tableview, serviceUUID;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralValue:)
                                                 name:@"peripheralValue"
                                               object:nil];

    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    CBCharacteristic *thisCharacteristic = nil;
    
    CBService *thisService = nil;
    
    for(int i = 0;i < thisPeripheral.services.count;i++)
    {
        thisService = [thisPeripheral.services objectAtIndex:i];
        if([thisService.UUID.UUIDString isEqualToString:serviceUUID])
        {
            for(int c = 0;c < thisService.characteristics.count;c++)
            {
                thisCharacteristic = [thisService.characteristics objectAtIndex:c];
                
                [thisPeripheral readValueForCharacteristic:thisCharacteristic];
            }
        }
    }
}

- (void) peripheralValue:(NSNotification *) notification
{
    NSDictionary *dict = [notification userInfo];
    
    CBCharacteristic *foundCharact = [dict objectForKey:@"characteristic"];
    
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    CBCharacteristic *thisCharacteristic = nil;
    
    CBService *thisService = nil;
    
    for(int i = 0;i < thisPeripheral.services.count;i++)
    {
        thisService = [thisPeripheral.services objectAtIndex:i];
        if([thisService.UUID.UUIDString isEqualToString:serviceUUID])
        {
            for(int c = 0;c < thisService.characteristics.count;c++)
            {
                thisCharacteristic = [thisService.characteristics objectAtIndex:c];
                
                NSData *thisCBUUIDdata = [thisCharacteristic.UUID data];
                NSData *valueCBUUIDdata = [foundCharact.UUID data];
                
                if([thisCBUUIDdata isEqualToData:valueCBUUIDdata])
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSIndexPath* indexPath = [NSIndexPath indexPathForRow: c inSection:0];
                        
                        servicesDetailTableViewCell* cell = (servicesDetailTableViewCell*)[self.tableview cellForRowAtIndexPath:indexPath];
                        
                        //cell.characteristicValue.text = [NSString stringWithFormat:@"%@", foundCharact.value];
                        cell.characteristicValue.text = strFromCharacteristicValue(thisService.UUID, thisCharacteristic.UUID, thisCharacteristic.value);
                    });
                }
            }
        }
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    if(thisPeripheral == nil)
    {
        return 0;
    }
    
    for(int i = 0;i < thisPeripheral.services.count;i++)
    {
        CBService *thisService = [thisPeripheral.services objectAtIndex:i];
        if([thisService.UUID.UUIDString isEqualToString:serviceUUID])
        {
            return thisService.characteristics.count;
        }
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"detail";
    
    servicesDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    if(thisPeripheral == nil)
    {
        return 0;
    }
    
    CBCharacteristic *thisCharacteristic = nil;
    
    CBService *thisService = nil;
    
    for(int i = 0;i < thisPeripheral.services.count;i++)
    {
        thisService = [thisPeripheral.services objectAtIndex:i];
        if([thisService.UUID.UUIDString isEqualToString:serviceUUID])
        {
            thisCharacteristic = [thisService.characteristics objectAtIndex:indexPath.row];
            break;
        }
    }
    
    cell.characteristicName.text = [[olp425 sharedInstance] strFromCharacteristicUUID:thisService.UUID charactUuid:thisCharacteristic.UUID];
    cell.characteristicValue.text = strFromCharacteristicValue(thisService.UUID, thisCharacteristic.UUID, thisCharacteristic.value);
    cell.characteristicType.text = [[olp425 sharedInstance] strFromCharacteristicProperties:thisCharacteristic.properties];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"edit" sender:self];

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *ind = [tableview indexPathForSelectedRow];
    
    if ([segue.identifier isEqualToString:@"edit"])
    {
        editViewController *vc = segue.destinationViewController;
        
        CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
        
        CBService *thisService = nil;
        CBCharacteristic *thisCharacteristic = nil;
        
        for(int i = 0;i < thisPeripheral.services.count;i++)
        {
            thisService = [thisPeripheral.services objectAtIndex:i];
            if([thisService.UUID.UUIDString isEqualToString:serviceUUID])
            {
                thisCharacteristic = [thisService.characteristics objectAtIndex:ind.row];
            }
        }
        
        vc.characteristicUUID = thisCharacteristic.UUID.UUIDString;
        vc.serviceUUID = serviceUUID;
    }
    
    [tableview deselectRowAtIndexPath:ind animated:YES];
    
}
@end
