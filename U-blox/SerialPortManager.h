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
