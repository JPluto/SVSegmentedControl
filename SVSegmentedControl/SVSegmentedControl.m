//
// SWSegmentedControl.m
// SWSegmentedControl
//
// Created by Sam Vermette on 26.10.10.
// Copyright 2010 Sam Vermette. All rights reserved.
//
// https://github.com/samvermette/SVSegmentedControl

#import <QuartzCore/QuartzCore.h>
#import "SVSegmentedControl.h"

#define SVSegmentedControlBG [[UIImage imageNamed:@"SVSegmentedControl.bundle/inner-shadow"] stretchableImageWithLeftCapWidth:4 topCapHeight:5]

@interface SVSegmentedThumb ()

@property (nonatomic, assign) UIFont *font;
@property (nonatomic, assign) SVSegmentedControl *segmentedControl;

@property (nonatomic, readonly) UILabel *label;
@property (nonatomic, readonly) UILabel *secondLabel;

- (void)activate;
- (void)deactivate;

@end

///////////////////////////////////////////////////////////

@interface SVSegmentedControl()

- (void)activate;
- (void)snap:(BOOL)animated;
- (void)updateTitles;
- (void)toggle;

@property (nonatomic, retain) NSMutableArray *titlesArray;
@property (nonatomic, retain) NSMutableArray *thumbRects;

@property (nonatomic, readwrite) NSUInteger snapToIndex;
@property (nonatomic, readwrite) BOOL trackingThumb;
@property (nonatomic, readwrite) BOOL moved;
@property (nonatomic, readwrite) BOOL activated;

@property (nonatomic, readwrite) CGFloat halfSize;
@property (nonatomic, readwrite) CGFloat dragOffset;
@property (nonatomic, readwrite) CGFloat segmentWidth;
@property (nonatomic, readwrite) CGFloat thumbHeight;

@end

///////////////////////////////////////////////////////////

@implementation SVSegmentedControl

@synthesize delegate, selectedSegmentChangedHandler, thumbEdgeInset, selectedIndex, animateToInitialSelection;
@synthesize backgroundImage, font, textColor, shadowColor, shadowOffset, segmentPadding, titleEdgeInsets, height, crossFadeLabelsOnDrag;
@synthesize titlesArray, thumb, thumbRects, snapToIndex, trackingThumb, moved, activated, halfSize, dragOffset, segmentWidth, thumbHeight;

- (id)initWithSectionTitles:(NSArray*)array {
	if ((self = [super initWithFrame:CGRectZero])) {
        self.titlesArray = [NSMutableArray arrayWithArray:array];
        self.thumbRects = [NSMutableArray arrayWithCapacity:[array count]];
        
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        self.animateToInitialSelection = NO;
        self.clipsToBounds = NO;
        
        self.font = [UIFont boldSystemFontOfSize:15];
        self.textColor = [UIColor grayColor];
        self.shadowColor = [UIColor blackColor];
        self.shadowOffset = CGSizeMake(0, -1);
        
        self.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        self.thumbEdgeInset = UIEdgeInsetsMake(2, 2, 3, 2);
        self.height = 32.0;
        
        self.selectedIndex = 0;
        self.thumb.segmentedControl = self;
    }
    
	return self;
}

