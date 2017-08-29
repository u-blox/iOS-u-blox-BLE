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

#import "overviewViewController.h"

@interface overviewViewController ()

@end

@implementation overviewViewController
@synthesize accelerometerLabel, accelerometerXview, accelerometerYview, accelerometerZview;
@synthesize temperatureLabel, rssiLabel, batteryLabel, ledGreenSwitch, ledRedSwitch;
@synthesize modelScene, modelHeight, modelTop, modelButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    gyroXval = 0;
    gyroYval = 0;
    gyroZval = 0;
    accXval = 0;
    accYval = 0;
    accZval = 0;
    
    tempTimeVal = 0;
    
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/NINA-B112.obj"];
    
    
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    [scene.rootNode addChildNode:cameraNode];
    
    // place the camera
    cameraNode.position = SCNVector3Make(0, 0, 25);
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    lightNode.position = SCNVector3Make(0, 10, 10);
    [scene.rootNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // retrieve the ship node
    //SCNNode *ship = [scene.rootNode childNodeWithName:@"ship" recursively:YES];
    myObject = scene.rootNode.childNodes[0];
    
    SCNVector3 minV = SCNVector3Zero;
    SCNVector3 maxV = SCNVector3Zero;
    
    [myObject getBoundingBoxMin:&minV max:&maxV];
    
    // set the scene to the view
    modelScene.scene = scene;
    
    // allows the user to manipulate the camera
    modelScene.allowsCameraControl = YES;
    
    // show statistics such as fps and timing information
    //modelScene.showsStatistics = YES;
    
    // configure the view
    modelScene.backgroundColor = [UIColor blackColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralValue:)
                                                 name:@"peripheralValue"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peripheralRSSIUpdate:)
                                                 name:@"peripheralRSSIUpdate"
                                               object:nil];

    [self startup];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CBPeripheral *discPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_LEDRED notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_LEDGREEN notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_TEMPERATURE notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_BATTERY notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCRANGE notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCX notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCY notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCZ notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROX notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROY notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROZ notify:NO];
    [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_GYRO notify:NO];

    
}
- (void)startup
{
    temperatureLabel.text = @"";
    rssiLabel.text = @"";
    batteryLabel.text = @"";
    accelerometerLabel.text = @"";
    
    ledRedSwitch.on = NO;
    ledGreenSwitch.on = NO;
    //ledRedSwitch.enabled = NO;
    //ledGreenSwitch.enabled = NO;
    
    // Check if connected peripheral has gyro service
    CBPeripheral *currentPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    modelButton.hidden = YES;
    modelScene.hidden = YES;
    if(currentPeripheral != nil)
    {
        for(int i = 0; i < currentPeripheral.services.count;i++)
        {
            CBService *checkService = [currentPeripheral.services objectAtIndex:i];
            
            /*
            //if([[checkService.UUID data] isEqualToData:[[NSData alloc] initWithBytes:gyroServiceUuid length:2]])
            if([[checkService.UUID data] isEqualToData:[[NSData alloc] initWithBytes:accServiceUuid length:2]])
            {
                modelButton.hidden = NO;
                modelScene.hidden = NO;
                [modelButton setTitle:@"Accelerometer" forState:UIControlStateNormal];
            }
             */
            if([[checkService.UUID data] isEqualToData:[[NSData alloc] initWithBytes:deviceIdServiceUuid length:2]])
            {
                for(int j = 0;j < checkService.characteristics.count;j++)
                {
                    if((checkService.characteristics[j].UUID.data.length == CHARACT_UUID_DEFAULT_LEN) &&
                       (memcmp(checkService.characteristics[j].UUID.data.bytes, modelNumberCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
                    {
                        
                        [currentPeripheral readValueForCharacteristic:checkService.characteristics[j]];
                    }
                }
            }

            
        }
    }

    
    CGRect accRect = accelerometerXview.frame;
    accRect.size.width = 0;
    accelerometerXview.frame = accRect;
    accRect = accelerometerYview.frame;
    accRect.size.width = 0;
    accelerometerYview.frame = accRect;
    accRect = accelerometerZview.frame;
    accRect.size.width = 0;
    accelerometerZview.frame = accRect;
    
    if([[[ublox sharedInstance] currentPeripheralUUID] isEqualToString:@""])
    {
        self.navbarLabel.text = @"Not connected";
        
        self.navbarButton.hidden = YES;
    } else {
        CBPeripheral *discPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
        
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_LEDRED];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_LEDGREEN];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_TEMPERATURE];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_BATTERY];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCRANGE];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCX];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCY];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCZ];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROX];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROY];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROZ];
        [[ublox sharedInstance] readDataFromPeripheral:discPeripheral ubloxcharAct:UBLOX_GYRO];
        
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_LEDRED notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_LEDGREEN notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_TEMPERATURE notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_BATTERY notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCRANGE notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCX notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCY notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_ACCZ notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROX notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROY notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_GYROZ notify:YES];
        [[ublox sharedInstance] notifyPeripheral:discPeripheral ubloxcharAct:UBLOX_GYRO notify:YES];
        
        self.navbarLabel.text = discPeripheral.name;
        
        self.navbarButton.hidden = NO;
    }

}

