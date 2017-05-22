//
//  ViewController.m
//  TableViewTest
//
//  Created by YY on 2017/5/16.
//  Copyright © 2017年 SongHeng. All rights reserved.
//

#import "ViewController.h"
#import "SXRTableViewCell.h"
#import "SDWebImage/UIImageView+WebCache.h"
#import "UIImageView+CornerImage.h"
#import <malloc/malloc.h>
#import "SDWebImageManager.h"
#import "CALayer+CornerLayer.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *tv;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initTableView];
}

- (void)initTableView{
    self.tv = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.tv.estimatedRowHeight = 100;
    [self.view addSubview:self.tv];
    self.tv.delegate = self;
    self.tv.dataSource = self;
}

- (void)cutImages{
    UIImage *bigImg = [UIImage imageNamed:@"timg"];
    UIGraphicsBeginImageContext(CGSizeMake(200, 200));
//    CGContextRef context = UIGraphicsGetCurrentContext();
    for (int i = 0; i<10000; i++) {
        int x = arc4random()%2280;
        int y = arc4random()%3308;
        [bigImg drawInRect:CGRectMake(-x, -y, 2480, 3508)];
        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
        NSData *data = UIImageJPEGRepresentation(img, 1);
        [data writeToFile:[NSString stringWithFormat:@"/Users/yy/Desktop/tmp/tmpImg/%d.jpg",i]  atomically:true];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    NSLog(@"didReceiveMemoryWarning");
}

#pragma mark - tv delegate

#pragma mark - tv datasource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3000;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SXRTableViewCell *cell = [self.tv dequeueReusableCellWithIdentifier:@"mycell"];

    if (!cell) {
        cell = [[SXRTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"mycell"];
    }
    
    [cell.iv sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1/tmpImgs/%ld.jpg",indexPath.row]] placeholderImage:nil options:SDWebImageAvoidAutoSetImage completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        [cell.iv cornerWithRadius:40 image:image color:nil borderWidth:4 borderColor:[UIColor blueColor]];
//        cell.iv.image = image;
    }];
    
    cell.label.text = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
    
//    NSLog(@"Size of %@: %zd", NSStringFromClass([cell class]),
//          malloc_size((__bridge const void *) cell));
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

@end