- (SVSegmentedThumb *)thumb {
    if (thumb == nil) {
        thumb = [[SVSegmentedThumb alloc] initWithFrame:CGRectZero];
    }
    
    return thumb;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
	if (!newSuperview) return;

	int c = [self.titlesArray count];
	int i = 0;
	
	self.segmentWidth = 0;
	
	for (NSString *titleString in self.titlesArray) {
		CGFloat stringWidth = [titleString sizeWithFont:self.font].width+(self.titleEdgeInsets.left+self.titleEdgeInsets.right+self.thumbEdgeInset.left+self.thumbEdgeInset.right);
        self.segmentWidth = MAX(stringWidth, self.segmentWidth);
	}
	
	self.segmentWidth = ceil(self.segmentWidth/2.0)*2; // make it an even number so we can position with center
	self.bounds = CGRectMake(0, 0, self.segmentWidth*c, self.height);
    self.thumbHeight = self.thumb.backgroundImage ? self.thumb.backgroundImage.size.height : self.height-(self.thumbEdgeInset.top+self.thumbEdgeInset.bottom);
    
    i = 0;
	for (NSString *titleString in self.titlesArray) {
        [self.thumbRects addObject:[NSValue valueWithCGRect:CGRectMake(self.segmentWidth*i+self.thumbEdgeInset.left, self.thumbEdgeInset.top, self.segmentWidth-(self.thumbEdgeInset.left*2), self.thumbHeight)]];
		i++;
	} 
	
	self.thumb.frame = [[self.thumbRects objectAtIndex:0] CGRectValue];
	self.thumb.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.thumb.bounds cornerRadius:2].CGPath;
	self.thumb.label.text = [self.titlesArray objectAtIndex:0];
	self.thumb.font = self.font;
	
	[self insertSubview:self.thumb atIndex:0];
    
    BOOL animateInitial = self.animateToInitialSelection;
    
    if (self.selectedIndex == 0) {
        animateInitial = NO;
    }
	
    [self moveThumbToIndex:selectedIndex animate:animateInitial];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (self.backgroundImage) {
        // 自定义背景
        [self.backgroundImage drawInRect:rect];
    } else {
        // 默认背景
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();

        CGContextSaveGState(context);
        
        CGPathRef roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:4].CGPath;
        CGContextAddPath(context, roundedRect);
        CGContextClip(context);
        
        CGFloat components[4] = {
            0, 0.55,
            0, 0.4
        };
        
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, NULL, 2);	
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0,0), CGPointMake(0,CGRectGetHeight(rect)-1), 0);
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorSpace);
        
        [SVSegmentedControlBG drawInRect:rect];
    }
    
    // 渲染阴影
	CGContextSetShadowWithColor(context, self.shadowOffset, 0, self.shadowColor.CGColor);
	
    // 文字部分
	[self.textColor set];
	CGFloat posY = ceil((CGRectGetHeight(rect)-self.font.pointSize+self.font.descender)/2)+self.titleEdgeInsets.top-self.titleEdgeInsets.bottom;
	int pointSize = self.font.pointSize;
	
	if (pointSize%2 != 0) {
		posY--;
    }
	
	int i = 0;
	for (NSString *titleString in self.titlesArray) {
        CGRect labelRect = CGRectMake((self.segmentWidth*i), posY, self.segmentWidth, self.font.pointSize);
		[titleString drawInRect:labelRect withFont:self.font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
		i++;
	}
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super beginTrackingWithTouch:touch withEvent:event];
    
    CGPoint cPos = [touch locationInView:self.thumb];
	self.activated = NO;
	
	self.snapToIndex = floor(self.thumb.center.x/self.segmentWidth);
	
	if (CGRectContainsPoint(self.thumb.bounds, cPos)) {
		self.trackingThumb = YES;
        [self.thumb deactivate];
		self.dragOffset = (self.thumb.frame.size.width/2)-cPos.x;
	}
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super continueTrackingWithTouch:touch withEvent:event];
    
    CGPoint cPos = [touch locationInView:self];
	CGFloat newPos = cPos.x+self.dragOffset;
	CGFloat newMaxX = newPos+(CGRectGetWidth(self.thumb.frame)/2);
	CGFloat newMinX = newPos-(CGRectGetWidth(self.thumb.frame)/2);
	
	CGFloat buffer = 2.0; // to prevent the thumb from moving slightly too far
	CGFloat pMaxX = CGRectGetMaxX(self.bounds) - buffer;
	CGFloat pMinX = CGRectGetMinX(self.bounds) + buffer;
	
	if ((newMaxX > pMaxX || newMinX < pMinX) && self.trackingThumb) {
		self.snapToIndex = floor(self.thumb.center.x/self.segmentWidth);
        
        if(newMaxX-pMaxX > 10 || pMinX-newMinX > 10) {
            self.moved = YES;
        }
        
		[self snap:NO];
        
		if (self.crossFadeLabelsOnDrag) {
			[self updateTitles];
        }
	} else if(self.trackingThumb) {
		self.thumb.center = CGPointMake(cPos.x+self.dragOffset, self.thumb.center.y);
		self.moved = YES;
        
		if (self.crossFadeLabelsOnDrag) {
			[self updateTitles];
        }
	}
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    
    CGPoint cPos = [touch locationInView:self];
	CGFloat pMaxX = CGRectGetMaxX(self.bounds);
	CGFloat pMinX = CGRectGetMinX(self.bounds);
	
	if (!self.moved && self.trackingThumb && [self.titlesArray count] == 2) {
		[self toggle];
    } else if(!self.activated && cPos.x > pMinX && cPos.x < pMaxX) {
		self.snapToIndex = floor(cPos.x/self.segmentWidth);
		[self snap:YES];
	} else {
        CGFloat posX = cPos.x;
        
        if (posX < pMinX) {
            posX = pMinX;
        }
        
        if (posX >= pMaxX) {
            posX = pMaxX-1;
        }
        
        self.snapToIndex = floor(posX/self.segmentWidth);
        [self snap:YES];
    }
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    
    if (self.trackingThumb) {
		[self snap:NO];
    }
}

