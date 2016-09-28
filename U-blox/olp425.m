//
//  olp425.m
//  U-blox
//
//  Created by Bill Martensson on 2015-02-23.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "olp425.h"
@interface olp425 ()

@end

@implementation olp425
{
}

@synthesize cbCentralManager, discoveredPeripherals, scanning;
@synthesize currentPeripheralUUID, serialPorts;

static olp425 *shared = nil;

+(id)sharedInstance {
    
    // Fundamental iOS design patterns: SharedInstance (Singleton in Objective C)
    // http://www.daveoncode.com/2011/12/19/fundamental-ios-design-patterns-sharedinstance-singleton-objective-c/
    
    static dispatch_once_t p = 0;
    
    __strong static id _sharedObject = nil;
    
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
}

- (id)init {
    self =[super init];
    if (self) {
        currentPeripheralUUID = @"";
        scanning = NO;
        discoveredPeripherals = [[NSMutableArray alloc] init];
        cbCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        
        serialPorts = [[NSMutableArray alloc] init];
        
        /*
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self sortPeripherals];
        });
        */
    }
    return self;
}

-(void)sortPeripherals
{
    if(scanning == NO)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self sortPeripherals];
        });

        return;
    }
    
    NSMutableArray *sortedArray = discoveredPeripherals;
    
    NSNumber *highestRSSI = [NSNumber numberWithInt:0];
    int highestRSSIindex = -1;
    
    NSTimeInterval timeNow = [[NSDate date] timeIntervalSince1970];
    
    for(int i = 0;i < sortedArray.count;i++)
    {
        highestRSSI = [NSNumber numberWithInt:0];
        highestRSSIindex = -1;
        
        NSNumber *lastSeenStamp = [[sortedArray objectAtIndex:i] objectForKey:@"timestamp"];
        
        if(timeNow - [lastSeenStamp doubleValue] > 3)
        {
            NSMutableDictionary *thisDict = [sortedArray objectAtIndex:i];
            [thisDict setObject:[NSNumber numberWithInt:-999] forKey:@"RSSI"];
            [sortedArray replaceObjectAtIndex:i withObject:thisDict];
        }
        
        for(int j = i;j < sortedArray.count;j++)
        {
            NSNumber *peripheralRSSI = [[sortedArray objectAtIndex:j] objectForKey:@"RSSI"];
                        
            if(peripheralRSSI > highestRSSI)
            {
                highestRSSI = peripheralRSSI;
                highestRSSIindex = j;
            }
        }
        if(highestRSSIindex != -1)
        {
            NSMutableDictionary *tempDict = [sortedArray objectAtIndex:i];
            [sortedArray replaceObjectAtIndex:i withObject:[sortedArray objectAtIndex:highestRSSIindex]];
            [sortedArray replaceObjectAtIndex:highestRSSIindex withObject:tempDict];
        }
    }

    discoveredPeripherals = sortedArray;

    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"peripheralListChange"
     object:self userInfo:nil];

    /*
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self sortPeripherals];
    });
    */
    
}

- (BOOL) scan: (bool)scanOn services:(NSArray*)services
{
    scanning = scanOn;
    
    if(scanOn)
    {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [cbCentralManager scanForPeripheralsWithServices:services options:dictionary];
    } else {
        [cbCentralManager stopScan];
    }
    
    return scanning;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{

}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // When connected to a peripheral, directly discover services.
    [peripheral discoverServices:nil];
    
    [peripheral readRSSI];
    
    // If no peripheral is selected as current, select this one.
    if([currentPeripheralUUID isEqualToString:@""])
    {
        currentPeripheralUUID = peripheral.identifier.UUIDString;
    }
    
    // Post a notifivation that the peripheral have updated.
    NSDictionary *updateDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: peripheral.identifier.UUIDString, @"UUID", nil];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"peripheralUpdate"
     object:self userInfo:updateDictionary];

}

