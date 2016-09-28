//
//  SerialPortManager.h
//  cB-OLS425
//
//  Created by Tomas Frisberg on 2013-10-28.
//  Copyright (c) 2013 Tomas Frisberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class SerialPortManager;

@protocol SerialPortManagerDelegate <NSObject>

-(void)serialPortManager:(SerialPortManager*)spm didDiscoverSerialPortAtIndex:(NSUInteger)index;

-(void)serialPortManager:(SerialPortManager *)spm didConnectSerialPortAtIndex:(NSUInteger)index;
-(void)serialPortManager:(SerialPortManager *)spm didFailToConnectSerialPortAtIndex:(NSUInteger)index;
-(void)serialPortManager:(SerialPortManager *)spm didDisconnectSerialPortAtIndex:(NSUInteger)index;

@end


@interface SerialPortManager : NSObject <CBCentralManagerDelegate>

@property (nonatomic, weak) id <SerialPortManagerDelegate> delegate;

@property (strong, nonatomic) NSMutableArray *serialPorts;

-(void)startSearch;
-(void)stopSearch;
-(void)clear;

-(BOOL)connectSerialPortAtIndex:(NSUInteger)index;
-(BOOL)disconnectSerialPortAtIndex:(NSUInteger)index;

-(void)enable;
-(void)disable;

@end
