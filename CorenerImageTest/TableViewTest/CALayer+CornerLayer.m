//
//  CALayer+CornerLayer.m
//  chacha
//
//  Created by YY on 2017/5/18.
//  Copyright © 2017年 EXUTECH. All rights reserved.
//

#import "CALayer+CornerLayer.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>

static char* kCornerImgName = "cornerImgName";

//  named as : rd(50.000000) IMG(fIUnkqwi89hnkG) BGC(1.00_0.00_0.00) BD(1.00_0.00_0.00_2.0)
static char* kCacheKeyBackgroundColor = "BCG";
static char* kCacheKeyBorder = "BD";
static char* kCacheKeyImage = "IMG";
static char* kRadius = "rd";

@interface CALayer (CornerLayer)<CALayerDelegate>

@property (nonatomic, strong) UIImage *cornerImg;

@end

@implementation CALayer (CornerLayer)

+ (void)load{
	NSLog(@"%@%s",[self class],__func__);
}

+ (void)initialize{
	NSLog(@"%@%s",[self class],__func__);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // init once
        Method originalDrawMethod = class_getInstanceMethod([self class], @selector(drawInContext:));
        Method exchangeDrawMethod = class_getInstanceMethod([self class], @selector(sxr_drawInContext:));
        
        method_exchangeImplementations(originalDrawMethod, exchangeDrawMethod);
    });
}

- (void)cornerWithRadius:(CGFloat)cornerRadius{
    UIGraphicsBeginImageContext(self.frame.size);
#warning only use one context if possiable
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:cornerRadius];
    
    CGContextAddPath(context, path.CGPath);
    CGContextSetFillColorWithColor(context, self.backgroundColor);

    CGContextDrawPath(context, kCGPathFill);
    [self setCornerImg:UIGraphicsGetImageFromCurrentImageContext()];

    self.contents = (id)[self cornerImg].CGImage;

    const CGFloat *comp = CGColorGetComponents(self.backgroundColor);
    [CALayer saveCacheWithImage:[self cornerImg] key:[NSString stringWithFormat:@"BGC(%f_%f_%f)%f",comp[0],comp[1],comp[2],cornerRadius]];

    self.backgroundColor = [UIColor clearColor].CGColor;
    UIGraphicsEndImageContext();
}

- (void)cornerWithRadius:(CGFloat)cornerRadius image:(UIImage *)img{
    [self cornerWithRadius:cornerRadius image:img color:nil borderWidth:0 borderColor:nil];
}

- (void)cornerWithRadius:(CGFloat)cornerRadius color:(UIColor *)color{
    [self cornerWithRadius:cornerRadius image:nil color:color borderWidth:0 borderColor:nil];
}

- (void)sxr_drawInContext:(CGContextRef)ctx{    
    if ([self cornerImg]) {
        //  use cornerImage again
        self.contents = (id)[self cornerImg].CGImage;
    }else{
        [self sxr_drawInContext:ctx];
    }
}