- (void)centralManager:(CBCentralManager *)cm didFailToConnectPeripheral:(CBPeripheral *)periph error:(NSError *)error
{
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Check if disconnected from current peripheral
    if([peripheral.identifier.UUIDString isEqualToString:currentPeripheralUUID])
    {
        currentPeripheralUUID = @"";
    }
    
    // Count number of connected peripherals
    int connectedCount = 0;
    
    CBPeripheral *discPeripheral;
    
    for(int i = 0; (i < discoveredPeripherals.count); i++)
    {
        discPeripheral = [[discoveredPeripherals objectAtIndex:i] objectForKey:@"peripheral"];

        if(discPeripheral.state == CBPeripheralStateConnected)
        {
            connectedCount++;
            
            // Select a new current peripheral if none is selected.
            if([currentPeripheralUUID isEqualToString:@""])
            {
                currentPeripheralUUID = peripheral.identifier.UUIDString;
            }
        }

        // Post a notification that the peripheral was updated
        if([discPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
        {
            NSDictionary *updateDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: currentPeripheralUUID, @"UUID", nil];
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"peripheralUpdate"
             object:self userInfo:updateDictionary];
            
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    int foundIndex = -1;
    
    BOOL newPeripheral = YES;
    
    CBPeripheral *discPeripheral;
    
    NSMutableDictionary *peripheralDict = [[NSMutableDictionary alloc] init];
    
    for(int i = 0; (i < discoveredPeripherals.count); i++)
    {
        discPeripheral = [[discoveredPeripherals objectAtIndex:i] objectForKey:@"peripheral"];
        
        if([discPeripheral .identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
        {
            newPeripheral = NO;
            
            foundIndex = i;
            
            [peripheralDict setObject:RSSI forKey:@"RSSI"];
            [peripheralDict setObject:peripheral forKey:@"peripheral"];
            [peripheralDict setObject:[NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]] forKey:@"timestamp"];

            [discoveredPeripherals replaceObjectAtIndex:i withObject:peripheralDict];
        }
    }
    
    if(newPeripheral)
    {
        peripheral.delegate = self;
        
        [peripheralDict setObject:RSSI forKey:@"RSSI"];
        [peripheralDict setObject:peripheral forKey:@"peripheral"];
        [peripheralDict setObject:peripheral.identifier.UUIDString forKey:@"UUID"];
        [peripheralDict setObject:[NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]] forKey:@"timestamp"];
        
        [discoveredPeripherals addObject:peripheralDict];
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"peripheralListChange"
         object:self userInfo:peripheralDict];

    } else {
        [peripheralDict setObject:peripheral.identifier.UUIDString forKey:@"UUID"];
        [peripheralDict setObject:peripheral forKey:@"peripheral"];
        
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"peripheralUpdate"
         object:self userInfo:peripheralDict];
    }

}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CoreBluetooth BLE hardware is powered off");
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CoreBluetooth BLE hardware is resetting");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CoreBluetooth BLE state is unauthorized");
            break;
        case CBCentralManagerStateUnknown:
            NSLog(@"CoreBluetooth BLE state is unknown");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
            break;
        default:
            break;
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    
    NSLog(@"didDiscoverServices %@", peripheral.identifier.UUIDString);
    
    CBPeripheral *discPeripheral;
    
    CBService *serialService = nil;
    
    BOOL haveSerialService = NO;
    
    for(int i = 0;i < peripheral.services.count;i++)
    {
        serialService = [peripheral.services objectAtIndex:i];

        NSData *thisServiceUUIDdata = [serialService.UUID data];
        
        if([thisServiceUUIDdata isEqualToData:[[NSData alloc] initWithBytes:serialPortServiceUuid length:16]])
        {
            haveSerialService = YES;
            break;
        }
    }
    
    if(serialService != nil && haveSerialService)
    {
        bool peripheralSerialPortExist = false;
        
        for(SerialPort* sp in serialPorts)
        {
            if([peripheral.identifier.UUIDString isEqualToString:sp.peripheral.identifier.UUIDString])
            {
                peripheralSerialPortExist = true;
            }
        }

        
        if(peripheralSerialPortExist == false)
        {
            SerialPort* sp = [[SerialPort alloc] initWithPeripheral:peripheral andDelegate:self];
            [serialPorts addObject:sp];
        } 
    }
    
    for(int i = 0;i < peripheral.services.count;i++)
    {
        CBService *thisService = [peripheral.services objectAtIndex:i];
        
        [peripheral discoverCharacteristics:nil forService:thisService];
    }
    
    for(int i = 0; (i < discoveredPeripherals.count); i++)
    {
        NSMutableDictionary *thisPeripheralDictionary = [discoveredPeripherals objectAtIndex:i];
        discPeripheral = [thisPeripheralDictionary objectForKey:@"peripheral"];
        
        if([discPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
        {
            if(serialService != nil)
            {
                NSData *thisServiceUUIDdata = [serialService.UUID data];
                if([thisServiceUUIDdata isEqualToData:[[NSData alloc] initWithBytes:serialPortServiceUuid length:16]])
                {
                    for(SerialPort* sp in serialPorts)
                    {
                        if([sp.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
                        {
                            [sp serialportPeripheral:peripheral didDiscoverServices:error];
                        }
                    }
                }
            }
            
            NSDictionary *updateDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: discPeripheral.identifier.UUIDString, @"UUID", nil];
            
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"peripheralService"
             object:self userInfo:updateDictionary];
            
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSData *thisServiceUUIDdata = [service.UUID data];
    
    if([thisServiceUUIDdata isEqualToData:[[NSData alloc] initWithBytes:serialPortServiceUuid length:16]])
    {
        for(SerialPort* sp in serialPorts)
        {
            if([sp.peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
            {
                [sp serialportPeripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
            }
        }
    }

    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)charact error:(NSError *)error
{
    for(SerialPort* sp in serialPorts)
    {
        if([peripheral.identifier.UUIDString isEqualToString:sp.peripheral.identifier.UUIDString])
        {
            [sp serialportPeripheral:peripheral didUpdateValueForCharacteristic:charact error:error];
        }
    }

    if(error == nil)
    {
        CBPeripheral *discPeripheral;
        
        for(int i = 0; (i < discoveredPeripherals.count); i++)
        {
            discPeripheral = [[discoveredPeripherals objectAtIndex:i] objectForKey:@"peripheral"];
            
            if([discPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
            {
                int charActEnum = -1;
                
                NSData *thisCBUUIDdata = [charact.UUID data];
                
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:redLedCharactUuid length:2]])
                {
                    charActEnum = OLP425_LEDRED;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:greenLedCharactUuid length:2]])
                {
                    charActEnum = OLP425_LEDGREEN;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:blueLedCharactUuid length:2]])
                {
                    charActEnum = OLP425_LEDBLUE;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:rgbLedCharactUuid length:2]])
                {
                    charActEnum = OLP425_LEDRGB;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:tempValueCharactUuid length:2]])
                {
                    charActEnum = OLP425_TEMPERATURE;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:batteryLevelCharactUuid length:2]])
                {
                    charActEnum = OLP425_BATTERY;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accRangeCharactUuid length:2]])
                {
                    charActEnum = OLP425_ACCRANGE;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accXCharactUuid length:2]])
                {
                    charActEnum = OLP425_ACCX;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accYCharactUuid length:2]])
                {
                    charActEnum = OLP425_ACCY;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accZCharactUuid length:2]])
                {
                    charActEnum = OLP425_ACCZ;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroXCharactUuid length:2]])
                {
                    charActEnum = OLP425_GYROX;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroYCharactUuid length:2]])
                {
                    charActEnum = OLP425_GYROY;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroZCharactUuid length:2]])
                {
                    charActEnum = OLP425_GYROZ;
                }
                if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroCharactUuid length:2]])
                {
                    charActEnum = OLP425_GYRO;
                }
                
                NSDictionary *valueDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: discPeripheral.identifier.UUIDString, @"UUID", charact, @"characteristic", [NSNumber numberWithInt:charActEnum], @"OLP425characteristic", nil];
                
                
                
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"peripheralValue"
                 object:self userInfo:valueDictionary];
                
            }
        }

    }
}


- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{

}

-(void) peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [peripheral readRSSI];
    });
    
    
    NSDictionary *updateDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: peripheral.identifier.UUIDString, @"UUID", RSSI, @"RSSI", nil];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"peripheralRSSIUpdate"
     object:self userInfo:updateDictionary];
}



- (void)connectPeripheral: (CBPeripheral*)peripheral
{
    if(peripheral.state == CBPeripheralStateDisconnected)
    {
        NSDictionary *dictionary;
    
        dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey];
    
        [cbCentralManager connectPeripheral:peripheral options:dictionary];
    } else {
        [cbCentralManager cancelPeripheralConnection:peripheral];
    }
}
- (void)disconnectPeripheral: (CBPeripheral*)peripheral
{
    if(peripheral.state == CBPeripheralStateConnected)
    {
        [cbCentralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)clearPeripheralList
{
    discoveredPeripherals = [[NSMutableArray alloc] init];
    currentPeripheralUUID = @"";
}

- (CBPeripheral*)getCurrentPeripheral
{
    for(int i = 0; (i < discoveredPeripherals.count); i++)
    {
        CBPeripheral *discPeripheral = [[discoveredPeripherals objectAtIndex:i] objectForKey:@"peripheral"];
        
        if([discPeripheral.identifier.UUIDString isEqualToString:currentPeripheralUUID])
        {
            return discPeripheral;
        }
    }
    return nil;
}

- (NSString*)getCurrentUUID
{
    return currentPeripheralUUID;
}

- (void)writeDataToPeripheral: (CBPeripheral*)peripheral olp425charAct:(int)olp425charAct value:(NSData*)value
{    
    for(int s = 0;s < peripheral.services.count;s++)
    {
        CBService *thisService = [peripheral.services objectAtIndex:s];
        for(int c = 0;c < thisService.characteristics.count;c++)
        {
            CBCharacteristic *thisCharacteristic = [thisService.characteristics objectAtIndex:c];
            
            NSData *thisCBUUIDdata = [thisCharacteristic.UUID data];

            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:redLedCharactUuid length:2]] && olp425charAct == OLP425_LEDRED)
            {
                [peripheral writeValue:value forCharacteristic:thisCharacteristic type:CBCharacteristicWriteWithResponse];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:greenLedCharactUuid length:2]] && olp425charAct == OLP425_LEDGREEN)
            {
                [peripheral writeValue:value forCharacteristic:thisCharacteristic type:CBCharacteristicWriteWithResponse];
            }
        }
    }
}

