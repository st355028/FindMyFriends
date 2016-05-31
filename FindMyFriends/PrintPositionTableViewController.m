//
//  PrintPositionTableViewController.m
//  FindMyFriends
//
//  Created by 何旻曄 on 2016/5/28.
//  Copyright © 2016年 MINYEH. All rights reserved.
//

#import "PrintPositionTableViewController.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "FMDB.h"
#import "ViewController.h"
#import "FMDatabasePool.h"
@interface PrintPositionTableViewController ()<UITableViewDelegate,UITableViewDataSource>
{
    NSMutableArray *results;
}
@end

@implementation PrintPositionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //results = [NSMutableArray new];
    results = [NSMutableArray arrayWithArray:self.result];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return results.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *position = results[indexPath.row];
    cell.textLabel.text = position;
    
    return cell;
}



@end
