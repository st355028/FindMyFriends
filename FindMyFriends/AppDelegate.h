//
//  AppDelegate.h
//  FindMyFriends
//
//  Created by 何旻曄 on 2016/5/21.
//  Copyright © 2016年 MINYEH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <sqlite3.h>
@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    sqlite3 *db;
}


@property (strong, nonatomic) UIWindow *window;


@end

