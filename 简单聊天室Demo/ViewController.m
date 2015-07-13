//
//  ViewController.m
//  简单聊天室Demo
//
//  Created by 胡晓桥 on 15/7/13.
//  Copyright (c) 2015年 胡晓桥. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<NSStreamDelegate,UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate>
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
}
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomHeight;
@property (nonatomic, strong) NSMutableArray *msgArr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KBWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(KBWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (NSMutableArray *)msgArr
{
    if (!_msgArr) {
        _msgArr = [NSMutableArray array];
    }
    return _msgArr;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.msgArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = self.msgArr[indexPath.row];
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

- (void)KBWillShow:(NSNotification *)noti
{
    CGFloat kbHeight = [noti.userInfo[@"UIKeyboardBoundsUserInfoKey"] CGRectValue].size.height;
    self.bottomHeight.constant = kbHeight;
}

- (void)KBWillHide:(NSNotification *)noti
{
    self.bottomHeight.constant = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}

//连接服务器
- (IBAction)clickToConnectSever:(id)sender {
    
    NSString *host = @"127.0.0.1";
    int port = 12345;
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    
    _inputStream = (__bridge NSInputStream *)(readStream);
    
    _outputStream = (__bridge NSOutputStream *)(writeStream);
    
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [_inputStream open];
    [_outputStream open];
    
}

#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode;
{
    //NSLog(@"%@",[NSThread currentThread]);
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            NSLog(@"成功建立连接！");
            break;
            case NSStreamEventHasBytesAvailable:
            [self readMsg];
            NSLog(@"读到数据");
            break;
            case NSStreamEventHasSpaceAvailable:
            NSLog(@"可以发送数据");
            break;
            case NSStreamEventErrorOccurred:
            NSLog(@"发生错误，连接失败");
            break;
            case NSStreamEventEndEncountered:
            NSLog(@"连接中断");
            break;
        default:
            break;
    }
    
}

- (void)readMsg
{
    uint8_t buf[1024];
   NSInteger len = [_inputStream read:buf maxLength:sizeof(buf)];
    
    if (len > 0) {
        NSString *receiveStr = [[NSString alloc] initWithBytes:buf length:len encoding:NSUTF8StringEncoding];
        
        NSLog(@"%@",receiveStr);
        [self.msgArr addObject:receiveStr];
        [self.tableView reloadData];
    }
    
}

//登录
- (IBAction)clickToLogin:(id)sender {
    
    NSString *loginStr = @"iam:zhangshan";
    [self sendMsg:loginStr];
}

- (void)sendMsg:(NSString *)str
{
    NSData *sendData = [str dataUsingEncoding:NSUTF8StringEncoding];
    [_outputStream write:sendData.bytes maxLength:sendData.length];
}

- (IBAction)sendBtn:(id)sender {
    
    if (_textField.text.length > 0) {
        [self sendMsg:[@"msg:" stringByAppendingString:_textField.text]];
       
        _textField.text = @"";
    }
    
    [self.view endEditing:YES];
}

@end
