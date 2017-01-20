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

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CBPeripheral.h>
#import "BLEDefinitions.h"
#import "ChatMessage.h"

#define SP_MAX_WRITE_SIZE   (20)

typedef enum
{
    SP_EVT_OPEN,
    SP_EVT_CLOSED
    
} SPEvent;

@class SerialPort;

@protocol SerialPortDelegate <NSObject>

- (void) port: (SerialPort*) serialPort event : (SPEvent) ev error: (NSInteger)err;

- (void) writeComplete: (SerialPort*) serialPort withError: (NSInteger)err;

- (void) port: (SerialPort*) serialPort receivedData: (NSData*)data;

@end

@interface SerialPort : NSObject <CBPeripheralDelegate>

@property (nonatomic) BOOL isOpen;
@property (nonatomic, readonly) BOOL isWriting;
@property (nonatomic, readonly) NSString *name;

@property (nonatomic, strong) CBPeripheral *peripheral;

- (SerialPort*) initWithPeripheral: (CBPeripheral*) peripheral andDelegate: (id) delegate;

- (BOOL) open;
- (void) close;

- (BOOL) write: (NSData*) data;

- (void)sendMessage: (NSString*)message;

- (void)serialportPeripheral:(CBPeripheral *)periph didWriteValueForCharacteristic:(CBCharacteristic *)charact error:(NSError *)err;
- (void)serialportPeripheral:(CBPeripheral *)periph didUpdateValueForCharacteristic:(CBCharacteristic *)ch error:(NSError *)error;

- (void)serialportPeripheral:(CBPeripheral *)periph didDiscoverCharacteristicsForService:(CBService *)serv error:(NSError *)error;
- (void)serialportPeripheral:(CBPeripheral *)periph didDiscoverServices:(NSError *)error;
@end
