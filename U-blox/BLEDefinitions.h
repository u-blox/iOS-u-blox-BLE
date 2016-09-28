//
//  BLEDefinitions.h
//  BLEDemo
//
//  Created by Tomas Henriksson on 1/18/12.
//  Copyright (c) 2012 connectBlue. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CBCharacteristic.h>
#import <CoreBluetooth/CBUUID.h>

#define SP_MAX_WRITE_SIZE   (20)

#define SERVICE_UUID_DEFAULT_LEN        (2)
#define CHARACT_UUID_DEFAULT_LEN        (2)

#define SERIAL_PORT_SERVICE_UUID_LEN    (16)
#define CHARACT_UUID_SERIAL_LEN         (16)

typedef enum
{
    CHAT_S_NOT_LOADED,
    CHAT_S_DISAPPEARED,
    CHAT_S_APPEARED_IDLE,
    CHAT_S_APPEARED_WAIT_TX,
    CHAT_S_APPEARED_NO_CONNECT_PERIPH
    
} CHAT_State;


extern const unsigned char accServiceUuid[SERVICE_UUID_DEFAULT_LEN];
extern const unsigned char accRangeCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char accXCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char accYCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char accZCharactUuid[CHARACT_UUID_DEFAULT_LEN];

extern const unsigned char gyroServiceUuid[SERVICE_UUID_DEFAULT_LEN];
extern const unsigned char gyroXCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char gyroYCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char gyroZCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char gyroCharactUuid[CHARACT_UUID_DEFAULT_LEN];

extern const unsigned char tempServiceUuid[SERVICE_UUID_DEFAULT_LEN];
extern const unsigned char tempValueCharactUuid[CHARACT_UUID_DEFAULT_LEN];

extern const unsigned char batteryServiceUuid[SERVICE_UUID_DEFAULT_LEN];
extern const unsigned char batteryLevelCharactUuid[CHARACT_UUID_DEFAULT_LEN];

extern const unsigned char ledServiceUuid[SERVICE_UUID_DEFAULT_LEN];
extern const unsigned char redLedCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char greenLedCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char blueLedCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char rgbLedCharactUuid[CHARACT_UUID_DEFAULT_LEN];

extern const unsigned char serialPortServiceUuid[SERIAL_PORT_SERVICE_UUID_LEN];
extern const unsigned char flowControlModeCharactUuid[CHARACT_UUID_SERIAL_LEN];
extern const unsigned char serialPortFifoCharactUuid[CHARACT_UUID_SERIAL_LEN];
extern const unsigned char creditsCharactUuid[CHARACT_UUID_SERIAL_LEN];

extern const unsigned char deviceIdServiceUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char systemIdCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char modelNumberCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char serialNumberCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char firmwareRevisionCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char hardwareRevisionCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char swRevisionCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char manufactNameCharactUuid[CHARACT_UUID_DEFAULT_LEN];
extern const unsigned char regCertCharactUuid[CHARACT_UUID_DEFAULT_LEN];

extern NSString* strFromServiceUUID(CBUUID *uuid);
extern NSString* strFromCharacteristicUUID(CBUUID *serviceUuid, CBUUID *charactUuid);
extern NSString* strFromCharacteristicValue(CBUUID *serviceUuid, CBUUID *uuid, NSData* value);
extern NSString* strFromCharacteristicProperties(CBCharacteristicProperties properties);

@interface BLEDefinitions : NSObject

@end
