//
//  overviewViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2015-03-31.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

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
    
    CBPeripheral *discPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_LEDRED notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_LEDGREEN notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_TEMPERATURE notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_BATTERY notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_ACCRANGE notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_ACCX notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_ACCY notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_ACCZ notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_GYROX notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_GYROY notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_GYROZ notify:NO];
    [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_GYRO notify:NO];

    
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
    CBPeripheral *currentPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
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
    
    if([[[olp425 sharedInstance] currentPeripheralUUID] isEqualToString:@""])
    {
        self.navbarLabel.text = @"Not connected";
        
        self.navbarButton.hidden = YES;
    } else {
        CBPeripheral *discPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
        
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_LEDRED];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_LEDGREEN];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_TEMPERATURE];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_BATTERY];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_ACCRANGE];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_ACCX];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_ACCY];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_ACCZ];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_GYROX];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_GYROY];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_GYROZ];
        [[olp425 sharedInstance] readDataFromPeripheral:discPeripheral olp425charAct:OLP425_GYRO];
        
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_LEDRED notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_LEDGREEN notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_TEMPERATURE notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_BATTERY notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_ACCRANGE notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_ACCX notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_ACCY notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_ACCZ notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_GYROX notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_GYROY notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_GYROZ notify:YES];
        [[olp425 sharedInstance] notifyPeripheral:discPeripheral olp425charAct:OLP425_GYRO notify:YES];
        
        self.navbarLabel.text = discPeripheral.name;
        
        self.navbarButton.hidden = NO;
    }

}

- (void) peripheralRSSIUpdate:(NSNotification *) notification
{
    NSDictionary *dict = [notification userInfo];
    
    NSString *foundUUID = [dict objectForKey:@"UUID"];
    NSNumber *foundRSSI = [dict objectForKey:@"RSSI"];
    
    if([[[olp425 sharedInstance] currentPeripheralUUID] isEqualToString:foundUUID])
    {
        rssiLabel.text = [NSString stringWithFormat:@"%@ dB", foundRSSI];
    }
}



- (void) peripheralValue:(NSNotification *) notification
{
    NSDictionary *dict = [notification userInfo];
    
    NSString *foundUUID = [dict objectForKey:@"UUID"];

    CBCharacteristic *foundCharact = [dict objectForKey:@"characteristic"];
    
    NSNumber *OLP425characteristicNSNumber = [dict objectForKey:@"OLP425characteristic"];
    int OLP425characteristic = [OLP425characteristicNSNumber intValue];
    
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
    
    
    if([[[olp425 sharedInstance] currentPeripheralUUID] isEqualToString:foundUUID])
    {
        if(OLP425characteristic == OLP425_GYRO)
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
        if(OLP425characteristic == OLP425_GYROX)
        {
            //NSInteger val = p[0];
        }
        
        if(OLP425characteristic == OLP425_ACCX)
        {
            NSInteger val = p[0] + 128;
            
            accXval = p[0];
            
            float accNewwidth = accWidth * ((float)val) / 256.0;
            
            CGRect accRect = accelerometerXview.frame;
            accRect.size.width = accNewwidth;
            accelerometerXview.frame = accRect;
        }
        if(OLP425characteristic == OLP425_ACCY)
        {
            NSInteger val = p[0] + 128;
            
            accYval = p[0];
            
            float accNewwidth = accWidth * ((float)val) / 256.0;

            CGRect accRect = accelerometerYview.frame;
            accRect.size.width = accNewwidth;
            accelerometerYview.frame = accRect;
        }
        if(OLP425characteristic == OLP425_ACCZ)
        {
            NSInteger val = p[0] + 128;
            
            accZval = p[0];
            
            float accNewwidth = accWidth * ((float)val) / 256.0;
            
            CGRect accRect = accelerometerZview.frame;
            accRect.size.width = accNewwidth;
            accelerometerZview.frame = accRect;            
        }
        if(OLP425characteristic == OLP425_ACCRANGE)
        {
            NSInteger range = (p[1] << 8) | p[0];
            
            self.accelerometerLabel.text = [NSString stringWithFormat:@"+-%ldG", (long)range];
        }
        if(OLP425characteristic == OLP425_TEMPERATURE)
        {
            self.temperatureLabel.text = [[NSString alloc] initWithFormat:@"%d% °C", p[0]];
        }
        if(OLP425characteristic == OLP425_BATTERY)
        {
            self.batteryLabel.text = [[NSString alloc] initWithFormat:@"%d%%", p[0]];
        }
        if(OLP425characteristic == OLP425_LEDRED)
        {
            self.ledRedSwitch.enabled = true;
            if(p[0] != 0)
            {
                self.ledRedSwitch.on = YES;
            } else {
                self.ledRedSwitch.on = NO;
            }
        }
        if(OLP425characteristic == OLP425_LEDGREEN)
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
    CBPeripheral *discPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    int writeValue = 0;

    if(self.ledRedSwitch.on)
    {
        writeValue = 1;
    }
    
    NSData *valueData = [NSData dataWithBytes:&writeValue length:1];
    
    [[olp425 sharedInstance] writeDataToPeripheral: discPeripheral olp425charAct:OLP425_LEDRED value:valueData];
}

- (IBAction) toggleGreenLedSwitch: (id) UISwitch
{
    CBPeripheral *discPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    int writeValue = 0;
    
    if(self.ledGreenSwitch.on)
    {
        writeValue = 1;
    }
    
    NSData *valueData = [NSData dataWithBytes:&writeValue length:1];
    
    [[olp425 sharedInstance] writeDataToPeripheral: discPeripheral olp425charAct:OLP425_LEDGREEN value:valueData];
}

- (IBAction) selectDevice: (id) UIButton
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"Select device"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    for(int i = 0; i < [[olp425 sharedInstance] discoveredPeripherals].count;i++)
    {
        NSMutableDictionary *thisPeripheralDict = [[[olp425 sharedInstance] discoveredPeripherals] objectAtIndex:i];
        CBPeripheral *thisPeripheral = [thisPeripheralDict objectForKey:@"peripheral"];
        
        if(thisPeripheral.state == CBPeripheralStateConnected)
        {
            [alertController addAction:[UIAlertAction
                                        actionWithTitle:thisPeripheral.name
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action)
                                        {
                                            [[olp425 sharedInstance] setCurrentPeripheralUUID:thisPeripheral.identifier.UUIDString];
                                            
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
