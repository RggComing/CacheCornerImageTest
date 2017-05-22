//
//  CALayer+CornerImage.h
//  TableViewTest
//
//  Created by YY on 2017/5/22.
//  Copyright © 2017年 SongHeng. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImageView (CornerImage)

///  only tailor the layer content and never cache
- (void)cornerWithRadius:(CGFloat)cornerRadius;

/// cache cornerImage with MD5
- (void)cornerWithRadius:(CGFloat)cornerRadius image:(UIImage *)img;

///  cache tailored backgroundColor in image
- (void)cornerWithRadius:(CGFloat)cornerRadius color:(UIColor *)color;

- (void)cornerWithRadius:(CGFloat)cornerRadius image:(UIImage *)img color:(UIColor *)color borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor;

@end
