//
//  MasterViewController.h
//  Seeba
//
//  Created by 大嶺 卓矢 on 2013/10/22.
//  Copyright (c) 2013年 大嶺 卓矢. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