- (void)snap:(BOOL)animated {
	[self.thumb deactivate];
    
    if (self.crossFadeLabelsOnDrag) {
        self.thumb.secondLabel.alpha = 0;
    }

	int index;
	if (self.snapToIndex != -1) {
		index = self.snapToIndex;
    } else {
		index = floor(self.thumb.center.x/self.segmentWidth);
    }
	
	self.thumb.label.text = [self.titlesArray objectAtIndex:index];

	if (animated) {
		[self moveThumbToIndex:index animate:YES];
    } else {
		self.thumb.frame = [[self.thumbRects objectAtIndex:index] CGRectValue];
    }
}

- (void)updateTitles {
	int hoverIndex = floor(self.thumb.center.x/self.segmentWidth);
	
	BOOL secondTitleOnLeft = ((self.thumb.center.x / self.segmentWidth) - hoverIndex) < 0.5;
	
	if (secondTitleOnLeft && hoverIndex > 0) {
		self.thumb.label.alpha = 0.5 + ((self.thumb.center.x / self.segmentWidth) - hoverIndex);
		self.thumb.secondLabel.text = [self.titlesArray objectAtIndex:hoverIndex - 1];
		self.thumb.secondLabel.alpha = 0.5 - ((self.thumb.center.x / self.segmentWidth) - hoverIndex);
	} else if (hoverIndex + 1 < self.titlesArray.count) {
		self.thumb.label.alpha = 0.5 + (1 - ((self.thumb.center.x / self.segmentWidth) - hoverIndex));
		self.thumb.secondLabel.text = [self.titlesArray objectAtIndex:hoverIndex + 1];
		self.thumb.secondLabel.alpha = ((self.thumb.center.x / self.segmentWidth) - hoverIndex) - 0.5;
	} else {
		self.thumb.secondLabel.text = nil;
		self.thumb.label.alpha = 1.0;
	}
	self.thumb.label.text = [self.titlesArray objectAtIndex:hoverIndex];
}

- (void)activate {
	
	self.trackingThumb = self.moved = NO;
	self.thumb.label.text = [self.titlesArray objectAtIndex:self.selectedIndex];
    	
	if (self.selectedSegmentChangedHandler) {
		self.selectedSegmentChangedHandler(self);
    }
    
    if ([self valueForKey:@"delegate"]) {
        id controlDelegate = [self valueForKey:@"delegate"];
        
        if([controlDelegate respondsToSelector:@selector(segmentedControl:didSelectIndex:)]) {
            [controlDelegate segmentedControl:self didSelectIndex:selectedIndex];
        }
    }

	[UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
                        self.activated = YES;
                        [self.thumb activate];
					 } completion:NULL];
}

- (void)toggle {
	if (self.snapToIndex == 0) {
		self.snapToIndex = 1;
    } else {
		self.snapToIndex = 0;
    }
	[self snap:YES];
}

- (void)moveThumbToIndex:(NSUInteger)segmentIndex animate:(BOOL)animate {
    self.selectedIndex = segmentIndex;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
	if (animate) {
        
        [self.thumb deactivate];
		
		[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut 
                         animations:^{
                            self.thumb.frame = [[self.thumbRects objectAtIndex:segmentIndex] CGRectValue];
                            if (self.crossFadeLabelsOnDrag) {
                                [self updateTitles];
                            }
                         } completion:^(BOOL finished){
							 [self activate];
						 }];
	} else {
		self.thumb.frame = [[self.thumbRects objectAtIndex:segmentIndex] CGRectValue];
		[self activate];
	}
}

- (void)setBackgroundImage:(UIImage *)newImage {
    if (backgroundImage) {
        [backgroundImage release], backgroundImage = nil;
    }
    
    if (newImage) {
        backgroundImage = [newImage retain];
        self.height = backgroundImage.size.height;
    }
}

- (void)setSegmentPadding:(CGFloat)newPadding {
    self.titleEdgeInsets = UIEdgeInsetsMake(0, newPadding, 0, newPadding);
}

- (void)dealloc {
	self.titlesArray = nil;
    self.selectedSegmentChangedHandler = nil;
    self.thumbRects = nil;
    
    [self setValue:nil forKey:@"delegate"];
    
	self.font = nil;
	self.textColor = nil;
	self.shadowColor = nil;
    self.backgroundImage = nil;
    [thumb release];
	
    [super dealloc];
}

@end