- (void)cornerWithRadius:(CGFloat)cornerRadius image:(UIImage *)img color:(UIColor *)color borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor{
    self.contents = nil;
    
//      had cache?
    NSString *cacheKey = [CALayer getKeyWithRadius:cornerRadius image:img color:color.CGColor borderWidth:borderWidth borderColor:borderColor.CGColor];
    UIImage *cacheImage = [CALayer cacheImageWithKey:cacheKey];
    if (cacheImage) {
        NSLog(@"Use Cache image");
        self.contents = (id)cacheImage.CGImage;
        return;
    }

    __block UIColor *bcolor = color;
    __block UIColor *bBorderColor = borderColor;

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
#warning will no image when cornerRadius is 0
        if (!cornerRadius) {
            return;
        }
        
#warning didnt handle content mode
#warning only use one context if possiable
        UIGraphicsBeginImageContext(self.frame.size);

        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGRect cornerRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:cornerRect cornerRadius:cornerRadius];
        [path addClip];
        CGContextAddPath(context, path.CGPath);

        //  draw image
        if (img) {
            CGContextTranslateCTM(context, 0, cornerRect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextDrawImage(context, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height),
                               img.CGImage);
            CGContextClip(context);
            //  add path again
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:cornerRect cornerRadius:cornerRadius];
            [path addClip];
            CGContextAddPath(context, path.CGPath);
            bcolor = nil;
        }else if(bcolor){
            CGContextSetFillColorWithColor(context, bcolor.CGColor);
        }
        
        if (borderWidth) {
            bBorderColor = bBorderColor ? bBorderColor : [UIColor blackColor];
            CGContextSetStrokeColorWithColor(context, bBorderColor.CGColor);
            if (!bcolor) {
                CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
            }
            CGContextSetLineWidth(context, borderWidth);
        }
        CGContextDrawPath(context, kCGPathFillStroke);
        
        self.backgroundColor = [UIColor clearColor].CGColor;
        
        UIImage *cornerImg = UIGraphicsGetImageFromCurrentImageContext();
        [CALayer saveCacheWithImage:cornerImg key:cacheKey];
        CGContextClearRect(context, cornerRect);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contents = (id)cornerImg.CGImage;
            [self setCornerImg:cornerImg];
        });
        
        UIGraphicsEndImageContext();
    });
}

+(NSString *)getKeyWithRadius:(CGFloat)cornerRadius image:(UIImage *)img color:(CGColorRef )color borderWidth:(CGFloat)borderWidth borderColor:(CGColorRef )borderColor{
    
    if (!cornerRadius) {
        return nil;
    }
    
    NSString *mtbStr = [NSString stringWithFormat:@"%s(%f)",kRadius,cornerRadius];
    if (img) {
        unsigned char result[16];
#warning this may use much cpu source
        NSData *imageData = UIImageJPEGRepresentation(img, 0.2);
        CC_MD5((__bridge const void *)(imageData), (int)imageData.length, result);

        NSString *imageHash = [NSString stringWithFormat:                               @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                               result[0], result[1], result[2], result[3],
                               result[4], result[5], result[6], result[7],
                               result[8], result[9], result[10], result[11],
                               result[12], result[13], result[14], result[15]
                               ];
        
        mtbStr = [mtbStr stringByAppendingFormat:@" %s(%@)",kCacheKeyImage,imageHash];
    }
    else if (color){
        const CGFloat *comp = CGColorGetComponents(color);
        mtbStr = [mtbStr stringByAppendingFormat:@" %s(%.2f_%.2f_%.2f)",kCacheKeyBackgroundColor,comp[0],comp[1],comp[2]];
    }
    
    if (borderWidth) {
        // BD(1.00_0.00_0.00_2.0)
        const CGFloat *comp = CGColorGetComponents(borderColor);
        mtbStr = [mtbStr stringByAppendingFormat:@" %s(%.2f_%.2f_%.2f_%.1f)",kCacheKeyBorder,comp[0],comp[1],comp[2],borderWidth];
    }
    
    
    return mtbStr;
}

+ (id)cacheImageWithKey:(NSString *)cacheKey{
    return [[self imageCahce] objectForKey:cacheKey];
}

+ (void)saveCacheWithImage:(UIImage *)img key:(NSString *)key{
    [[self imageCahce] setObject:img forKey:key];
}

#pragma mark setter&&getter
- (UIImage *)cornerImg{
	return objc_getAssociatedObject(self, kCornerImgName);
}

- (void)setCornerImg:(UIImage *)cornerImg{
	objc_setAssociatedObject(self, kCornerImgName, cornerImg, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)cleanCache{
    [[self imageCahce] removeAllObjects];
}

+ (NSCache *)imageCahce{
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 100;
        cache.totalCostLimit = 1021024;
    });

    return cache;
}

@end
