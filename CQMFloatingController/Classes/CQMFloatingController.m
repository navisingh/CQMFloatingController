//
// CQMFloatingController.m
// Created by cocopon on 2011/05/19.
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

#import <QuartzCore/QuartzCore.h>
#import "CQMFloatingController.h"
#import "CQMFloatingContentOverlayView.h"
#import "CQMFloatingFrameView.h"
#import "CQMFloatingMaskControl.h"
#import "CQMFloatingNavigationBar.h"
#import "CQMPathUtilities.h"


#define kDefaultMaskColor  [UIColor colorWithWhite:0 alpha:0.5]
#define kDefaultFrameColor [UIColor colorWithRed:0.10f green:0.12f blue:0.16f alpha:1.00f]
#define kFrameMargin 66.0f
#define kFramePadding      5.0f
#define kRootKey           @"root"
#define kShadowColor       [UIColor blackColor]
#define kShadowOffset      CGSizeMake(0, 2.0f)
#define kShadowOpacity     0.70f
#define kShadowRadius      10.0f
#define kAnimationDuration 0.3f


@interface CQMFloatingController()<CQMFloatingControllerDelegate>

@property (nonatomic, strong) CQMFloatingMaskControl *maskControl;
@property (nonatomic, strong) CQMFloatingFrameView *frameView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) CQMFloatingContentOverlayView *contentOverlayView;
@property (nonatomic, strong) UIImageView *shadowView;
@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, strong) UINavigationController *navigationController;

@end


@implementation CQMFloatingController
{
@private
	BOOL _presented;
}


- (id)init {
	if (self = [super init]) {
        CGFloat w = [UIApplication sharedApplication].delegate.window.frame.size.width - kFrameMargin;
        CGFloat h = [UIApplication sharedApplication].delegate.window.frame.size.height - kFrameMargin;
        
        [self setPortraitFrameSize:CGSizeMake(w, h)];
        [self setLandscapeFrameSize:CGSizeMake(h, w)];
        
		[self setFrameColor:kDefaultFrameColor];
	}
	return self;
}


#pragma mark -
#pragma mark Property

- (void)setPortraitFrameSize:(CGSize)portraitFrameSize {
	_portraitFrameSize = portraitFrameSize;
	[self layoutFrameView];
}

- (void)setLandscapeFrameSize:(CGSize)landscapeFrameSize {
	_landscapeFrameSize = landscapeFrameSize;
	[self layoutFrameView];
}


- (UIColor*)frameColor {
	return [self.frameView baseColor];
}
- (void)setFrameColor:(UIColor*)frameColor {
	[self.frameView setBaseColor:frameColor];
	[self.contentOverlayView setEdgeColor:frameColor];
	[self.navigationController.navigationBar setTintColor:frameColor];
}


- (CQMFloatingMaskControl*)maskControl {
	if (_maskControl == nil) {
		_maskControl = [[CQMFloatingMaskControl alloc] init];
		[_maskControl setBackgroundColor:kDefaultMaskColor];
		[_maskControl setResizeDelegate:self];
		[_maskControl addTarget:self
						 action:@selector(maskControlDidTouchUpInside:)
			   forControlEvents:UIControlEventTouchUpInside];
	}
	return _maskControl;
}


- (UIView*)frameView {
	if (_frameView == nil) {
		_frameView = [[CQMFloatingFrameView alloc] init];
		[_frameView.layer setShadowColor:[kShadowColor CGColor]];
		[_frameView.layer setShadowOffset:kShadowOffset];
		[_frameView.layer setShadowOpacity:kShadowOpacity];
		[_frameView.layer setShadowRadius:kShadowRadius];
	}
	return _frameView;
}


- (UIView*)contentView {
	if (_contentView == nil) {
		_contentView = [[UIView alloc] init];
		[_contentView setClipsToBounds:YES];
	}
	return _contentView;
}


- (CQMFloatingContentOverlayView*)contentOverlayView {
	if (_contentOverlayView == nil) {
		_contentOverlayView = [[CQMFloatingContentOverlayView alloc] init];
		[_contentOverlayView setUserInteractionEnabled:NO];
	}
	return _contentOverlayView;
}


- (UINavigationController*)navigationController {
	if (_navigationController == nil) {
		UIViewController *dummy = [[UIViewController alloc] init];
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:dummy];
		
		// Archive navigation controller for changing navigationbar class
		[navController navigationBar];
		NSMutableData *data = [[NSMutableData alloc] init];
		NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		[archiver encodeObject:navController forKey:kRootKey];
		[archiver finishEncoding];
		
		// Unarchive it with changing navigationbar class
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		[unarchiver setClass:[CQMFloatingNavigationBar class]
				forClassName:NSStringFromClass([UINavigationBar class])];
		_navigationController = [unarchiver decodeObjectForKey:kRootKey];
	}
	return _navigationController;
}

