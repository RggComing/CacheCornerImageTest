//
//  CALayer+CornerImage.m
//  TableViewTest
//
//  Created by YY on 2017/5/22.
//  Copyright © 2017年 SongHeng. All rights reserved.
//

#import "UIImageView+CornerImage.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <CommonCrypto/CommonDigest.h>

//  named as : rd(50.000000) IMG(fIUnkqwi89hnkG) BGC(1.00_0.00_0.00) BD(1.00_0.00_0.00_2.0)
static char* kCacheKeyBackgroundColor = "BCG";
static char* kCacheKeyBorder = "BD";
static char* kCacheKeyImage = "IMG";
static char* kRadius = "rd";

@implementation UIImageView (CornerImage)

- (void)cornerWithRadius:(CGFloat)cornerRadius{
    //  just mask the image,no cache
}

-(void)cornerWithRadius:(CGFloat)cornerRadius image:(UIImage *)img{
    [self cornerWithRadius:cornerRadius image:img color:nil borderWidth:0 borderColor:nil];
}

- (void)cornerWithRadius:(CGFloat)cornerRadius color:(UIColor *)color{
    [self cornerWithRadius:cornerRadius image:nil color:color borderWidth:0 borderColor:nil];
}

- (void)cornerWithRadius:(CGFloat)cornerRadius image:(UIImage *)img color:(UIColor *)color borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor{
    self.image = nil;
    self.highlightedImage = nil;
    
    //      had cache?
    NSString *cacheKey = [UIImageView getKeyWithRadius:cornerRadius image:img color:color.CGColor borderWidth:borderWidth borderColor:borderColor.CGColor];
    UIImage *cacheImage = [UIImageView cacheImageWithKey:cacheKey];
    if (cacheImage) {
//        NSLog(@"Use Cache image");
        self.image = cacheImage;
        return;
    }
    
    __block UIColor *bcolor = color;
    __block UIColor *bBorderColor = borderColor;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
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
        
        self.backgroundColor = [UIColor clearColor];
        
        UIImage *cornerImg = UIGraphicsGetImageFromCurrentImageContext();
        [UIImageView saveCacheWithImage:cornerImg key:cacheKey];
        CGContextClearRect(context, cornerRect);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.image = cornerImg;
        });
        
        UIGraphicsEndImageContext();
    });
}

+(NSString *)getKeyWithRadius:(CGFloat)cornerRadius image:(UIImage *)img color:(CGColorRef )color borderWidth:(CGFloat)borderWidth borderColor:(CGColorRef )borderColor{
#define CHUNK_SIZE 8192 // 1024*8
    if (!cornerRadius) {
        return nil;
    }
    
    NSString *mtbStr = [NSString stringWithFormat:@"%s(%f)",kRadius,cornerRadius];
    if (img) {
        CC_MD5_CTX md5;
        
        CC_MD5_Init(&md5);

#warning this may use much cpu source
        NSData *imageData = UIImageJPEGRepresentation(img, .2);
        CC_MD5_Update(&md5, [imageData bytes], (CC_LONG)[imageData length]);
        
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &md5);
        
        NSString *imageHash = [NSString stringWithFormat:                               @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                               digest[0], digest[1], digest[2], digest[3],
                               digest[4], digest[5], digest[6], digest[7],
                               digest[8], digest[9], digest[10], digest[11],
                               digest[12], digest[13], digest[14], digest[15]
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

#pragma mark - cache method

//+ (CGContextRef)getContextWithSize:(CGSize)size{
//    static NSMutableSet *contextSet;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        contextSet = [[NSMutableSet alloc] init];
//    });
//    CGContextRef context = (__bridge CGContextRef)([contextSet anyObject]);
//    if (context) {
//        CGContextConvertSizeToUserSpace(context, size);
//        [contextSet removeObject:(__bridge id _Nonnull)(context)];
//    }else{
//        UIGraphicsBeginImageContext(size);
//        context = UIGraphicsGetCurrentContext();
//    }
//    
//    return context;
//}

+ (id)cacheImageWithKey:(NSString *)cacheKey{
    id image = [[self imageCahce] objectForKey:cacheKey];
    if (!image) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        image = [NSFileHandle fileHandleForReadingAtPath:[path stringByAppendingFormat:@"/%@.jpg",cacheKey]];
    }
    return image;
}

+ (void)saveCacheWithImage:(UIImage *)img key:(NSString *)key{
//    NSLog(@"%@",key);
    [[self imageCahce] setObject:img forKey:key];
    
    //  save as file
    NSData *data = UIImageJPEGRepresentation(img, 1.0);
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingFormat:@"/%@.jpg",key];
    if (![NSFileHandle fileHandleForReadingAtPath:path]) {
        [data writeToFile:path atomically:true];
    }
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
        cache.totalCostLimit = 1021024024;
    });
    
    return cache;
}


@end
