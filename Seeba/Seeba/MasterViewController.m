//
//  MasterViewController.m
//  Seeba
//
//  Created by 大嶺 卓矢 on 2013/10/22.
//  Copyright (c) 2013年 大嶺 卓矢. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"

#import "GTMOAuthAuthentication.h"
#import "GTMOAuthViewControllerTouch.h"


@interface MasterViewController () {
}
@end


@implementation MasterViewController{

    // OAuth認証オブジェクト
    GTMOAuthAuthentication *auth_;
    
    // 表示中ツイート情報
    NSArray *timelineStatuses_;
    
}


// デフォルトのタイムライン処理表示
- (void)asyncShowHomeTimeline
{
    [self fetchGetHomeTimeline];
 
/******* 追 記 *****/
    NSTimer *TimerSwingObject = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                                 target:self
                                                               selector:@selector(StreamingTL:)
                                                               userInfo:nil
                                                                repeats:YES];
    
}


//自動更新するために呼び出し続ける
- (void) StreamingTL: (NSTimer *)timer {
    
        [self fetchGetHomeTimeline];
}


// タイムライン (home_timeline) 取得
- (void)fetchGetHomeTimeline
{
    
    // 要求を準備
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    // 非同期通信による取得開始
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(homeTimelineFetcher:finishedWithData:error:)];
    
    
    // テーブルを更新
    [self.tableView reloadData];
    
}


// タイムライン (home_timeline) 取得応答時
- (void)homeTimelineFetcher:(GTMHTTPFetcher *)fetcher
           finishedWithData:(NSData *)data
                      error:(NSError *)error

{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    
    // タイムライン取得成功
    // JSONデータをパース
    NSError *jsonError = nil;
    NSArray *statuses = [NSJSONSerialization JSONObjectWithData:data
                                                        options:0
                                                          error:&jsonError];
    
    // JSONデータのパースエラー
    if (statuses == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    
    // データを保持
    timelineStatuses_ = statuses;
    
    // テーブルを更新
    [self.tableView reloadData];

    
}


- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}


// 認証エラー表示AlertViewタグ
static const int kMyAlertViewTagAuthenticationError = 1;

// 認証処理が完了した場合の処理
- (void)authViewContoller:(GTMOAuthViewControllerTouch *)viewContoller
           finishWithAuth:(GTMOAuthAuthentication *)auth
                    error:(NSError *)error
{
    if (error != nil) {
        // 認証失敗
        NSLog(@"Authentication error: %d.", error.code);
        UIAlertView *alertView;
        alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Authentication failed."
                                              delegate:self
                                     cancelButtonTitle:@"Confirm"
                                     otherButtonTitles:nil];
        alertView.tag = kMyAlertViewTagAuthenticationError;
        [alertView show];
    } else {
        // 認証成功
        NSLog(@"Authentication succeeded.");
        // タイムライン表示
        [self asyncShowHomeTimeline];
    }
}

// UIAlertViewが閉じられた時
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // 認証失敗通知AlertViewが閉じられた場合
    if (alertView.tag == kMyAlertViewTagAuthenticationError) {
        // 再度認証
        [self asyncSignIn];
    }
}








// KeyChain登録サービス名
static NSString *const kKeychainAppServiceName = @"si-ba";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    // GTMOAuthAuthenticationインスタンス生成
    // ※自分の登録アプリの Consumer Key と Consumer Secret に書き換えてください
    NSString *consumerKey = @"2tb4YeEFfV7LtUQk3s7AQw";
    NSString *consumerSecret = @"38To4tIdT71q0lYLuxkhXeF4qJcsGQ6eH1H3xcv79U";
    auth_ = [[GTMOAuthAuthentication alloc]
             initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
             consumerKey:consumerKey
             privateKey:consumerSecret];
    
    // 既にOAuth認証済みであればKeyChainから認証情報を読み込む
    BOOL authorized = [GTMOAuthViewControllerTouch
                       authorizeFromKeychainForName:kKeychainAppServiceName
                       authentication:auth_];
    if (authorized) {
        // 認証済みの場合はタイムライン更新
        [self asyncShowHomeTimeline];
    } else {
        // 未認証の場合は認証処理を実施
        [self asyncSignIn];
    }

}


// 認証処理
- (void)asyncSignIn
{
    NSString *requestTokenURL = @"https://api.twitter.com/oauth/request_token";
    NSString *accessTokenURL = @"https://api.twitter.com/oauth/access_token";
    NSString *authorizeURL = @"https://api.twitter.com/oauth/authorize";
    
    NSString *keychainAppServiceName = @"si-ba";
    
    auth_.serviceProvider = @"Twitter";
    auth_.callback = @"http://www.example.com/OAuthCallback";
    
    GTMOAuthViewControllerTouch *viewController;
    viewController = [[GTMOAuthViewControllerTouch alloc]
                      initWithScope:nil
                      language:nil
                      requestTokenURL:[NSURL URLWithString:requestTokenURL]
                      authorizeTokenURL:[NSURL URLWithString:authorizeURL]
                      accessTokenURL:[NSURL URLWithString:accessTokenURL]
                      authentication:auth_
                      appServiceName:keychainAppServiceName
                      delegate:self
                      finishedSelector:@selector(authViewContoller:finishWithAuth:error:)];
    
    [[self navigationController] pushViewController:viewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table View



- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// テーブルのセクション数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// テーブルの行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [timelineStatuses_ count];
}

// 指定位置に挿入されるセルの要求
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [timelineStatuses_ objectAtIndex:indexPath.row];
    
    // ツイート本文を表示
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont systemFontOfSize:12];
    cell.textLabel.text = [status objectForKey:@"text"];
    
    // ユーザ情報から screen_name を取り出して表示
    NSDictionary *user = [status objectForKey:@"user"];
    cell.detailTextLabel.text = [user objectForKey:@"screen_name"];
    
    return cell;
}

// 指定位置の行で使用する高さの要求
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [timelineStatuses_ objectAtIndex:indexPath.row];
    
    // ツイート本文をもとにセルの高さを決定
    NSString *content = [status objectForKey:@"text"];
    CGSize labelSize = [content sizeWithFont:[UIFont systemFontOfSize:12]
                           constrainedToSize:CGSizeMake(300, 1000)
                               lineBreakMode:UILineBreakModeWordWrap];
    return labelSize.height + 25;
}


@end