#pragma mark -
#pragma mark Singleton


+ (CQMFloatingController*)sharedFloatingController {
	static CQMFloatingController *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^ {
		instance = [[CQMFloatingController alloc] init];
	});
	return instance;
}


#pragma mark -


- (void)showInView:(UIView*)view withContentViewController:(UIViewController*)viewController animated:(BOOL)animated {
	@synchronized(self) {
		if (_presented) {
			return;
		}
		_presented = YES;
	}
	
	[self.view setAlpha:0];
	
	if (_contentViewController != viewController) {
		[[_contentViewController view] removeFromSuperview];
		_contentViewController = viewController;

		NSArray *viewControllers = [NSArray arrayWithObject:_contentViewController];
		[self.navigationController setViewControllers:viewControllers];
	}
	
	[self.view setFrame:[view bounds]];
	[view addSubview:[self view]];
	
	[self layoutFrameView];
	
	__block CQMFloatingController *me = self;
	[UIView animateWithDuration:(animated ? kAnimationDuration : 0)
					 animations:
	 ^(void) {
		 [me.view setAlpha:1.0f];
	 }];
}

- (void)dismissAnimated:(BOOL)animated {
    if (animated) {
        typeof (self) __weak weakSelf = self;
        [UIView animateWithDuration: kAnimationDuration
                         animations:
         ^(void) {
             [weakSelf.view setAlpha:0];
         }
                         completion:
         ^(BOOL finished) {
             if (finished) {
                 [weakSelf.view removeFromSuperview];
                 _presented = NO;
             }
         }];
    }
    else {
        [self.view removeFromSuperview];
        _presented = NO;
    }
}


- (void)layoutFrameView {
	// Frame
	CGSize maskSize = [self.maskControl frame].size;
	BOOL isPortrait = (maskSize.width <= maskSize.height);
	CGSize frameSize = isPortrait ? [self portraitFrameSize] : [self landscapeFrameSize];
	CGSize viewSize = [self.view frame].size;
	UIView *frameView = [self frameView];
	[frameView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
	[frameView setFrame:CGRectMake(round((viewSize.width - frameSize.width) / 2),
								   round((viewSize.height - frameSize.height) / 2),
								   frameSize.width,
								   frameSize.height)];
	[frameView setNeedsDisplay];
	
	// Content
	UIView *contentView = [self contentView];
	CGRect contentFrame = CGRectMake(kFramePadding, 0,
									 frameSize.width - kFramePadding * 2,
									 frameSize.height - kFramePadding);
	CGSize contentSize = contentFrame.size;
	[contentView setFrame:contentFrame];
	
	// Navigation
	UIView *navView = [self.navigationController view];
	CGFloat navBarHeight = [self.navigationController.navigationBar sizeThatFits:[contentView bounds].size].height;
	[navView setFrame:CGRectMake(0, 0,
								 contentSize.width, contentSize.height)];
	[self.navigationController.navigationBar setFrame:CGRectMake(0, 0,
																 contentSize.width, navBarHeight)];
	
	// Content overlay
	UIView *contentOverlay = [self contentOverlayView];
	CGFloat contentFrameWidth = [CQMFloatingContentOverlayView frameWidth];
	[contentOverlay setFrame:CGRectMake(contentFrame.origin.x - contentFrameWidth,
										contentFrame.origin.y + navBarHeight - contentFrameWidth,
										contentSize.width  + contentFrameWidth * 2,
										contentSize.height - navBarHeight + contentFrameWidth * 2)];
	[contentOverlay setNeedsDisplay];
	[contentOverlay.superview bringSubviewToFront:contentOverlay];
	
	// Shadow
	CGFloat radius = [self.frameView cornerRadius];
	CGPathRef shadowPath = CQMPathCreateRoundingRect(CGRectMake(0, 0,
																frameSize.width, frameSize.height),
													 radius, radius, radius, radius);
	[frameView.layer setShadowPath:shadowPath];
	CGPathRelease(shadowPath);
}


#pragma mark -
#pragma mark Actions


- (void)maskControlDidTouchUpInside:(id)sender {
	[self dismissAnimated:YES];
}


#pragma mark -
#pragma mark Delegates


- (void)floatingMaskControlDidResize:(CQMFloatingFrameView*)frameView {
	[self layoutFrameView];
}


#pragma mark -
#pragma mark UIViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self.view setBackgroundColor:[UIColor clearColor]];
	
	UIView *maskControl = [self maskControl];
	CGSize viewSize = [self.view frame].size;
	[maskControl setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
	[maskControl setFrame:CGRectMake(0, 0,
									 viewSize.width, viewSize.height)];
	[self.view addSubview:maskControl];
	
	[self.view addSubview:[self frameView]];
	[self.frameView addSubview:[self contentView]];
	[self.contentView addSubview:[self.navigationController view]];
	[self.frameView addSubview:[self contentOverlayView]];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}


@end
