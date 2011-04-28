//
//  PatchbayView.m
//  Choreographer
//
//  Created by Philippe Kocher on 29.09.10.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "PatchbayView.h"
#import "AudioEngine.h"


@implementation PatchbayView

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code here.
		[self reset];
    }
    return self;
}

- (void)reset
{
	selectedOutputChannel = -1;
	selectedOutputChannelPin = -1;
	selectedhardwareDeviceOutputChannelPin = -1;
	selectedPatchCord = -1;
}

#pragma mark -
#pragma mark drawing
// -----------------------------------------------------------

#define patchbayBoxHeight 25
#define patchbayTopOffset 5

#define patchbayHardwarePinX 705
#define patchbayOutputPinX 625
#define patchbayPinSize 10

- (BOOL)isFlipped
{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect r;
	NSPoint p1, p2;
	int i;
	
	// boxes
	
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	
	for(i=0;i<numberOfOutputChannels;i++)
	{
		r = NSMakeRect(10, i * patchbayBoxHeight + patchbayTopOffset, 620, patchbayBoxHeight);
		if(i == selectedOutputChannel)
		{
			[[NSColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
			[NSBezierPath fillRect:r];
		}
		[[NSColor blackColor] set];	
		[NSBezierPath strokeRect:r];
		
		r = NSMakeRect(patchbayOutputPinX, i * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5 - patchbayPinSize * 0.5, patchbayPinSize, patchbayPinSize);
		
		if(i != selectedOutputChannelPin)
			[[NSColor whiteColor] set];	
		
		[NSBezierPath fillRect:r];
		[[NSColor blackColor] set];	
		[NSBezierPath strokeRect:r];
	}
	for(i=0;i<numberOfhardwareDeviceOutputChannels;i++)
	{
		r = NSMakeRect(patchbayHardwarePinX + 5, i * patchbayBoxHeight + patchbayTopOffset, 100, patchbayBoxHeight);
		[[NSColor blackColor] set];	
		[NSBezierPath strokeRect:r];

		r = NSMakeRect(patchbayHardwarePinX, i * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5 - patchbayPinSize * 0.5, patchbayPinSize, patchbayPinSize);

		if(i != selectedhardwareDeviceOutputChannelPin)
			[[NSColor whiteColor] set];	
		
		[NSBezierPath fillRect:r];
		[[NSColor blackColor] set];	
		[NSBezierPath strokeRect:r];
	}
	for(i=numberOfhardwareDeviceOutputChannels;i<expectedNumberOfhardwareDeviceOutputChannels;i++)
	{
		r = NSMakeRect(patchbayHardwarePinX + 5, i * patchbayBoxHeight + patchbayTopOffset, 100, patchbayBoxHeight);
		[[NSColor grayColor] set];	
		[NSBezierPath strokeRect:r];
		
		r = NSMakeRect(patchbayHardwarePinX, i * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5 - patchbayPinSize * 0.5, patchbayPinSize, patchbayPinSize);
		
		[[NSColor whiteColor] set];	
		[NSBezierPath fillRect:r];
		[[NSColor grayColor] set];	
		[NSBezierPath strokeRect:r];
	}
		
	// text labels
	
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	
	NSString *label;
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	[attrs setObject:[NSFont systemFontOfSize: 18] forKey:NSFontAttributeName];

	for(i=0;i<numberOfOutputChannels;i++)
	{
		r = NSMakeRect(20, i * patchbayBoxHeight + patchbayTopOffset + 2, 40, 22);
		label = [NSString stringWithFormat:@"%d",i+1];
		[label drawInRect:r withAttributes:attrs];
	}
	for(i=0;i<numberOfhardwareDeviceOutputChannels;i++)
	{
		r = NSMakeRect(patchbayHardwarePinX + 20, i * patchbayBoxHeight + patchbayTopOffset + 2, 40, 22);
		label = [NSString stringWithFormat:@"%d",i+1];
		[label drawInRect:r withAttributes:attrs];
	}
	for(i=numberOfhardwareDeviceOutputChannels;i<expectedNumberOfhardwareDeviceOutputChannels;i++)
	{
		[attrs setObject:[NSColor lightGrayColor] forKey:NSForegroundColorAttributeName];

		r = NSMakeRect(patchbayHardwarePinX + 20, i * patchbayBoxHeight + patchbayTopOffset + 2, 40, 22);
		label = [NSString stringWithFormat:@"%d",i+1];
		[label drawInRect:r withAttributes:attrs];
	}
	

	// patch cords
	int hardwareDeviceOutputChannel;
	
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	for(i=0;i<numberOfOutputChannels;i++)
	{
		if(-1 != (hardwareDeviceOutputChannel = [[[speakerSetupPreset speakerChannelAtIndex:i] valueForKey:@"hardwareDeviceOutputChannel"] intValue]))
		{
			p1 = NSMakePoint(patchbayOutputPinX + patchbayPinSize * 0.5, i * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5);
			p2 = NSMakePoint(patchbayHardwarePinX + patchbayPinSize * 0.5, hardwareDeviceOutputChannel * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5);
		
			if(i == selectedPatchCord)
			{
				[[NSColor purpleColor] set];
				[NSBezierPath setDefaultLineWidth:3.0];
				[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
				[NSBezierPath setDefaultLineWidth:1.0];

				r = NSMakeRect(p1.x - patchbayPinSize * 0.4, p1.y - patchbayPinSize * 0.4, patchbayPinSize * 0.8, patchbayPinSize * 0.8);
				[[NSBezierPath bezierPathWithOvalInRect:r] fill];
				
				r = NSMakeRect(p2.x - patchbayPinSize * 0.4, p2.y - patchbayPinSize * 0.4, patchbayPinSize * 0.8, patchbayPinSize * 0.8);
				[[NSBezierPath bezierPathWithOvalInRect:r] fill];
			}
			else
			{
				[[NSColor blueColor] set];
				[NSBezierPath strokeLineFromPoint:p1 toPoint:p2];

				r = NSMakeRect(p1.x - patchbayPinSize * 0.25, p1.y - patchbayPinSize * 0.25, patchbayPinSize * 0.5, patchbayPinSize * 0.5);
				[[NSBezierPath bezierPathWithOvalInRect:r] fill];
				
				r = NSMakeRect(p2.x - patchbayPinSize * 0.25, p2.y - patchbayPinSize * 0.25, patchbayPinSize * 0.5, patchbayPinSize * 0.5);
				[[NSBezierPath bezierPathWithOvalInRect:r] fill];
			}
			
		}
	}

	if(-1 != selectedOutputChannelPin && patchCordDraggingType == fromChannelToHardware)
	{
		p1 = NSMakePoint(patchbayOutputPinX + patchbayPinSize * 0.5, selectedOutputChannelPin * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5);
		[[NSColor blueColor] set];	
		[NSBezierPath strokeLineFromPoint:p1 toPoint:draggingCurrentPosition];
	}

	if(-1 != selectedhardwareDeviceOutputChannelPin && patchCordDraggingType == fromHardwareToChannel)
	{
		p1 = NSMakePoint(patchbayHardwarePinX + patchbayPinSize * 0.5, selectedhardwareDeviceOutputChannelPin * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5);
		[[NSColor blueColor] set];	
		[NSBezierPath strokeLineFromPoint:p1 toPoint:draggingCurrentPosition];
	}
}

#pragma mark -
#pragma mark mouse events
// -----------------------------------------------------------

- (void)mouseDown:(NSEvent *)event
{
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	draggingCurrentPosition = localPoint;

	NSRect r;
	int i;
	
	if(-1 != (selectedOutputChannelPin = [self outputPinUnderPoint:localPoint]))
	{
		patchCordDraggingType = fromChannelToHardware;
		selectedPatchCord = selectedOutputChannelPin;
	}
	else if(-1 != (selectedhardwareDeviceOutputChannelPin = [self hardwarePinUnderPoint:localPoint]))
	{
		patchCordDraggingType = fromHardwareToChannel;
	}
	else
	{
		selectedOutputChannel = -1;
		selectedPatchCord = -1;
		for(i=0;i<numberOfOutputChannels;i++)
		{
			r = NSMakeRect(10, i * patchbayBoxHeight + patchbayTopOffset, 620, patchbayBoxHeight);
		
			if(NSPointInRect(localPoint, r))
			{
				selectedOutputChannel = i;
				break;
			}
		}
	}
	
	[self setNeedsDisplay:YES];
}


- (void)mouseDragged:(NSEvent *)event
{
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	draggingCurrentPosition = localPoint;
	int i;
	SpeakerChannel *channel;

	if(patchCordDraggingType == fromChannelToHardware)
	{
		selectedhardwareDeviceOutputChannelPin = [self hardwarePinUnderPoint:localPoint];		
		if(-1 != selectedhardwareDeviceOutputChannelPin)
		{
			for(i=0;i<[speakerSetupPreset countSpeakerChannels];i++)
			{
				channel = [speakerSetupPreset speakerChannelAtIndex:i];
				if(selectedhardwareDeviceOutputChannelPin == [[channel valueForKey:@"hardwareDeviceOutputChannel"] intValue])
				{
					// there is a channel already connected to this hardware output
					selectedhardwareDeviceOutputChannelPin = -1;
					break;
				}
			}
		}
	}
	if(patchCordDraggingType == fromHardwareToChannel) selectedOutputChannelPin = [self outputPinUnderPoint:localPoint];

	[self setNeedsDisplay:YES];
}


- (void)mouseUp:(NSEvent *)theEvent
{
	if(-1 != selectedOutputChannelPin && -1 != selectedhardwareDeviceOutputChannelPin)
	{
		[[speakerSetupPreset speakerChannelAtIndex:selectedOutputChannelPin] setValue:[NSNumber numberWithInt:selectedhardwareDeviceOutputChannelPin] forKey:@"hardwareDeviceOutputChannel"];
	}
	
	selectedOutputChannelPin = -1;
	selectedhardwareDeviceOutputChannelPin = -1;

	[self setNeedsDisplay:YES];
}


- (int)outputPinUnderPoint:(NSPoint)localPoint
{
	NSRect r;
	int i;

	for(i=0;i<numberOfOutputChannels;i++)
	{
		r = NSMakeRect(patchbayOutputPinX, i * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5 - patchbayPinSize * 0.5, patchbayPinSize, patchbayPinSize);
		
		if(NSPointInRect(localPoint, r))
		{
			return i;
		}
	}
	
	return -1;
}

- (int)hardwarePinUnderPoint:(NSPoint)localPoint
{
	NSRect r;
	int i;
	
	for(i=0;i<numberOfhardwareDeviceOutputChannels;i++)
	{
		r = NSMakeRect(patchbayHardwarePinX, i * patchbayBoxHeight + patchbayTopOffset + patchbayBoxHeight * 0.5 - patchbayPinSize * 0.5, patchbayPinSize, patchbayPinSize);
		
		if(NSPointInRect(localPoint, r))
		{
			return i;
		}
	}
	
	return -1;
}

- (int)patchCordUnderPoint:(NSPoint)localPoint
{
	
	return -1;
}


#pragma mark -
#pragma mark keyboard events
// -----------------------------------------------------------

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)event
{
	unsigned short keyCode = [event keyCode];
//	NSLog(@"Patchbay View key code: %d ", keyCode);
		
	switch(keyCode)
	{
			// delete
		case 117:
			// backspace
		case 51:
			
			if(-1 != selectedPatchCord)
			{
				[[speakerSetupPreset speakerChannelAtIndex:selectedPatchCord] setValue:[NSNumber numberWithInt:-1] forKey:@"hardwareDeviceOutputChannel"];
			}
			break;
			
			// tab
		case 48:
			break;
			
			// esc
		case 53:
			[self reset];
			break;
	}
	
	[self setNeedsDisplay:YES];
}

@end
