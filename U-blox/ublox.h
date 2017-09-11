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

#ifndef U_blox_ublox_h
#define U_blox_ublox_h

#endif



enum UBLOXcharacteristics
{
    UBLOX_LEDRED,
    UBLOX_LEDGREEN,
    UBLOX_LEDBLUE,
    UBLOX_LEDRGB,
    UBLOX_TEMPERATURE,
    UBLOX_BATTERY,
    UBLOX_ACCRANGE,
    UBLOX_ACCX,
    UBLOX_ACCY,
    UBLOX_ACCZ,
    UBLOX_GYROX,
    UBLOX_GYROY,
    UBLOX_GYROZ,
    UBLOX_GYRO
    
};
enum UBLOXservice
{
    UBLOX_SERVICE_LED,
    UBLOX_SERVICE_TEMPERATURE,
    UBLOX_SERVICE_BATTERY,
    UBLOX_SERVICE_ACCELEROMETER,
    UBLOX_SERVICE_SERIALPORT,
    UBLOX_SERVICE_DEVICEINFO
};

@interface ublox : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate>
{
}

@property enum UBLOXcharacteristics    UBLOXcharact;

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

- (void)writeDataToPeripheral: (CBPeripheral*)peripheral ubloxcharAct:(int)ubloxcharAct value:(NSData*)value;

- (void)readDataFromPeripheral: (CBPeripheral*)peripheral ubloxcharAct:(int)ubloxcharAct;
- (void)notifyPeripheral: (CBPeripheral*)peripheral ubloxcharAct:(int)ubloxcharAct notify:(BOOL)notify;

- (NSString*)strFromCharacteristicUUID: (CBUUID*)serviceUuid charactUuid:(CBUUID*)charactUuid;
- (NSString*)strFromCharacteristicProperties: (CBCharacteristicProperties)properties;

-(void)sortPeripherals;

// SERIAL
@property (strong, strong) NSMutableArray *serialPorts;

- (void)serialSendMessageToPeripheralUUID: (NSString*)peripheralUUID message:(NSString*)message;
@end
