//
// CQMFloatingFrameView.m
// Created by cocopon on 2012/05/14.
//
// Copyright (c) 2012 cocopon <cocopon@me.com>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "CQMFloatingFrameView.h"
#import "CQMPathUtilities.h"


#define kHighlightHeight     22.0f
#define kHighlightMargin     1.0f
#define kStartHighlightColor [UIColor colorWithWhite:1.00f alpha:0.40f]
#define kEndHighlightColor   [UIColor colorWithWhite:1.00f alpha:0.05f]
#define kDefaultCornerRadius 10.0f


@implementation CQMFloatingFrameView {
@private
	CGFloat cornerRadius_;
	UIColor *baseColor_;
}


- (id)init {
	if (self = [super init]) {
		[self setBackgroundColor:[UIColor clearColor]];
		[self setCornerRadius:kDefaultCornerRadius];
	}
	return self;
}


- (void)dealloc {
	[baseColor_ release];
	[super dealloc];
}


#pragma mark -
#pragma mark Property


- (UIColor*)baseColor {
	return baseColor_;
}
- (void)setBaseColor:(UIColor*)baseColor {
	if (baseColor_ != baseColor) {
		[baseColor_ release];
		baseColor_ = [baseColor retain];
	}
	[self setNeedsDisplay];
}


- (CGFloat)cornerRadius {
	return cornerRadius_;
}
- (void)setCornerRadius:(CGFloat)cornerRadius {
	cornerRadius_ = cornerRadius;
	[self setNeedsDisplay];
}


#pragma mark -
#pragma mark UIView


- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGFloat radius = [self cornerRadius];
	CGSize viewSize = [self frame].size;
	CGPathRef path;
	
	// Base
	CGContextSaveGState(context);
	path = CQMPathCreateRoundingRect(CGPointZero,
									 CGPointMake(viewSize.width, viewSize.height),
									 radius,
									 radius,
									 radius,
									 radius);
	CGContextAddPath(context, path);
	CGContextSetFillColorWithColor(context, [self.baseColor CGColor]);
	CGContextFillPath(context);
	CGContextRestoreGState(context);
	
	// Highlight
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSArray *colors = [[NSArray alloc] initWithObjects:
					   (id)[kStartHighlightColor CGColor],
					   (id)[kEndHighlightColor CGColor],
					   nil];
	CGFloat locations[] = {0, 1.0f};
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locations);
	CGRect highlightRect = CGRectMake(kHighlightMargin, kHighlightMargin,
									  viewSize.width - kHighlightMargin * 2,
									  kHighlightHeight);
	CGFloat highlightRadius = radius - kHighlightMargin;
	CGContextSaveGState(context);
	path = CQMPathCreateRoundingRect(highlightRect.origin,
									 CGPointMake(highlightRect.origin.x + highlightRect.size.width,
												 highlightRect.origin.y + highlightRect.size.height),
									 0, 0, highlightRadius, highlightRadius);
	CGContextAddPath(context, path);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradient,
								CGPointMake(0, 0),
								CGPointMake(0, kHighlightHeight),
								0);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
	CGContextRestoreGState(context);
	
	CGPathRelease(path);
}


@end