- (void) peripheralRSSIUpdate:(NSNotification *) notification
{
    NSDictionary *dict = [notification userInfo];
    
    NSString *foundUUID = [dict objectForKey:@"UUID"];
    NSNumber *foundRSSI = [dict objectForKey:@"RSSI"];
    
    if([[[ublox sharedInstance] currentPeripheralUUID] isEqualToString:foundUUID])
    {
        rssiLabel.text = [NSString stringWithFormat:@"%@ dB", foundRSSI];
    }
}



- (void) peripheralValue:(NSNotification *) notification
{
    NSDictionary *dict = [notification userInfo];
    
    NSString *foundUUID = [dict objectForKey:@"UUID"];

    CBCharacteristic *foundCharact = [dict objectForKey:@"characteristic"];
    
    NSNumber *UBLOXcharacteristicNSNumber = [dict objectForKey:@"UBLOXcharacteristic"];
    int UBLOXcharacteristic = [UBLOXcharacteristicNSNumber intValue];
    
    char *p = (char*)foundCharact.value.bytes;
    
    CGRect screenRect = UIScreen.mainScreen.bounds;
    
    float accWidth = screenRect.size.width - 40;
    
    
    if((foundCharact.UUID.data.length == CHARACT_UUID_DEFAULT_LEN) &&
       (memcmp(foundCharact.UUID.data.bytes, modelNumberCharactUuid,CHARACT_UUID_DEFAULT_LEN) == 0))
    {
        NSString *modelName = [[NSString alloc] initWithCString:foundCharact.value.bytes encoding:NSUTF8StringEncoding];
        
        if([modelName hasPrefix:@"NINA-B1"])
        {
            modelButton.hidden = NO;
            modelScene.hidden = NO;
            [modelButton setTitle:@"Accelerometer" forState:UIControlStateNormal];
            
        }
        
    }
    
    
    if([[[ublox sharedInstance] currentPeripheralUUID] isEqualToString:foundUUID])
    {
        if(UBLOXcharacteristic == UBLOX_GYRO)
        {
            /*
             [0] = acc/gyro_x
             [1] = acc/gyro_y
             [2] = acc/gyro_z
             
             [3] = timestamp[24:16]
             [4] = timestamp[15:8]
             [5] = timestamp[7:0]
            */
            gyroXval = p[0];
            gyroYval = p[1];
            gyroZval = p[2];
            
            unsigned char *n = foundCharact.value.bytes;
            
            int timeValue = (n[3] << 16) | (n[4] << 8) | n[5];

            int diff = timeValue - tempTimeVal;
            tempTimeVal = timeValue;
            
            if(diff > 5000)
            {
                return;
            }
            
            float passedTime = (((float)diff)/1000000)*39;
            
            
            float angleRotX = (((float)gyroXval/64.0)*360)*passedTime;
            float angleRotY = (((float)gyroYval/64.0)*360)*passedTime;
            float angleRotZ = (((float)gyroZval/64.0)*360)*passedTime;
            
            SCNMatrix4 xAngle = SCNMatrix4MakeRotation([self degToRad:angleRotY], 1, 0, 0);  // Y
            SCNMatrix4 yAngle = SCNMatrix4MakeRotation([self degToRad:angleRotZ], 0, 1, 0);  // Z
            SCNMatrix4 zAngle = SCNMatrix4MakeRotation([self degToRad:angleRotX], 0, 0, 1); // X
            
            SCNMatrix4 rotationMatrix = SCNMatrix4Mult(SCNMatrix4Mult(xAngle, yAngle), zAngle);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                myObject.transform = SCNMatrix4Mult(rotationMatrix, myObject.transform);
            });
        }
        if(UBLOXcharacteristic == UBLOX_GYROX)
        {
            //NSInteger val = p[0];
        }
        
        if(UBLOXcharacteristic == UBLOX_ACCX)
        {
            NSInteger val = p[0] + 128;
            
            accXval = p[0];
            
            float accNewwidth = accWidth * ((float)val) / 256.0;
            
            CGRect accRect = accelerometerXview.frame;
            accRect.size.width = accNewwidth;
            accelerometerXview.frame = accRect;
        }
        if(UBLOXcharacteristic == UBLOX_ACCY)
        {
            NSInteger val = p[0] + 128;
            
            accYval = p[0];
            
            float accNewwidth = accWidth * ((float)val) / 256.0;

            CGRect accRect = accelerometerYview.frame;
            accRect.size.width = accNewwidth;
            accelerometerYview.frame = accRect;
        }
        if(UBLOXcharacteristic == UBLOX_ACCZ)
        {
            NSInteger val = p[0] + 128;
            
            accZval = p[0];
            
            float accNewwidth = accWidth * ((float)val) / 256.0;
            
            CGRect accRect = accelerometerZview.frame;
            accRect.size.width = accNewwidth;
            accelerometerZview.frame = accRect;            
        }
        if(UBLOXcharacteristic == UBLOX_ACCRANGE)
        {
            NSInteger range = (p[1] << 8) | p[0];
            
            self.accelerometerLabel.text = [NSString stringWithFormat:@"+-%ldG", (long)range];
        }
        if(UBLOXcharacteristic == UBLOX_TEMPERATURE)
        {
            self.temperatureLabel.text = [[NSString alloc] initWithFormat:@"%d% °C", p[0]];
        }
        if(UBLOXcharacteristic == UBLOX_BATTERY)
        {
            self.batteryLabel.text = [[NSString alloc] initWithFormat:@"%d%%", p[0]];
        }
        if(UBLOXcharacteristic == UBLOX_LEDRED)
        {
            self.ledRedSwitch.enabled = true;
            if(p[0] != 0)
            {
                self.ledRedSwitch.on = YES;
            } else {
                self.ledRedSwitch.on = NO;
            }
        }
        if(UBLOXcharacteristic == UBLOX_LEDGREEN)
        {
            self.ledGreenSwitch.enabled = true;
            if(p[0] != 0)
            {
                self.ledGreenSwitch.on = YES;
            } else {
                self.ledGreenSwitch.on = NO;
            }
        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) toggleRedLedSwitch: (id) UISwitch
{
    CBPeripheral *discPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    int writeValue = 0;

    if(self.ledRedSwitch.on)
    {
        writeValue = 1;
    }
    
    NSData *valueData = [NSData dataWithBytes:&writeValue length:1];
    
    [[ublox sharedInstance] writeDataToPeripheral: discPeripheral ubloxcharAct:UBLOX_LEDRED value:valueData];
}

