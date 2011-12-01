//
// SWSegmentedControl.h
// SWSegmentedControl
//
// Created by Sam Vermette on 26.10.10.
// Copyright 2010 Sam Vermette. All rights reserved.
//
// https://github.com/samvermette/SVSegmentedControl
//

#import <UIKit/UIKit.h>
#import "SVSegmentedThumb.h"
#import <AvailabilityMacros.h>

@protocol SVSegmentedControlDelegate;

@protocol SVSegmentedControlDelegate
- (void)segmentedControl:(SVSegmentedControl*)segmentedControl didSelectIndex:(NSUInteger)index;
@end

///////////////////////////////////////////////////

@interface SVSegmentedControl : UIControl

@property (nonatomic, assign) id<SVSegmentedControlDelegate> delegate DEPRECATED_ATTRIBUTE; // deprecated: use addTarget:action:forControlEvents: instead
@property (nonatomic, copy) void (^selectedSegmentChangedHandler)(id sender); // you can also use addTarget:action:forControlEvents:

@property (nonatomic, retain, readonly) SVSegmentedThumb *thumb;
@property (nonatomic, readwrite) UIEdgeInsets thumbEdgeInset; // default is UIEdgeInsetsMake(2, 2, 3, 2)
@property (nonatomic, readwrite) NSUInteger selectedIndex; // default is 0
@property (nonatomic, readwrite) BOOL animateToInitialSelection; // default is NO

@property (nonatomic, retain) UIImage *backgroundImage; // default is nil
@property (nonatomic, retain) UIFont *font; // default is [UIFont boldSystemFontOfSize:15]
@property (nonatomic, retain) UIColor *textColor; // default is [UIColor grayColor];
@property (nonatomic, retain) UIColor *shadowColor;  // default is [UIColor blackColor]
@property (nonatomic, readwrite) CGSize shadowOffset;  // default is CGSizeMake(0, -1)
@property (nonatomic, readwrite) CGFloat segmentPadding DEPRECATED_ATTRIBUTE; // deprecated: use titleEdgeInsets instead
@property (nonatomic, readwrite) UIEdgeInsets titleEdgeInsets; // default is UIEdgeInsetsMake(0, 10, 0, 10)
@property (nonatomic, readwrite) CGFloat height; // default is 32.0
@property (nonatomic, readwrite) BOOL crossFadeLabelsOnDrag; // default is NO

- (SVSegmentedControl*)initWithSectionTitles:(NSArray*)titlesArray;
- (void)moveThumbToIndex:(NSUInteger)segmentIndex animate:(BOOL)animate;

@end