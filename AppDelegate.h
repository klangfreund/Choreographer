//
//  AppDelegate.h
//  Choreographer
//
//  Created by Philippe Kocher on 11.06.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject
{
	IBOutlet NSWindow *startupSplashWindow;
	IBOutlet NSTextField *startupStatusTextField;
	IBOutlet NSView *openPanelAccessoryView;
	
	NSString *versionString;
	NSInteger projectSampleRate;
	
	id currentProjectDocument;
}

@property (assign) id currentProjectDocument;

- (IBAction)showArrangerWindow:(id)sender;
- (IBAction)showRadarEditorWindow:(id)sender;
- (IBAction)showTimelineEditorWindow:(id)sender;
- (IBAction)showTableEditorWindow:(id)sender;
- (IBAction)showMarkersWindow:(id)sender;

/*
- (IBAction) showTransportPanelAction: (id) sender ;
*/

@end
