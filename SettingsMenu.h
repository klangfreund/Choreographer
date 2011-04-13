//
//  SettingsMenu.h
//  Choreographer
//
//  Created by Philippe Kocher on 31.03.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SettingsMenu : NSMenu
{
	NSMutableDictionary *currentItems;
	NSMutableDictionary *models;
	NSMutableDictionary *keyPaths;
	NSMutableArray *highestIndexPerSection;
}

- (void)setModel:(id)aModel key:(NSString *)aString;
- (void)setModel:(id)aModel key:(NSString *)aString index:(NSInteger)i;
- (void)setModel:(id)aModel keyPath:(NSString *)aString;
- (void)setModel:(id)aModel keyPath:(NSString *)aString index:(NSInteger)i;
- (void)menuAction:(id)sender;

@end
