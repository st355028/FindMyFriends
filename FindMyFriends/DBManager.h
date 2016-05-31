//
//  DBManager.h
//  FindMyFriends
//
//  Created by 何旻曄 on 2016/5/21.
//  Copyright © 2016年 MINYEH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBManager : NSObject
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSString *databaseFilename;

-(instancetype)initWithDatabaseFilename:(NSString *)dbFilename;
-(void)copyDatabaseIntoDocumentsDirectory;
@end
