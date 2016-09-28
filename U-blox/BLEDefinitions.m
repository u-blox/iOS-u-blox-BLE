//
//  BLEDefinitions.m
//  BLEDemo
//
//  Created by Tomas Henriksson on 1/18/12.
//  Copyright (c) 2012 connectBlue. All rights reserved.
//

#import "BLEDefinitions.h"

//const unsigned char genericAccessServiceUuid[SERVICE_UUID_DEFAULT_LEN]      = {0x18, 0x00};
//const unsigned char genericAttributeServiceUuid[SERVICE_UUID_DEFAULT_LEN]   = {0x18, 0x01};
const unsigned char immediateAlertServiceUuid[SERVICE_UUID_DEFAULT_LEN]     = {0x18, 0x02};
const unsigned char linkLossServiceUuid[SERVICE_UUID_DEFAULT_LEN]           = {0x18, 0x03};
const unsigned char txPowerServiceUuid[SERVICE_UUID_DEFAULT_LEN]            = {0x18, 0x04};
const unsigned char currentTimeServiceUuid[SERVICE_UUID_DEFAULT_LEN]        = {0x18, 0x05};
const unsigned char refTimeUpdateServiceUuid[SERVICE_UUID_DEFAULT_LEN]      = {0x18, 0x06};
const unsigned char nextDstChangeServiceUuid[SERVICE_UUID_DEFAULT_LEN]      = {0x18, 0x07};
const unsigned char glucoseServiceUuid[SERVICE_UUID_DEFAULT_LEN]            = {0x18, 0x08};
const unsigned char healthThermServiceUuid[SERVICE_UUID_DEFAULT_LEN]        = {0x18, 0x09};
const unsigned char deviceIdServiceUuid[SERVICE_UUID_DEFAULT_LEN]           = {0x18, 0x0a};
const unsigned char networkAvailServiceUuid[SERVICE_UUID_DEFAULT_LEN]       = {0x18, 0x0b};
//const unsigned char xxxServiceUuid[SERVICE_UUID_DEFAULT_LEN]                = {0x18, 0x0c};
const unsigned char heartRateServiceUuid[SERVICE_UUID_DEFAULT_LEN]          = {0x18, 0x0d};
const unsigned char phoneAlertStatusServiceUuid[SERVICE_UUID_DEFAULT_LEN]   = {0x18, 0x0e};
const unsigned char batteryServiceUuid[SERVICE_UUID_DEFAULT_LEN]            = {0x18, 0x0f};
const unsigned char bloodPressureServiceUuid[SERVICE_UUID_DEFAULT_LEN]      = {0x18, 0x10};
const unsigned char alertNotificationServiceUuid[SERVICE_UUID_DEFAULT_LEN]  = {0x18, 0x11};
const unsigned char humanIntDeviceServiceUuid[SERVICE_UUID_DEFAULT_LEN]     = {0x18, 0x12};
const unsigned char scanParametersServiceUuid[SERVICE_UUID_DEFAULT_LEN]     = {0x18, 0x13};
const unsigned char runSpeedCadenceServiceUuid[SERVICE_UUID_DEFAULT_LEN]    = {0x18, 0x14};

const unsigned char accServiceUuid[SERVICE_UUID_DEFAULT_LEN]       = {0xff, 0xa0};
const unsigned char gyroServiceUuid[SERVICE_UUID_DEFAULT_LEN]       = {0xff, 0xb0};
const unsigned char tempServiceUuid[SERVICE_UUID_DEFAULT_LEN]      = {0xff, 0xe0};
const unsigned char ledServiceUuid[SERVICE_UUID_DEFAULT_LEN]       = {0xff, 0xd0};

const unsigned char   serialPortServiceUuid[SERIAL_PORT_SERVICE_UUID_LEN] = {
    0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83,
    0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x01};


const unsigned char batteryLevelCharactUuid[CHARACT_UUID_DEFAULT_LEN]       = {0x2a, 0x19};
const unsigned char systemIdCharactUuid[CHARACT_UUID_DEFAULT_LEN]           = {0x2a, 0x23};
const unsigned char modelNumberCharactUuid[CHARACT_UUID_DEFAULT_LEN]        = {0x2a, 0x24};
const unsigned char serialNumberCharactUuid[CHARACT_UUID_DEFAULT_LEN]       = {0x2a, 0x25};
const unsigned char firmwareRevisionCharactUuid[CHARACT_UUID_DEFAULT_LEN]   = {0x2a, 0x26};
const unsigned char hardwareRevisionCharactUuid[CHARACT_UUID_DEFAULT_LEN]   = {0x2a, 0x27};
const unsigned char swRevisionCharactUuid[CHARACT_UUID_DEFAULT_LEN]         = {0x2a, 0x28};
const unsigned char manufactNameCharactUuid[CHARACT_UUID_DEFAULT_LEN]       = {0x2a, 0x29};
const unsigned char regCertCharactUuid[CHARACT_UUID_DEFAULT_LEN]            = {0x2a, 0x2a};

