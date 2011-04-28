//
//  SettingsPopupButton.h
//  Choreographer
//
//  Created by Philippe Kocher on 09.06.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SettingsPopupButton : NSPopUpButton
{
	id currentItem;
	
	id model;
	NSString *keyPath;
	
	NSInteger selectedTag;	
}

- (void)setModel:(id)aModel key:(NSString *)aString;
- (void)setModel:(id)aModel keyPath:(NSString *)aString;
- (void)menuAction:(id)sender;

@end
