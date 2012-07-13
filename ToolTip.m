//
//  ToolTip.m
//  Choreographer
//
//  Created by Philippe Kocher on 19.10.07.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "ToolTip.h"

@implementation ToolTipTextField

- (void)drawRect:(NSRect)aRect
{
    [super drawRect:aRect];
    
    [[NSColor colorWithCalibratedWhite:0.925 alpha:1.0] set];
    NSFrameRect(aRect);
}

@end


static ToolTip	*sharedToolTip = nil;


@implementation ToolTip
+ (id)sharedToolTip
{
	if (!sharedToolTip)
	{
		sharedToolTip = [[ToolTip alloc] init];
	}
	return sharedToolTip;
}

+ (void)dispose
{
    [sharedToolTip dealloc];
    sharedToolTip = nil;
}

- (id)init
{    
   if((self = [super init]))
   {
        // These size are not really important, just the relation between the two...
        NSRect	contentRect		= {{ 300, 100 },{ 100, 20 }};
        NSRect	textFieldFrame	= NSMakeRect(0,0,100,20);
        
        window = [[NSWindow alloc] initWithContentRect: contentRect
								   styleMask: NSBorderlessWindowMask
								   backing: NSBackingStoreBuffered
                                   defer: YES];
        
        [window setOpaque:NO];
        [window setAlphaValue:0.80];
        [window setBackgroundColor:[NSColor colorWithDeviceRed:1.0 green:0.96 blue:0.76 alpha:1.0]];
        [window setHasShadow:YES];
        [window setLevel:NSStatusWindowLevel];
        [window setReleasedWhenClosed:YES];
        
        textField = [[ToolTipTextField alloc] initWithFrame:textFieldFrame];
        [textField setEditable:NO];
        [textField setSelectable:NO];
        [textField setBezeled:NO];
        [textField setBordered:NO];
        [textField setDrawsBackground:NO];
		[textField setAlignment:NSCenterTextAlignment];
        [textField setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[textField setFont: [NSFont systemFontOfSize:11]];
        [[window contentView] addSubview:textField];
        
        [textField setStringValue:@" "]; // next message requires at least 1 char...
        textAttributes = [[[textField attributedStringValue] attributesAtIndex:0 effectiveRange:nil] retain];

   
   
   
       // Start watching events
	   eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask: NSLeftMouseDraggedMask
															handler:^(NSEvent *incommingEvent)
															{
																event = incommingEvent;
																return event;
															}];
   }
   
   return self;
}

- (void)dealloc
{
    [window release];
    [textAttributes release];
    [textField release];

//	NSLog(@"removeMonitor");
	[NSEvent removeMonitor:eventMonitor];

	[super dealloc];
}

- (void)setString:(NSString *)string inView:(NSView *)view
{
    NSSize size = [string sizeWithAttributes:textAttributes];
	NSPoint cursorPositionOnScreen = [[event window] convertBaseToScreen:[event locationInWindow]];
	NSPoint cursorPositionInView = [view convertPoint:[event locationInWindow] fromView:nil];

	NSRect viewFrame = [view visibleRect];

	[textField setStringValue:string];
	[window setContentSize:NSMakeSize(size.width + 20, size.height + 1)];
	[window setFrameTopLeftPoint:NSMakePoint(cursorPositionOnScreen.x + 10, cursorPositionOnScreen.y + 10)];
	
	if(NSPointInRect(cursorPositionInView, viewFrame) && event)
		[window orderFront:nil];
	else
		[window orderOut:nil];		
}

@end