- (IBAction) toggleGreenLedSwitch: (id) UISwitch
{
    CBPeripheral *discPeripheral = [[ublox sharedInstance] getCurrentPeripheral];
    
    int writeValue = 0;
    
    if(self.ledGreenSwitch.on)
    {
        writeValue = 1;
    }
    
    NSData *valueData = [NSData dataWithBytes:&writeValue length:1];
    
    [[ublox sharedInstance] writeDataToPeripheral: discPeripheral ubloxcharAct:UBLOX_LEDGREEN value:valueData];
}

- (IBAction) selectDevice: (id) UIButton
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Select device"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    for(int i = 0; i < [[ublox sharedInstance] discoveredPeripherals].count;i++)
    {
        NSMutableDictionary *thisPeripheralDict = [[[ublox sharedInstance] discoveredPeripherals] objectAtIndex:i];
        CBPeripheral *thisPeripheral = [thisPeripheralDict objectForKey:@"peripheral"];
        
        if(thisPeripheral.state == CBPeripheralStateConnected)
        {
            [alertController addAction:[UIAlertAction
                                        actionWithTitle:thisPeripheral.name
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                                        {
                                            [[ublox sharedInstance] setCurrentPeripheralUUID:thisPeripheral.identifier.UUIDString];
                                            
                                            [self startup];                                            
                                        }]];
        }
    }


    [alertController addAction:[UIAlertAction
                                actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                style:UIAlertActionStyleCancel
                                handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
}

-(float)degToRad: (float)deg
{
    return deg / 180 * (float)M_PI;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)pressModel:(id)sender {
    //myObject.eulerAngles = SCNVector3Make(0,0,0);
    [self calculateAngle];
}

- (IBAction)tapModel:(id)sender {
    
    
    int targetHeight = 0;
    int targetTop = 0;
    
    if(modelHeight.constant == 115)
    {
        targetHeight = self.view.bounds.size.height;
        targetTop = 0;
    } else {
        targetHeight = 115;
        targetTop = 180;
    }

    modelHeight.constant = targetHeight;
    modelTop.constant = targetTop;
    [modelScene setNeedsUpdateConstraints];
    [modelScene layoutIfNeeded];

    dispatch_async(dispatch_get_main_queue(), ^{
        myObject.eulerAngles = SCNVector3Make(myObject.eulerAngles.x+0.1f, myObject.eulerAngles.y, myObject.eulerAngles.z);
        
    });

}

- (IBAction)modelButtonSwitch:(id)sender {
    if(modelScene.hidden)
    {
        modelScene.hidden = NO;
        [modelButton setTitle:@"Accelerometer" forState:UIControlStateNormal];
    } else {
        modelScene.hidden = YES;
        [modelButton setTitle:@"3D" forState:UIControlStateNormal];
    }
}

-(void)calculateAngle
{
    float ax = -(float)accXval;
    float ay = (float)accYval;
    float az = (float)accZval;
    
    // PEKA NER
    float oX = 0;
    
    float oY = 0;
    
    float oZ = 0;
    
    
    if(accZval > 0) // PEKA UPP
    {
        oX = atan(ax/sqrt(ay*ay+az*az));
        
        oY = atan(ay/sqrt(ax*ax+az*az));
        
        oZ = atan(az/sqrt(ax*ax+ay*ay));
    } else { // PEKA NER
        oX = atan(-ax/sqrt(ay*ay+az*az));
        
        oY = atan(ay/sqrt(ax*ax+az*az));
        
        oZ = atan(az/sqrt(ax*ax+ay*ay));

        oX = oX + (M_PI);
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // pitch    yaw     roll
        myObject.eulerAngles = SCNVector3Make(oX, 0, oY);
        
    });
}

@end