- (void)readDataFromPeripheral: (CBPeripheral*)peripheral olp425charAct:(int)olp425charAct
{
    for(int s = 0;s < peripheral.services.count;s++)
    {
        CBService *thisService = [peripheral.services objectAtIndex:s];
        for(int c = 0;c < thisService.characteristics.count;c++)
        {
            CBCharacteristic *thisCharacteristic = [thisService.characteristics objectAtIndex:c];
            
            NSData *thisCBUUIDdata = [thisCharacteristic.UUID data];
            
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:redLedCharactUuid length:2]] && olp425charAct == OLP425_LEDRED)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:greenLedCharactUuid length:2]] && olp425charAct == OLP425_LEDGREEN)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:tempValueCharactUuid length:2]] && olp425charAct == OLP425_TEMPERATURE)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:batteryLevelCharactUuid length:2]] && olp425charAct == OLP425_BATTERY)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accRangeCharactUuid length:2]] && olp425charAct == OLP425_ACCRANGE)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accXCharactUuid length:2]] && olp425charAct == OLP425_ACCX)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accYCharactUuid length:2]] && olp425charAct == OLP425_ACCY)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accZCharactUuid length:2]] && olp425charAct == OLP425_ACCZ)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroXCharactUuid length:2]] && olp425charAct == OLP425_GYROX)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroYCharactUuid length:2]] && olp425charAct == OLP425_GYROY)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroZCharactUuid length:2]] && olp425charAct == OLP425_GYROZ)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroCharactUuid length:2]] && olp425charAct == OLP425_GYRO)
            {
                [peripheral readValueForCharacteristic:thisCharacteristic];
            }
        }
    }
}

