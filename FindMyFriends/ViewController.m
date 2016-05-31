//
//  ViewController.m
//  FindMyFriends
//
//  Created by 何旻曄 on 2016/5/21.
//  Copyright © 2016年 MINYEH. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "FMResultSet.h"
#import "FMDatabase.h"
#import "PrintPositionTableViewController.h"
@interface ViewController ()<MKMapViewDelegate,CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    NSDictionary * jsonResult;
    CLLocation *currentLocation;
    NSMutableArray * path;
    MKPolylineRenderer * renderer;
    NSInteger segindexForDraw;
    NSInteger segindexForUpload;
    FMResultSet *YourPosition;
    NSMutableArray *post;
    FMDatabase *db;

}

@property (weak, nonatomic) IBOutlet MKMapView *mainMap;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //獲取文檔目錄，NSDocumentDirectory表示我們查找Documents目錄的路徑,NSUserDomainMask表示我們的搜尋範圍只能在我們的應用程式沙箱當中
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentDirectory stringByAppendingPathComponent:@"MyDatabase.db"];
    
    db = [FMDatabase databaseWithPath:dbPath] ; //如果該路徑本來沒有檔案，會新增檔案，不然會開啟舊檔
    if (![db open]) {
        
        NSLog(@"Could not open db.");
        return ;
    }
    //IF NOT EXISTS 可以選擇是否要加，加這段是用來判斷如果table存在了就不再創造
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS Position (latitude double,longitude double)"];
    [db executeUpdate:@"DELETE FROM Position"]; //清空資料庫

    path = [[NSMutableArray alloc]init];
    locationManager = [CLLocationManager new];//初始化
    post = [NSMutableArray new]; //存取資料庫撈到的資料

    if([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [locationManager requestAlwaysAuthorization];
    
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.activityType = CLActivityTypeFitness;
    locationManager.delegate =self;
    [locationManager startUpdatingLocation];

    }
//讓tableview跳回來viewcontroller的指令
-(IBAction)backToMain:(UIStoryboardSegue *)sender
{
    NSLog(@"BackToMain executed");
}
//回到目前所在地
- (IBAction)returnMyPosition:(UIButton *)sender {
    self.mainMap.userTrackingMode = MKUserTrackingModeFollowWithHeading;
}
//切換地圖模式
- (IBAction)mapType:(UISegmentedControl *)sender {
    NSInteger targetIndex = sender.selectedSegmentIndex;
    
    switch (targetIndex) {
        case 0:
            self.mainMap.mapType = MKMapTypeStandard;
            break;
        case 1:
            self.mainMap.mapType = MKMapTypeSatellite;
            break;
        case 2:
            self.mainMap.mapType = MKMapTypeHybrid;
            break;
        default:
        break;}

}
//尋找朋友
- (IBAction)findMyFriends:(UIButton *)sender {
    [self findMyFriends];
}
//開始畫我們的軌跡
- (IBAction)startTracker:(UIButton *)sender {
    segindexForDraw = 1; //用來控制是否要畫線的判斷 segindexForDraw=1 是要畫線
    [locationManager startUpdatingLocation]; //開啟追蹤使用者位置
}


- (IBAction)removeTracker:(UIButton *)sender {
    segindexForDraw = 0; //用來控制是否要畫線的判斷 segindexForDraw=0 是不要畫線
    [self.mainMap removeOverlays:self.mainMap.overlays]; //在顯示在地圖上的軌跡畫面刪掉
    
}
- (IBAction)trackerAndFind:(UISegmentedControl *)sender {
    NSInteger index = sender.selectedSegmentIndex;
    switch (index) {
        case 0:
            segindexForUpload = 0; //用來控制資料庫是否要寫入資料以及上傳使用者位置到server的判斷
            [db executeUpdate:@"DELETE FROM Position"]; //把資料庫資料清空
            [post removeAllObjects]; //把存資料庫資料的陣列內容清空
            [db close]; //資料庫停止寫入
            break;
        case 1:
            segindexForUpload = 1; //用來控制資料庫是否要寫入資料以及上傳使用者位置到server的判斷
            [db open]; //開啟資料庫
            [locationManager startUpdatingLocation];
            break;
        default:
            break;
    }
}

#pragma mark -- DidUpDataLocations Methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    
    currentLocation = locations.lastObject; //抓取使用者最新的地理位置
    double Latitude = currentLocation.coordinate.latitude; //細分地理位置的緯度來存進資料庫
    double Longitude = currentLocation.coordinate.longitude; //細分地理位置的經度來存進資料庫
    if(segindexForUpload==1)
    {
        [self uploadData]; //開始上傳位置到server
        [db executeUpdateWithFormat:@"INSERT INTO Position (latitude,longitude) VALUES (%f,%f)",Latitude,Longitude]; //把資料寫入資料庫
       
        //YourPosition的資料型態是FMResultSet，這是專門用來存取資料庫撈出來的資料
        YourPosition = [db executeQuery:@"SELECT latitude, longitude FROM Position"];
        
        while ([YourPosition next]) {
            
            double lat = [YourPosition doubleForColumn:@"latitude"];
            double lon = [YourPosition doubleForColumn:@"longitude"];
            [post addObject:[NSString stringWithFormat:@"Your Position : %f - %f",lat,lon]];
            
        }
        [YourPosition close];

    }
    if(segindexForDraw==0)
    {   //畫面刪除後再把資料刪掉
        [path removeAllObjects];
    }
   else
       [self drawRoute];
    
    static dispatch_once_t changeRegionOnceToken;
    dispatch_once(&changeRegionOnceToken,^{
        //MKCoordinateRegion 這個類別是可以讀寫  region可以抓到地圖中心以及縮放比例
        MKCoordinateRegion region = self.mainMap.region;
        region.center = currentLocation.coordinate;
        //span縮放 此段是說目前螢幕可看的範圍是0.01個經緯度的內容
        region.span.latitudeDelta = 0.01;
        region.span.longitudeDelta = 0.01;
        
        [self.mainMap setRegion:region animated:true];
    });
    
    
}
#pragma mark  --------findMyFriend

