//
//  ViewController.m
//  OpenForecast
//
//  Created by Sergey Vinogradov on 12.09.16.
//  Copyright © 2016 forecaster. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "OFForecast.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSArray+Cache.h"

NSString *const kAPIKey  = @"2c2ecab69f0478c749442255ca478b63";
NSString *const kMainUrl = @"http://api.openweathermap.org/data/2.5/group";
NSString *const kIconUrlFormat = @"http://openweathermap.org/img/w/%@.png";
NSString *const kLocalCache = @"LocalStoredForecastList";

static NSArray *citiesList() {
    static NSArray *array = nil;
    if (!array) {
        array = @[@1487764,@726050,@588335,@456172,@1819730,@1795564,@5391997,@5392171,@1496990,@1496503];
    }
    return array;
}

static UIImage *placeholderImage() {
    static UIImage *image = nil;
    if (!image) {
        image = [UIImage imageNamed:@"placeholder"];
    }
    return image;
}

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *noResultsView;
@property (weak, nonatomic) IBOutlet UILabel *noResultsLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSMutableArray *itemsList;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.itemsList = [NSMutableArray array];
    [self prepareItemsWithArrayOfDictionaries:[[NSArray alloc] initArrayFromCacheWithKey:kLocalCache]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor lightGrayColor];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:self.refreshControl];
    [self.tableView sendSubviewToBack:self.refreshControl];
    
    [self checkIfWeHaveResults];
    
    if (((AppDelegate*)[UIApplication sharedApplication].delegate).networkIsReachable) {
        [self updateWeatherForTargetCities];
    }
    
    [((AppDelegate*)[UIApplication sharedApplication].delegate) addObserver:self forKeyPath:@"networkIsReachable" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
     [((AppDelegate*)[UIApplication sharedApplication].delegate) removeObserver:self forKeyPath:@"networkIsReachable"];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.itemsList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    OFForecast *forecast = self.itemsList[indexPath.row];
    
    cell.textLabel.text = forecast.city;
    cell.detailTextLabel.text = forecast.weather;
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:kIconUrlFormat,forecast.iconName]] placeholderImage:placeholderImage()];
    
    return cell;
}


#pragma mark - Private

- (void)pullToRefresh {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM d, h:mm a"];
    NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor lightGrayColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
    self.refreshControl.attributedTitle = attributedTitle;
    [self.refreshControl endRefreshing];
    [self updateWeatherForTargetCities];
}

- (void)prepareItemsWithArrayOfDictionaries:(NSArray *)array {
    if (array && [array count]) {
        [array storeArrayToCacheWithKey:kLocalCache];
        
        [self.itemsList removeAllObjects];
        for (NSDictionary *dict in array) {
            [self.itemsList addObject:[[OFForecast alloc] initWithDictionary:dict]];
        }
        
        [self.itemsList sortUsingComparator:^NSComparisonResult(OFForecast *obj1, OFForecast *obj2) {
            return [obj1.city caseInsensitiveCompare:obj2.city];
        }];
    }
    
    [self checkIfWeHaveResults];
}

- (void)checkIfWeHaveResults {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        
        if ([self.itemsList count]) {
            [self hideNoResultsView];
        } else {
            [self showWaitForForecast];
        }
    });
}

#pragma mark No results hover view

- (void)showNoResultsView {
    self.noResultsView.alpha = 0.0;
    self.noResultsView.hidden = NO;
    [self.view bringSubviewToFront:self.noResultsView];
    [UIView animateWithDuration:0.5 animations:^{
        self.noResultsView.alpha = 1.0;
    }];
}

- (void)hideNoResultsView {
    [UIView animateWithDuration:0.5 animations:^{
        self.noResultsView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.noResultsView.hidden = YES;
        [self.view bringSubviewToFront:self.tableView];
    }];
}

- (void)showWaitForForecast {
    self.noResultsLabel.text = @"Please wait for\nforecast deliver.";
    
    [self showNoResultsView];
}

- (void)resetUIForInternetReachable:(BOOL)isReachable {
    if (isReachable) {
        [self hideNoResultsView];
    } else {
        self.noResultsLabel.text = @"Please wait for\nforecast deliver.";
        
        [self showNoResultsView];
    }
}


#pragma mark - KVO
     
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)
change context:(void *)context {
    
    if (change && change[@"new"]) {
        BOOL isReachable = [change[@"new"] boolValue];
        
        [self resetUIForInternetReachable:isReachable];
        
        if (isReachable) {
            [self updateWeatherForTargetCities];
        }
    }
}


#pragma mark - Networking

- (void)updateWeatherForTargetCities {
    
    __block NSString *citiesListString = @"";
    [citiesList() enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        citiesListString = [citiesListString stringByAppendingFormat:@"%@,",obj];
    }];
    citiesListString = [citiesListString substringToIndex:(citiesListString.length-1)];
    
    NSString *urlString = [NSString stringWithFormat:@"%@?id=%@&units=metric&APPID=%@",kMainUrl,citiesListString,kAPIKey];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];//URLFragmentAllowedCharacterSet
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
     
     [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
         if (error) {
             NSLog(@"Error stories update: %@",error);
             return;
         }
         
#ifdef DEBUG
         //NSString *string = [NSString stringWithUTF8String:[data bytes]];
         //NSLog(@"%@",string);
#endif
         
         NSError *parsingError;
         NSDictionary *responceDict = [self parseJsonFromData:data possibleError:parsingError];
         
         if (!responceDict || parsingError) {
             return;
         }
         
         [self prepareItemsWithArrayOfDictionaries:responceDict[@"list"]];
     }] resume];
}



#pragma mark Parsing

- (id)parseJsonFromData:(NSData *)data possibleError:(NSError*)parsingError{
    
    id object = nil;
    
    if (!data)
        return @{@"error":@"Empty data"};
    
    object = [NSJSONSerialization JSONObjectWithData:data
                                             options:NSJSONReadingMutableLeaves
                                               error:&parsingError];
    if (parsingError) {
        
        NSLog(@"Parsig error %@",[parsingError userInfo]);
    }
    
    return object;
}

@end
