//
//  UIImage+ImmediateLoading.m
//  SwapTest
//
//  Created by Julian Asamer on 3/11/11.
//  Code taken from https://gist.github.com/259357
//

#import "UIImage+ImmediateLoading.h"

@implementation UIImage (UIImage_ImmediateLoading)

+ (UIImage*)imageImmediateLoadWithContentsOfFile:(NSString*)path {
    //return [UIImage imageWithContentsOfFile:path];
    
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    CGImageRef imageRef = [image CGImage];
    CGRect rect = CGRectMake(0.f, 0.f, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       rect.size.width,
                                                       rect.size.height,
                                                       CGImageGetBitsPerComponent(imageRef),
                                                       CGImageGetBytesPerRow(imageRef),
                                                       CGImageGetColorSpace(imageRef), 
                                                       CGImageGetBitmapInfo(imageRef) // by ukv
                                                       //kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Little //by ukv
                                                       );
    if (!bitmapContext) {
        return [image autorelease];
    }
    
    CGContextDrawImage(bitmapContext, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef];

    CGImageRelease(decompressedImageRef);
    CGContextRelease(bitmapContext);
    [image release];
    return decompressedImage;
     
    //return [[[UIImage alloc] initImmediateLoadWithContentsOfFile: path] autorelease];
}

/*
- (UIImage*) initImmediateLoadWithContentsOfFile:(NSString*)path {
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    CGImageRef imageRef = [image CGImage];
    CGRect rect = CGRectMake(0.f, 0.f, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                       rect.size.width,
                                                       rect.size.height,
                                                       CGImageGetBitsPerComponent(imageRef),
                                                       CGImageGetBytesPerRow(imageRef),
                                                       CGImageGetColorSpace(imageRef),
                                                       //CGImageGetBitmapInfo(imageRef), // by ukv
                                                       kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little //by ukv
                                                       );
    CGContextDrawImage(bitmapContext, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(bitmapContext);
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef];
    CGImageRelease(decompressedImageRef);
    CGContextRelease(bitmapContext);
    [image release];
    return decompressedImage;
}
*/

@end