- (void)notifyPeripheral: (CBPeripheral*)peripheral olp425charAct:(int)olp425charAct notify:(BOOL)notify
{
    for(int s = 0;s < peripheral.services.count;s++)
    {
        CBService *thisService = [peripheral.services objectAtIndex:s];
        for(int c = 0;c < thisService.characteristics.count;c++)
        {
            CBCharacteristic *thisCharacteristic = [thisService.characteristics objectAtIndex:c];
            
            NSData *thisCBUUIDdata = [thisCharacteristic.UUID data];
            
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:redLedCharactUuid length:2]] && olp425charAct == OLP425_LEDRED)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:greenLedCharactUuid length:2]] && olp425charAct == OLP425_LEDGREEN)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:tempValueCharactUuid length:2]] && olp425charAct == OLP425_TEMPERATURE)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:batteryLevelCharactUuid length:2]] && olp425charAct == OLP425_BATTERY)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accRangeCharactUuid length:2]] && olp425charAct == OLP425_ACCRANGE)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accXCharactUuid length:2]] && olp425charAct == OLP425_ACCX)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accYCharactUuid length:2]] && olp425charAct == OLP425_ACCY)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accZCharactUuid length:2]] && olp425charAct == OLP425_ACCZ)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroXCharactUuid length:2]] && olp425charAct == OLP425_GYROX)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroYCharactUuid length:2]] && olp425charAct == OLP425_GYROY)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroZCharactUuid length:2]] && olp425charAct == OLP425_GYROZ)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
            if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroCharactUuid length:2]] && olp425charAct == OLP425_GYRO)
            {
                [peripheral setNotifyValue:notify forCharacteristic:thisCharacteristic];
            }
        }
    }
    
}

- (int)CBUUIDtype: (CBUUID*)thisCBUUID
{
    NSData *thisCBUUIDdata = [thisCBUUID data];
    
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:tempServiceUuid length:2]])
    {
        return OLP425_SERVICE_TEMPERATURE;
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:batteryServiceUuid length:2]])
    {
        return OLP425_SERVICE_BATTERY;
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accServiceUuid length:2]])
    {
        return OLP425_SERVICE_ACCELEROMETER;
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:ledServiceUuid length:2]])
    {
        return OLP425_SERVICE_LED;
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:serialPortServiceUuid length:16]])
    {
        return OLP425_SERVICE_SERIALPORT;
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:deviceIdServiceUuid length:2]])
    {
        return OLP425_SERVICE_DEVICEINFO;
    }
    
    return -1;
}

- (NSString*)CBUUIDString: (CBUUID*)thisCBUUID
{
    NSData *thisCBUUIDdata = [thisCBUUID data];
    
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:tempServiceUuid length:2]])
    {
        return @"Temperature";
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:batteryServiceUuid length:2]])
    {
        return @"Battery";
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:accServiceUuid length:2]])
    {
        return @"Accelerometer";
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:gyroServiceUuid length:2]])
    {
        return @"Gyro";
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:ledServiceUuid length:2]])
    {
        return @"LED";
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:serialPortServiceUuid length:16]])
    {
        return @"Serial Port";
    }
    if([thisCBUUIDdata isEqualToData:[[NSData alloc] initWithBytes:deviceIdServiceUuid length:2]])
    {
        return @"Device info";
    }
    
    return @"SERVICE";
}

