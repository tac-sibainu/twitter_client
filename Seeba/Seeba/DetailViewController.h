//
//  DetailViewController.h
//  Seeba
//
//  Created by 大嶺 卓矢 on 2013/10/22.
//  Copyright (c) 2013年 大嶺 卓矢. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
