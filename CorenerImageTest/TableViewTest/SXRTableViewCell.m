//
//  SXRTableViewCell.m
//  TableViewTest
//
//  Created by YY on 2017/5/17.
//  Copyright © 2017年 SongHeng. All rights reserved.
//

#import "SXRTableViewCell.h"

@interface SXRTableViewCell ()

@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *msgLabel;

@end

@implementation SXRTableViewCell

- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    
    self.timeLabel.text = [NSString stringWithFormat:@"%f",[NSDate date].timeIntervalSinceNow];
    self.msgLabel.text = [NSString stringWithFormat:@"@@ %f -- 说的话",[NSDate date].timeIntervalSinceNow];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - lazy load
- (UIImageView *)iv{
    if (!_iv) {
        _iv = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 80, 80)];
        _iv.backgroundColor = [UIColor redColor];
//        _iv.layer.cornerRadius = 40;
//        _iv.layer.masksToBounds = false;
        [self.contentView addSubview:_iv];
        
    }
    return _iv;
}

- (UILabel *)label{
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectMake(120, 10,
                                             [UIScreen mainScreen].bounds.size.width - 140, 14)];
        _label.backgroundColor = [UIColor yellowColor];
        [self.contentView addSubview:_label];
    }
    return _label;
}

- (UILabel *)timeLabel{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 76, [UIScreen mainScreen].bounds.size.width - 140, 14)];
        [self.contentView addSubview:_timeLabel];
    }
    return _timeLabel;
}

- (UILabel *)msgLabel{
    if (!_msgLabel) {
        _msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, 34, [UIScreen mainScreen].bounds.size.width - 140, 14)];
        [self.contentView addSubview:_msgLabel];
    }
    return _msgLabel;
}
@end