- (NSString*)strFromCharacteristicUUID: (CBUUID*)serviceUuid charactUuid:(CBUUID*)charactUuid
{
    NSString*       str = nil;
    
    if( (serviceUuid.data.length == SERIAL_PORT_SERVICE_UUID_LEN) &&
       (memcmp(serviceUuid.data.bytes, serialPortServiceUuid, SERIAL_PORT_SERVICE_UUID_LEN) == 0))
    {
        if((charactUuid.data.length == CHARACT_UUID_SERIAL_LEN) &&
           (memcmp(charactUuid.data.bytes, flowControlModeCharactUuid, CHARACT_UUID_SERIAL_LEN) == 0))
        {
            str = @"Flow Control Mode";
        }
        else if( (charactUuid.data.length == CHARACT_UUID_SERIAL_LEN) &&
                (memcmp(charactUuid.data.bytes, serialPortFifoCharactUuid,CHARACT_UUID_SERIAL_LEN) == 0))
        {
            str = @"FIFO";
        }
        else if( (charactUuid.data.length == CHARACT_UUID_SERIAL_LEN) &&
                (memcmp(charactUuid.data.bytes, creditsCharactUuid, CHARACT_UUID_SERIAL_LEN) == 0))
        {
            str = @"Flow Control Credits";
        }
    }
    else if( (serviceUuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(serviceUuid.data.bytes, accServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
           (memcmp(charactUuid.data.bytes, accRangeCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Range";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, accXCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"X Value";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, accYCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Y Value";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, accZCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Z Value";
        }
    }
    else if( (serviceUuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(serviceUuid.data.bytes, gyroServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, gyroXCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"X Value";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, gyroYCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Y Value";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, gyroZCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Z Value";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, gyroCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"XYZ Value";
        }
    }
    else if( (serviceUuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(serviceUuid.data.bytes, tempServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
           (memcmp(charactUuid.data.bytes, tempValueCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Temperature";
        }
    }
    else if( (serviceUuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(serviceUuid.data.bytes, batteryServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
           (memcmp(charactUuid.data.bytes, batteryLevelCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Level";
        }
    }
    else if((serviceUuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(serviceUuid.data.bytes, ledServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
           (memcmp(charactUuid.data.bytes, greenLedCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Green LED";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, redLedCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Red LED";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, blueLedCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Blue LED";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, rgbLedCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"RGB LED";
        }
    }
    else if((serviceUuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(serviceUuid.data.bytes, deviceIdServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
           (memcmp(charactUuid.data.bytes, systemIdCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"System Identifier";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, modelNumberCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Model Number";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, serialNumberCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Serial Number";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, firmwareRevisionCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Firmware Revision";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, hardwareRevisionCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Hardware Revision";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, swRevisionCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Software Revision";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, manufactNameCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Manufacturer Name";
        }
        else if((charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                (memcmp(charactUuid.data.bytes, regCertCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
        {
            str = @"Regulatory Certification";
        }
    }
    
    if(str == nil)
    {
        str = [[NSString alloc] initWithFormat:@"%@", charactUuid];
    }
    
    return str;
}

// - (NSString*)strFromCharacteristicUUID: (CBUUID*)serviceUuid charactUuid:(CBUUID*)charactUuid
- (NSString*)strFromCharacteristicProperties: (CBCharacteristicProperties)properties
{
    NSString* str = @"";
    
    //str = [[NSString alloc] initWithFormat:@"0x%x: ", properties];
    
    if((properties & 0x01) != 0)
        str = @"Broadcast ";
    
    if((properties & 0x02) != 0)
        str = [[NSString alloc] initWithFormat:@"%@%@", str, @"Read "];
    
    if((properties & 0x04) != 0)
        str = [[NSString alloc] initWithFormat:@"%@%@", str, @"WriteWithoutResponse "];
    
    if((properties & 0x08) != 0)
        str = [[NSString alloc] initWithFormat:@"%@%@", str, @"Write "];
    
    if((properties & 0x10) != 0)
        str = [[NSString alloc] initWithFormat:@"%@%@", str, @"Notify "];
    
    if((properties & 0x20) != 0)
        str = [[NSString alloc] initWithFormat:@"%@%@", str, @"Indicate "];
    
    if((properties & 0x40) != 0)
        str = [[NSString alloc] initWithFormat:@"%@%@", str, @"AuthenticatedSignedWrites "];
    
    if((properties & 0x80) != 0)
        str = [[NSString alloc] initWithFormat:@"%@%@", str, @"ExtendedProperties "];
    
    return str;
}

///// SERIAL COMS
- (void)serialSendMessageToPeripheralUUID: (NSString*)peripheralUUID message:(NSString*)message
{
    SerialPort  *sp;
    
    for(int i = 0; i < serialPorts.count; i++)
    {
        sp = [serialPorts objectAtIndex:i];
        
        if([sp.peripheral.identifier.UUIDString isEqualToString:peripheralUUID])
        {
            [sp sendMessage:message];
        }
    }
}
@end
