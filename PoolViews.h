//
//  PoolViews.h
//  Choreographer
//
//  Created by Philippe Kocher on 17.02.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PoolViewController.h"

@interface PoolView : NSView
{
	IBOutlet id tabControl;
}
@end

@interface PoolOutlineView : NSOutlineView
{
	BOOL hasFocus;
}
@end

@interface PoolTableView : NSTableView
{
	BOOL hasFocus;
}
@end