const unsigned char accRangeCharactUuid[CHARACT_UUID_DEFAULT_LEN]           = {0xff, 0xa2};
const unsigned char accXCharactUuid[CHARACT_UUID_DEFAULT_LEN]               = {0xff, 0xa3};
const unsigned char accYCharactUuid[CHARACT_UUID_DEFAULT_LEN]               = {0xff, 0xa4};
const unsigned char accZCharactUuid[CHARACT_UUID_DEFAULT_LEN]               = {0xff, 0xa5};

const unsigned char gyroXCharactUuid[CHARACT_UUID_DEFAULT_LEN]               = {0xff, 0xb3};
const unsigned char gyroYCharactUuid[CHARACT_UUID_DEFAULT_LEN]               = {0xff, 0xb4};
const unsigned char gyroZCharactUuid[CHARACT_UUID_DEFAULT_LEN]               = {0xff, 0xb5};
const unsigned char gyroCharactUuid[CHARACT_UUID_DEFAULT_LEN]                = {0xff, 0xb6};

const unsigned char tempValueCharactUuid[CHARACT_UUID_DEFAULT_LEN]          = {0xff, 0xe1};

const unsigned char redLedCharactUuid[CHARACT_UUID_DEFAULT_LEN]             = {0xff, 0xd1};
const unsigned char greenLedCharactUuid[CHARACT_UUID_DEFAULT_LEN]           = {0xff, 0xd2};
const unsigned char blueLedCharactUuid[CHARACT_UUID_DEFAULT_LEN]           = {0xff, 0xd3};
const unsigned char rgbLedCharactUuid[CHARACT_UUID_DEFAULT_LEN]           = {0xff, 0xd4};

const unsigned char flowControlModeCharactUuid[CHARACT_UUID_SERIAL_LEN] = {
    0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83,
    0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x02};

const unsigned char serialPortFifoCharactUuid[CHARACT_UUID_SERIAL_LEN] = {
    0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83,
    0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x03};

const unsigned char creditsCharactUuid[CHARACT_UUID_SERIAL_LEN] = {
    0x24, 0x56, 0xe1, 0xb9, 0x26, 0xe2, 0x8f, 0x83,
    0xe7, 0x44, 0xf3, 0x4f, 0x01, 0xe9, 0xd7, 0x04};


NSString* strFromServiceUUID(CBUUID *uuid)
{
    NSString*       str;
    
    if((uuid.data.length == SERIAL_PORT_SERVICE_UUID_LEN) &&
            (memcmp(uuid.data.bytes, serialPortServiceUuid, SERIAL_PORT_SERVICE_UUID_LEN) == 0))
    {
        str = @"Serial Port";
    }
    else if( (uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, accServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Accelerometer";
    }
    else if( (uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, gyroServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Gyroscope";
    }
    else if( (uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
             (memcmp(uuid.data.bytes, tempServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Temperature";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, ledServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"LED";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, immediateAlertServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Intermediate Alert";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, linkLossServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Link Loss";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, txPowerServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Tx Power";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, currentTimeServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Current Time";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, refTimeUpdateServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Reference Time Update";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, nextDstChangeServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Next DST Change";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, glucoseServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Glucose";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, healthThermServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Health Thermometer";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, deviceIdServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Device Information";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, networkAvailServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Network Availability";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, heartRateServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Heart Rate";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, phoneAlertStatusServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Phone Alert Status";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, batteryServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Battery";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, bloodPressureServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Blood Pressure";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, alertNotificationServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Alert Notification";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, humanIntDeviceServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Human Interface Device";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, scanParametersServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Scan Parameters";
    }
    else if((uuid.data.length == SERVICE_UUID_DEFAULT_LEN) &&
            (memcmp(uuid.data.bytes, runSpeedCadenceServiceUuid, SERVICE_UUID_DEFAULT_LEN) == 0))
    {
        str = @"Running Speed and Cadence";
    }
    else
    {
        str = [[NSString alloc] initWithFormat:@"%@", uuid];
    }
    
    return str;
}


NSString* strFromCharacteristicUUID(CBUUID *serviceUuid, CBUUID *charactUuid)
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
           (memcmp(charactUuid.data.bytes, gyroXCharactUuid, CHARACT_UUID_DEFAULT_LEN) == 0))
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

NSString* strFromCharacteristicValue(CBUUID *serviceUuid, CBUUID *charactUuid, NSData* value)
{
    NSString* str = nil;

    if((value.bytes != nil) && (value.length > 0) &&
       (charactUuid.data.length == CHARACT_UUID_DEFAULT_LEN) &&
       ((memcmp(charactUuid.data.bytes, modelNumberCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0) ||
        (memcmp(charactUuid.data.bytes, serialNumberCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0) ||
        (memcmp(charactUuid.data.bytes, firmwareRevisionCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0) ||
        (memcmp(charactUuid.data.bytes, hardwareRevisionCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0) ||
        (memcmp(charactUuid.data.bytes, swRevisionCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0) ||
        (memcmp(charactUuid.data.bytes, manufactNameCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0)))
    {
        str = [[NSString alloc] initWithCString:value.bytes encoding:NSUTF8StringEncoding];
    }
    
    if(str == nil)
        str = [value description];
    
    return str;
}

NSString* strFromCharacteristicProperties(CBCharacteristicProperties properties)
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

@implementation BLEDefinitions

@end
