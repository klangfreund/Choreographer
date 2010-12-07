//
//  ProgressPanel.h
//  Choreographer
//
//  Created by Philippe Kocher on 11.12.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProgressPanel : NSWindow
{
	NSView			*contentView;
	NSMutableArray	*progressSubviews;
}

+ (id)sharedProgressPanel;

- (id)addProgressWithTitle:(NSString *)title;
- (void)setProgressValue:(float)theValue forProgress:(id)progress;
- (void)removeProgress:(id)theProgress;
- (void)recalcSize:(NSArray *)subviews;

@end


@interface ProgressSubview : NSView
{
	NSTextField *textField;
	NSProgressIndicator	*progressIndicator;
}

- (id)initWithFrame:(NSRect)frame andText:(NSString *)text;
- (void)setProgressValue:(float)theValue;
@end
