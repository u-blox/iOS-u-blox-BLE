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

#import <CoreBluetooth/CBCentralManager.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBPeripheral.h>
#import <CoreBluetooth/CBService.h>
#import <CoreBluetooth/CBCharacteristic.h>
#import <CoreBluetooth/CBUUID.h>
#import "BLEDefinitions.h"
#import "ChatMessage.h"

#import "SerialPort.h"

#ifndef U_blox_olp425_h
#define U_blox_olp425_h

#endif



enum OLP425characteristics
{
    OLP425_LEDRED,
    OLP425_LEDGREEN,
    OLP425_LEDBLUE,
    OLP425_LEDRGB,
    OLP425_TEMPERATURE,
    OLP425_BATTERY,
    OLP425_ACCRANGE,
    OLP425_ACCX,
    OLP425_ACCY,
    OLP425_ACCZ,
    OLP425_GYROX,
    OLP425_GYROY,
    OLP425_GYROZ,
    OLP425_GYRO
    
};
enum OLP425service
{
    OLP425_SERVICE_LED,
    OLP425_SERVICE_TEMPERATURE,
    OLP425_SERVICE_BATTERY,
    OLP425_SERVICE_ACCELEROMETER,
    OLP425_SERVICE_SERIALPORT,
    OLP425_SERVICE_DEVICEINFO
};

@interface olp425 : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate>
{
}

@property enum OLP425characteristics    OLP425charact;

@property (nonatomic, strong) NSString *currentPeripheralUUID;

@property (nonatomic, assign) BOOL scanning;
@property (nonatomic, strong) CBCentralManager *cbCentralManager;
@property (nonatomic, strong) NSMutableArray *discoveredPeripherals;

+ (id)sharedInstance;

- (BOOL) scan: (bool)scanOn services:(NSArray*)services;

- (void)connectPeripheral: (CBPeripheral*)peripheral;
- (void)disconnectPeripheral: (CBPeripheral*)peripheral;

- (void)clearPeripheralList;
- (CBPeripheral*)getCurrentPeripheral;
- (NSString*)getCurrentUUID;

- (int)CBUUIDtype: (CBUUID*)thisCBUUID;
- (NSString*)CBUUIDString: (CBUUID*)CBUUID;

- (void)writeDataToPeripheral: (CBPeripheral*)peripheral olp425charAct:(int)olp425charAct value:(NSData*)value;

- (void)readDataFromPeripheral: (CBPeripheral*)peripheral olp425charAct:(int)olp425charAct;
- (void)notifyPeripheral: (CBPeripheral*)peripheral olp425charAct:(int)olp425charAct notify:(BOOL)notify;

- (NSString*)strFromCharacteristicUUID: (CBUUID*)serviceUuid charactUuid:(CBUUID*)charactUuid;
- (NSString*)strFromCharacteristicProperties: (CBCharacteristicProperties)properties;

-(void)sortPeripherals;

// SERIAL
@property (strong, strong) NSMutableArray *serialPorts;

- (void)serialSendMessageToPeripheralUUID: (NSString*)peripheralUUID message:(NSString*)message;
@end