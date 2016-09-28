//
//  SerialPortManager.m
//  cB-OLS425
//
//  Created by Tomas Frisberg on 2013-10-28.
//  Copyright (c) 2013 Tomas Frisberg. All rights reserved.
//

#import "SerialPortManager.h"
#import "SerialPort.h"

@implementation SerialPortManager
{
    CBCentralManager* _centralManager;
    
    dispatch_queue_t _queue;
    
    BOOL _startScan;
}

#pragma mark - Public Methods

-(SerialPortManager*)init
{
    _serialPorts = [[NSMutableArray alloc] init];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:TRUE] forKey:CBCentralManagerOptionShowPowerAlertKey];
    
    //_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:dictionary];

    _queue = dispatch_queue_create("com.connectblue.ble", DISPATCH_QUEUE_SERIAL);
    //_queue = nil;
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:_queue options:dictionary];
    
    _startScan = FALSE;
    
    return self;
}

-(void)startSearch
{
    if(_centralManager.state == CBCentralManagerStatePoweredOn)
    {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        
        NSArray	*uuidArray	= [NSArray arrayWithObjects:[CBUUID UUIDWithString	:@"2456e1b9-26e2-8f83-e744-f34f01e9d701"], nil];
        
        [_centralManager scanForPeripheralsWithServices:uuidArray options:dictionary];
    }
    else
    {
        _startScan = TRUE;
    }
}

-(void)stopSearch
{
    if(_centralManager.state == CBCentralManagerStatePoweredOn)
    {
        [_centralManager stopScan];
    }
}

-(void)clear
{
    NSMutableArray* tmpArr = [[NSMutableArray alloc] init];
    
    for(SerialPort* sp in _serialPorts)
    {
        if(sp.peripheral.state != CBPeripheralStateDisconnected)
        {
            [tmpArr addObject:sp];
            
            [_serialPorts removeObject:sp];
        }
    }
    
    _serialPorts = tmpArr;
}

-(BOOL)connectSerialPortAtIndex:(NSUInteger)index
{
    BOOL result = FALSE;
    
    if((_centralManager.state == CBCentralManagerStatePoweredOn) &&
       (index < _serialPorts.count))
    {
        SerialPort* sp = _serialPorts[index];
        
        if(sp.peripheral.state == CBPeripheralStateDisconnected)
        {
            [_centralManager connectPeripheral:sp.peripheral options:nil];
            
            result = TRUE;
        }
    }
    
    return result;
}

-(BOOL)disconnectSerialPortAtIndex:(NSUInteger)index
{
    BOOL result = FALSE;
    
    if((_centralManager.state == CBCentralManagerStatePoweredOn) &&
       (index < _serialPorts.count))
    {
        SerialPort* sp = _serialPorts[index];
        
        if((sp.peripheral.state == CBPeripheralStateConnected) ||
           (sp.peripheral.state == CBPeripheralStateConnecting))
        {
            [_centralManager cancelPeripheralConnection:sp.peripheral];
            
            result = TRUE;
        }
    }
    
    return result;
}

-(void)enable
{
    for(SerialPort* sp in _serialPorts)
    {
        [sp enable];
    }
}

-(void)disable
{
    for(SerialPort* sp in _serialPorts)
    {
        [sp disable];
    }
}

#pragma mark - CBCentralManager Protocol

- (void)centralManager:(CBCentralManager *)cm didDiscoverPeripheral:(CBPeripheral *)periph advertisementData:(NSDictionary *)advData RSSI:(NSNumber *)rssi
{
    NSUInteger index = _serialPorts.count;
    
    for(int i = 0; (i < _serialPorts.count) && (index == _serialPorts.count); i++)
    {
        SerialPort* sp = _serialPorts[i];
        
        if(sp.peripheral == periph)
        {
            index = i;
        }
    }
    
    SerialPort* sp;
    
    if(index < _serialPorts.count)
    {
        sp = _serialPorts[index];
    }
    else
    {
        // New serial port
        
        sp = [[SerialPort alloc] initWithPeripheral:periph andQueue:_queue];
        
        [_serialPorts addObject:sp];
    }
    
    sp.rssi = rssi;
    
    //[_delegate serialPortManager:self didDiscoverSerialPortAtIndex:index];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate serialPortManager:self didDiscoverSerialPortAtIndex:index];
    });
}

- (void)centralManager:(CBCentralManager *)cm didConnectPeripheral:(CBPeripheral *)periph
{
    NSUInteger index = _serialPorts.count;
    
    for(int i = 0; (i < _serialPorts.count) && (index == _serialPorts.count); i++)
    {
        SerialPort* sp = _serialPorts[i];
        
        if(sp.peripheral == periph)
        {
            index = i;
        }
    }
    
    if(index < _serialPorts.count)
    {
        //[_delegate serialPortManager:self didConnectSerialPortAtIndex:index];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate serialPortManager:self didConnectSerialPortAtIndex:index];
        });
    }
}

- (void)centralManager:(CBCentralManager *)cm didFailToConnectPeripheral:(CBPeripheral *)periph error:(NSError *)error
{
    NSUInteger index = _serialPorts.count;
    
    for(int i = 0; (i < _serialPorts.count) && (index == _serialPorts.count); i++)
    {
        SerialPort* sp = _serialPorts[i];
        
        if(sp.peripheral == periph)
        {
            index = i;
        }
    }
    
    if(index < _serialPorts.count)
    {
        //[_delegate serialPortManager:self didFailToConnectSerialPortAtIndex:index];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate serialPortManager:self didFailToConnectSerialPortAtIndex:index];
        });
    }
    
}

- (void)centralManager:(CBCentralManager *)cm didDisconnectPeripheral:(CBPeripheral *)periph error:(NSError *)error
{
    NSUInteger index = _serialPorts.count;
    
    for(int i = 0; (i < _serialPorts.count) && (index == _serialPorts.count); i++)
    {
        SerialPort* sp = _serialPorts[i];
        
        if(sp.peripheral == periph)
        {
            index = i;
            
            [sp leDisconnected];
        }
    }
    
    if(index < _serialPorts.count)
    {
        //[_delegate serialPortManager:self didDisconnectSerialPortAtIndex:index];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate serialPortManager:self didDisconnectSerialPortAtIndex:index];
        });
    }
}

- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)cm
{
    if((_centralManager.state == CBCentralManagerStatePoweredOn) &&
       (_startScan == TRUE))
    {
        _startScan = FALSE;
        
        [self startSearch];
    }
}


@end
