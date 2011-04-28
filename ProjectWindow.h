//
//  ProjectWindow.h
//  Choreographer
//
//  Created by Philippe Kocher on 04.06.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CHProjectDocument.h"
#import "RulerScrollView.h"
#import "ArrangerScrollView.h"


@interface ProjectWindow : NSWindow
{
	IBOutlet CHProjectDocument *document;
	IBOutlet id playbackController;
    
	IBOutlet RulerScrollView			*rulerScrollView;
    IBOutlet ArrangerScrollView			*arrangerScrollView;
	
	IBOutlet id	CPUTextField;

}

@end

