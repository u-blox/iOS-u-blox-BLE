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

#import "editViewController.h"
#import "BLEDefinitions.h"

@interface editViewController ()

@end

@implementation editViewController
@synthesize serviceUUID,characteristicUUID;
@synthesize serviceLabel, characteristicLabel, valueLabel, textTextfield, hexTextfield, intTextfield;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    CBService *thisService = nil;
    CBCharacteristic *thisCharacteristic = nil;
    
    for(int i = 0;i < thisPeripheral.services.count;i++)
    {
        thisService = [thisPeripheral.services objectAtIndex:i];
        if([thisService.UUID.UUIDString isEqualToString:serviceUUID])
        {
            serviceLabel.text = [[olp425 sharedInstance] CBUUIDString:thisService.UUID];
            for(int j = 0;j < thisService.characteristics.count;j++)
            {
                thisCharacteristic = [thisService.characteristics objectAtIndex:j];
                if([thisCharacteristic.UUID.UUIDString isEqualToString:characteristicUUID])
                {
                    characteristicLabel.text = [[olp425 sharedInstance] strFromCharacteristicUUID:thisService.UUID charactUuid:thisCharacteristic.UUID];
                    
                    valueLabel.text = strFromCharacteristicValue(thisService.UUID, thisCharacteristic.UUID, thisCharacteristic.value);
                    
                    [thisPeripheral setNotifyValue:YES forCharacteristic:thisCharacteristic];
                }
            }
        }
    }
    
    if((thisCharacteristic.properties & 0x04) != 0)
    {
        self.textTextfield.hidden = NO;
        self.hexTextfield.hidden = NO;
        self.intTextfield.hidden = NO;
    }
    else if((thisCharacteristic.properties & 0x08) != 0)
    {
        self.textTextfield.hidden = NO;
        self.hexTextfield.hidden = NO;
        self.intTextfield.hidden = NO;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralValue:)
                                                 name:@"peripheralValue"
                                               object:nil];

    
}

- (void) peripheralValue:(NSNotification *) notification
{
    NSDictionary *dict = [notification userInfo];
    
    CBCharacteristic *foundCharact = [dict objectForKey:@"characteristic"];
    
    if([foundCharact.UUID.UUIDString isEqualToString:characteristicUUID])
    {
        valueLabel.text = [NSString stringWithFormat:@"%@", foundCharact.value];
    }

}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    CBService *thisService = nil;
    CBCharacteristic *thisCharacteristic = nil;
    
    for(int i = 0;i < thisPeripheral.services.count;i++)
    {
        thisService = [thisPeripheral.services objectAtIndex:i];
        if([thisService.UUID.UUIDString isEqualToString:serviceUUID])
        {
            for(int j = 0;j < thisService.characteristics.count;j++)
            {
                thisCharacteristic = [thisService.characteristics objectAtIndex:j];
                if([thisCharacteristic.UUID.UUIDString isEqualToString:characteristicUUID])
                {
                    [thisPeripheral setNotifyValue:NO forCharacteristic:thisCharacteristic];
                }
            }
        }
    }

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    CBService *thisService = nil;
    CBCharacteristic *thisCharacteristic = nil;
    
    for(int i = 0;i < thisPeripheral.services.count;i++)
    {
        thisService = [thisPeripheral.services objectAtIndex:i];
        if([thisService.UUID.UUIDString isEqualToString:serviceUUID])
        {
            break;
        }
    }
    for(int j = 0;j < thisService.characteristics.count;j++)
    {
        thisCharacteristic = [thisService.characteristics objectAtIndex:j];
        if([thisCharacteristic.UUID.UUIDString isEqualToString:characteristicUUID])
        {
            break;
        }
    }

    
    [textField resignFirstResponder];
    
    if (textField == textTextfield) {
        NSRange     range;
        BOOL        ok = TRUE;
        NSUInteger  len;
        
        range.location = 0;
        range.length = [textTextfield.text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        
        unsigned char   *buf = malloc(range.length);
        
        ok = [textTextfield.text getBytes:buf maxLength:range.length usedLength:&len encoding:NSUTF8StringEncoding options:NSStringEncodingConversionAllowLossy range:range remainingRange:&range];
        
        if(ok == TRUE)
        {
            NSData *valueData = [NSData  dataWithBytes:buf length:len];
            
            if((thisCharacteristic.properties & 0x04) != 0)
            {
                [thisPeripheral writeValue:valueData forCharacteristic:thisCharacteristic type:CBCharacteristicWriteWithoutResponse];
            }
            else if((thisCharacteristic.properties & 0x08) != 0)
            {
                [thisPeripheral writeValue:valueData forCharacteristic:thisCharacteristic type:CBCharacteristicWriteWithResponse];
            }

        }
        
        free(buf);

    }
    if (textField == hexTextfield) {
        NSScanner       *scanner = [NSScanner alloc];
        NSInteger       bufSize = (hexTextfield.text.length + 1) / 2;
        unsigned char   *buf = malloc(bufSize);
        
        NSString    *str;
        NSRange     range;
        unsigned int  val;
        BOOL        ok = TRUE;
        NSInteger   pos = 0;
        
        for(int i = 0; (i < bufSize) && (ok == TRUE); i++)
        {
            range.location = pos;
            
            if( (pos == 0) && (hexTextfield.text.length % 2) != 0)
            {
                range.length = 1;
                pos += 1;
            }
            else
            {
                range.length = 2;
                pos += 2;
            }
            
            str = [hexTextfield.text substringWithRange:range];
            
            scanner = [scanner initWithString:str];
            
            ok = [scanner scanHexInt: &val];
            
            if(ok)
            {
                buf[bufSize - i - 1] = val;
            }
        }
        
        if(ok)
        {
            NSData *valueData = [NSData dataWithBytes:buf length:bufSize];
            
            if((thisCharacteristic.properties & 0x04) != 0)
            {
                [thisPeripheral writeValue:valueData forCharacteristic:thisCharacteristic type:CBCharacteristicWriteWithoutResponse];
            }
            else if((thisCharacteristic.properties & 0x08) != 0)
            {
                [thisPeripheral writeValue:valueData forCharacteristic:thisCharacteristic type:CBCharacteristicWriteWithResponse];
            }
        }
        
        free(buf);    }
    if (textField == intTextfield) {
        int writeValue = [[textField text] intValue];
        
        NSData *valueData = [NSData dataWithBytes:&writeValue length:1];
        
        if((thisCharacteristic.properties & 0x04) != 0)
        {
            [thisPeripheral writeValue:valueData forCharacteristic:thisCharacteristic type:CBCharacteristicWriteWithoutResponse];
        }
        else if((thisCharacteristic.properties & 0x08) != 0)
        {
            [thisPeripheral writeValue:valueData forCharacteristic:thisCharacteristic type:CBCharacteristicWriteWithResponse];
        }

    }
    
    return YES;
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

@end
