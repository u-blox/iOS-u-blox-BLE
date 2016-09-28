//
//  chatViewController.m
//  U-blox
//
//  Created by Bill Martensson on 2015-04-13.
//  Copyright (c) 2015 U-blox. All rights reserved.
//

#import "chatViewController.h"

@interface chatViewController ()

@end

@implementation chatViewController
{
    NSMutableArray *messages;
}
@synthesize navbarLabel, navbarButton, tableview, messageTextfield, messageView, messageViewDistance, sendButton;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableview.rowHeight = UITableViewAutomaticDimension;
    self.tableview.estimatedRowHeight = 44.0; // set to whatever your "average" cell height is
    
    messages = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    CBPeripheral *currentPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    messageTextfield.enabled = NO;
    messageTextfield.placeholder = @"No serial service";
    sendButton.enabled = NO;
    
    if(currentPeripheral != nil)
    {
        for(int i = 0; i < currentPeripheral.services.count;i++)
        {
            CBService *checkService = [currentPeripheral.services objectAtIndex:i];
            
            //if([[checkService.UUID data] isEqualToData:[[NSData alloc] initWithBytes:gyroServiceUuid length:2]])
            if([[checkService.UUID data] isEqualToData:[[NSData alloc] initWithBytes:serialPortServiceUuid length:16]])
            {
                messageTextfield.enabled = YES;
                messageTextfield.placeholder = @"Message";
                sendButton.enabled = YES;
            }
            
        }
    }
    
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];


    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(serialportMessage:)
                                                 name:@"serialportMessage"
                                               object:nil];

    
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[olp425 sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            [sp open];
        }
    }
    
    messages = [[NSMutableArray alloc] init];
    [tableview reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    for(SerialPort* sp in [[olp425 sharedInstance] serialPorts])
    {
        if([sp.peripheral.identifier.UUIDString isEqualToString:thisPeripheral.identifier.UUIDString])
        {
            [sp close];
        }
    }
    
    
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"serialportMessage"
                                                  object:nil];
    
    
}

- (void) serialportMessage:(NSNotification *) notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dict = [notification userInfo];
        
        NSString *messagePeripheralUUID = [dict objectForKey:@"UUID"];
        NSString *messageText = [dict objectForKey:@"message"];
        NSString *writeState = [dict objectForKey:@"writestate"];
        
        if([[[olp425 sharedInstance] getCurrentUUID] isEqualToString:messagePeripheralUUID])
        {
            NSDateFormatter *format = [[NSDateFormatter alloc] init];
            [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            
            NSDate *now = [[NSDate alloc] init];
            
            NSString *dateString = [format stringFromDate:now];
            
            if([writeState isEqualToString:@"read"])
            {
                NSDictionary *message = [[NSDictionary alloc] initWithObjectsAndKeys: [[olp425 sharedInstance] getCurrentPeripheral].name, @"name", messageText, @"message", dateString, @"datetext", nil];
                
                [messages addObject:message];
            } else {
                NSDictionary *message = [[NSDictionary alloc] initWithObjectsAndKeys: @"", @"name", messageText, @"message", dateString, @"datetext", nil];
                
                [messages addObject:message];
            }
            
            [tableview reloadData];
            [self performSelector:@selector(scrollToBottom) withObject:self afterDelay:0.5 ];
            //[tableview setContentOffset:CGPointMake(0, tableview.contentSize.height) animated:YES];
            
            
        }
    });
}

- (void) scrollToBottom
{
    if (messages.count > 0)
    {
        [tableview scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:messages.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)n
{
    messageViewDistance.constant = 0;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)keyboardWillShow:(NSNotification *)n
{
    NSDictionary* userInfo = [n userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    messageViewDistance.constant = keyboardSize.height;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"chat";
    
    chatTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NSDictionary *currentMessage = [messages objectAtIndex:indexPath.row];
    
    cell.userFromLabel.text = @"";
    cell.userToLabel.text = @"";
    cell.dateFromLabel.text = @"";
    cell.dateToLabel.text = @"";
    cell.messageFromLabel.text = @"";
    cell.messageToLabel.text = @"";
    
    cell.imageFrom.hidden = YES;
    cell.imageTo.hidden = YES;
    
    cell.messageFromView.hidden = YES;
    cell.messageToView.hidden = YES;
    
    
    
    if([[currentMessage objectForKey:@"name"] isEqualToString:@""])
    {
        cell.userFromLabel.text = @"Me";
        cell.dateFromLabel.text = [currentMessage objectForKey:@"datetext"];
        cell.messageFromLabel.text = [currentMessage objectForKey:@"message"];
        cell.imageFrom.hidden = NO;
        cell.messageFromView.hidden = NO;

    } else {
        cell.userToLabel.text =[currentMessage objectForKey:@"name"];
        cell.dateToLabel.text = [currentMessage objectForKey:@"datetext"];
        cell.messageToLabel.text = [currentMessage objectForKey:@"message"];
        cell.imageTo.hidden = NO;
        cell.messageToView.hidden = NO;

    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *currentMessage = [messages objectAtIndex:indexPath.row];

    NSString *textToMeasure = [currentMessage objectForKey:@"message"];
    
    CGRect screenRect = UIScreen.mainScreen.bounds;
    float width = screenRect.size.width - 118;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:14]};
    // NSString class method: boundingRectWithSize:options:attributes:context is
    // available only on ios7.0 sdk.
    CGRect rect = [textToMeasure boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes
                                              context:nil];
    
    return 80-5+rect.size.height;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    
    [self doSendMessage];
    
    return YES;
}

- (IBAction) sendMessage: (id) UIButton
{
    [self.view endEditing:YES];
    [self doSendMessage];
}

-(void) doSendMessage
{
    NSString *textToSend = messageTextfield.text;
    
    messageTextfield.text = @"";
    
    CBPeripheral *thisPeripheral = [[olp425 sharedInstance] getCurrentPeripheral];
    
    [[olp425 sharedInstance] serialSendMessageToPeripheralUUID:thisPeripheral.identifier.UUIDString message:textToSend];

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