-(void)findMyFriends
{
    NSString *urlstring = @"http://class.softarts.cc/FindMyFriends/queryFriendLocations.php?GroupName=ap102";
    NSURL *url = [NSURL URLWithString:urlstring];
    
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(error)
        {
            //NSLog(@"Error:%@",error);
            return;
        }
        
        jsonResult = [NSJSONSerialization JSONObjectWithData:data
        options:NSJSONReadingMutableContainers  error:nil];
        NSArray *json = [[NSArray alloc]initWithArray:[jsonResult objectForKey:@"friends"]];
        NSLog(@"朋友資訊 %@",json);
        
        for(int i=0;i<json.count;i++)
        {
            CLLocationCoordinate2D friend;
            NSDictionary * friendsDictionary= json[i];
            NSString *FriendName = [friendsDictionary objectForKey:@"friendName"];
            NSString *lat = [friendsDictionary objectForKey:@"lat"];
            NSString *lon = [friendsDictionary objectForKey:@"lon"];
            friend.latitude = lat.floatValue;
            friend.longitude = lon.floatValue;
            MKPointAnnotation * point = [MKPointAnnotation new];
            
            point.title = FriendName;
            point.coordinate = friend;
            if([FriendName isEqualToString:@"MinYeh"]){
            }else{
                [self.mainMap addAnnotation:point];
            }
       
        }
    }];
    //要讓task開始工作一定要加這行
    [task resume];

}

-(void)uploadData
{
    CLLocationDegrees lat=currentLocation.coordinate.latitude;
    CLLocationDegrees lon=currentLocation.coordinate.longitude;
    NSString *urlstring = [NSString stringWithFormat:@"http://class.softarts.cc/FindMyFriends/updateUserLocation.php?GroupName=ap102&UserName=MinYeh&Lat=%.6f&Lon=%.6f",lat,lon];
    NSURL *url = [NSURL URLWithString:urlstring];
    
    //Prepare NSURLSession  固定版型 複製到任何地方都可用
    //產生一個設定 預設的
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(error)
        {
            NSLog(@"Error:%@",error);
            return;
        }
    }];
    //要讓task開始工作一定要加這行
    [task resume];

}

#pragma mark --Draw
-(void)drawRoute  {

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(currentLocation.coordinate.latitude,currentLocation.coordinate.longitude);
    
    [path addObject:[NSValue valueWithMKCoordinate:coordinate]];
    
    CLLocationCoordinate2D coordinates[path.count];
    
    for (int i=0;i<path.count;i++) {
        
        //coordinates[i] = [[path objectAtIndex:i] MKCoordinateValue];
        coordinates[i] = [path[i] MKCoordinateValue];
        
        //NSLog(@"%@",path);
        
    }
    
    MKPolyline * polyLine = [MKPolyline polylineWithCoordinates:coordinates count:path.count];
    
    renderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
    
    renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
    renderer.lineWidth   = 5;
    
    [self.mainMap addOverlay:polyLine];
    
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    return renderer;
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    PrintPositionTableViewController *vc = segue.destinationViewController;
    
    vc.result = [NSMutableArray arrayWithArray:post];
    
    
    
}
@end
