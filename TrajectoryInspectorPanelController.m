//
//  TrajectoryInspectorPanelController.m
//  Choreographer
//
//  Created by Philippe Kocher on 17.08.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import "TrajectoryInspectorPanelController.h"


static TrajectoryInspectorPanelController *sharedTrajectoryInspectorPanelController = nil;

@implementation TrajectoryInspectorPanelController

#pragma mark -
#pragma mark singleton
// -----------------------------------------------------------

+ (id)sharedTrajectoryInspectorPanelController
{
    if (!sharedTrajectoryInspectorPanelController)
	{
        sharedTrajectoryInspectorPanelController = [[TrajectoryInspectorPanelController alloc] initWithWindowNibName:@"TrajectoryInspector"];
    }
    return sharedTrajectoryInspectorPanelController;
}

#pragma mark -
#pragma mark initialisation and setup
// -----------------------------------------------------------

- (void)awakeFromNib
{
}

- (BOOL)newTrajectoryPanel
{
	// show window
	[self showWindow:nil];
	[self adjustPanelSize];

	// initialise fields
	initialPosition = [[[Breakpoint alloc] init] autorelease];
	centre = [[[SpatialPosition alloc] init] autorelease];
	boundingVolumePoint1 = [[[SpatialPosition alloc] init] autorelease];
	boundingVolumePoint2 = [[[SpatialPosition alloc] init] autorelease];
	
	[self setXYZ:initialPositionXYZFields AED:initialPositionAEDFields position:[initialPosition position]];
	[self setXYZ:centreXYZFields AED:centreAEDFields position:centre];
	durationInMiliseconds = 1000;
	[durationField setFloatValue:durationInMiliseconds * 0.001];
	
	if (!name)
	{
		[nameField setStringValue:@"untitled trajectory"];
	}
	else
	{
		[nameField setStringValue:name];
	}
	
	
	// rotation
	rotationSpeed = 1;
	
	// bounding volume
	boundingVolumePoint1.x = boundingVolumePoint1.y = -0.5;
	boundingVolumePoint1.z = 0;

	boundingVolumePoint2.x = boundingVolumePoint2.y = boundingVolumePoint2.z = 0.5;

	[[boundingBoxFields cellWithTag:0] setFloatValue:1.0];
	[[boundingBoxFields cellWithTag:1] setFloatValue:1.0];
	[[boundingBoxFields cellWithTag:2] setFloatValue:1.0];
	
	// run modal dialog
	[NSApp runModalForWindow:newTrajectoryPanel];

	return !cancel;
}


#pragma mark -
#pragma mark actions
// -----------------------------------------------------------

// the selected tab = trajectory type
- (IBAction)tabViewSelection:(id)sender
{
	trajectoryType = [sender selectedSegment];
	
	if(trajectoryType == 1 || trajectoryType == 2)
	{
		[adaptiveInitialPositionCheckbox setState:1];
		[self adaptiveFlag:adaptiveInitialPositionCheckbox];
	}
	
	[self adjustPanelSize];
}

// initial position
- (IBAction)initialPositionXYZ:(id)sender
{
	SpatialPosition *pos = [initialPosition position];
	pos.x = [[initialPositionXYZFields cellWithTag:0] floatValue];
	pos.y = [[initialPositionXYZFields cellWithTag:1] floatValue];
	pos.z = [[initialPositionXYZFields cellWithTag:2] floatValue];
	
	[pos cartopol];
		
	[self setXYZ:initialPositionXYZFields AED:initialPositionAEDFields position:pos];
}

- (IBAction)initialPositionAED:(id)sender
{
	SpatialPosition *pos = [initialPosition position];
	pos.a = [[initialPositionAEDFields cellWithTag:0] floatValue];
	pos.e = [[initialPositionAEDFields cellWithTag:1] floatValue];
	pos.d = [[initialPositionAEDFields cellWithTag:2] floatValue];
	
	[pos poltocar];
	
	[self setXYZ:initialPositionXYZFields AED:initialPositionAEDFields position:pos];
}

- (IBAction)adaptiveFlag:(id)sender;
{	
	BOOL state = [sender state];

	adaptiveInitialPosition = state;

	[initialPositionXYZFields setEnabled:!state];
	[initialPositionAEDFields setEnabled:!state];
}

// specific parameters
- (IBAction)duration:(id)sender
{
	durationInMiliseconds = [sender floatValue] < 0.001 ? 1 : [sender floatValue] * 1000;
	[durationField setFloatValue:durationInMiliseconds * 0.001];
}

- (IBAction)rotationSpeed:(id)sender { rotationSpeed = [sender floatValue]; }

- (IBAction)minRandomSpeed:(id)sender { minRandomSpeed = [sender floatValue]; }
- (IBAction)maxRandomSpeed:(id)sender { maxRandomSpeed = [sender floatValue]; }
- (IBAction)randomStability:(id)sender { randomStability = [sender floatValue]; }

	
// centre (rotation and random)
- (IBAction)centreXYZ:(id)sender
{
	centre.x = [[centreXYZFields cellWithTag:0] floatValue];
	centre.y = [[centreXYZFields cellWithTag:1] floatValue];
	centre.z = [[centreXYZFields cellWithTag:2] floatValue];
	
	[centre cartopol];
	
	[self setXYZ:centreXYZFields AED:centreAEDFields position:centre];
}

- (IBAction)centreAED:(id)sender
{
	centre.a = [[centreAEDFields cellWithTag:0] floatValue];
	centre.e = [[centreAEDFields cellWithTag:1] floatValue];
	centre.d = [[centreAEDFields cellWithTag:2] floatValue];
	
	[centre poltocar];
	
	[self setXYZ:centreXYZFields AED:centreAEDFields position:centre];
}

// bounding box (random)
- (IBAction)boundingBox:(id)sender
{
	float x = [[boundingBoxFields cellWithTag:0] floatValue];
	float y = [[boundingBoxFields cellWithTag:1] floatValue];
	float z = [[boundingBoxFields cellWithTag:2] floatValue];
	
	boundingVolumePoint1.x = centre.x - x * 0.5;
	boundingVolumePoint1.y = centre.y - y * 0.5;
	boundingVolumePoint1.z = centre.z - z * 0.5;

	boundingVolumePoint2.x = centre.x + x * 0.5;
	boundingVolumePoint2.y = centre.y + y * 0.5;
	boundingVolumePoint2.z = centre.z + z * 0.5;
}

- (IBAction)cancelButton:(id)sender;
{
	[NSApp stopModal];
	[newTrajectoryPanel close];
	cancel = YES;
}

- (IBAction)newButton:(id)sender;
{
	[NSApp stopModal];
	[newTrajectoryPanel close];
	cancel = NO;
}

#pragma mark -
#pragma mark misc
// -----------------------------------------------------------

- (void)setXYZ:(NSForm *)theXYZForm AED:(NSForm *)theAEDForm position:(SpatialPosition *)thePosition
{
	[[theXYZForm cellWithTag:0] setFloatValue:thePosition.x];
	[[theXYZForm cellWithTag:1] setFloatValue:thePosition.y];
	[[theXYZForm cellWithTag:2] setFloatValue:thePosition.z];

	[[theAEDForm cellWithTag:0] setFloatValue:thePosition.a];
	[[theAEDForm cellWithTag:1] setFloatValue:thePosition.e];
	[[theAEDForm cellWithTag:2] setFloatValue:thePosition.d];
}


- (void)adjustPanelSize
{
	NSRect frame = [newTrajectoryPanel frame];

	switch (trajectoryType)
	{
		case 0:
			[breakpointParameterPanel setHidden:NO];
			[breakpointParameterPanel setFrameOrigin:NSMakePoint(26,  frame.size.height - 320)];
			[rotationParameterPanel setHidden:YES];
			[randomParameterPanel setHidden:YES];
			[centreFieldsPanel setHidden:YES];
			[boundingBoxFieldsPanel setHidden:YES];
			frame.size.height = 330;
			break;
		case 1:
			[breakpointParameterPanel setHidden:YES];
			[rotationParameterPanel setHidden:NO];
			[rotationParameterPanel setFrameOrigin:NSMakePoint(26,  frame.size.height - 320)];
			[randomParameterPanel setHidden:YES];
			[centreFieldsPanel setHidden:NO];
			[centreFieldsPanel setFrameOrigin:NSMakePoint(22, frame.size.height - 410)];
			[boundingBoxFieldsPanel setHidden:YES];
			frame.size.height = 420;
			break;
		case 2:
			[breakpointParameterPanel setHidden:YES];
			[rotationParameterPanel setHidden:YES];
			[randomParameterPanel setHidden:NO];
			[randomParameterPanel setFrameOrigin:NSMakePoint(26, frame.size.height - 360)];
			[centreFieldsPanel setHidden:NO];
			[centreFieldsPanel setFrameOrigin:NSMakePoint(22, frame.size.height - 450)];
			[boundingBoxFieldsPanel setHidden:NO];
			[boundingBoxFieldsPanel setFrameOrigin:NSMakePoint(22, frame.size.height - 520)];
			frame.size.height = 530;
			break;
		default:
			[breakpointParameterPanel setHidden:YES];
			[rotationParameterPanel setHidden:YES];
			[randomParameterPanel setHidden:YES];
			[centreFieldsPanel setHidden:YES];
			[boundingBoxFieldsPanel setHidden:YES];
			frame.size.height = 400;
	}
		
	[newTrajectoryPanel setFrame:frame display:YES animate:YES];

}

#pragma mark -
#pragma mark getters
// -----------------------------------------------------------

- (NSString *)name { return [nameField stringValue]; }

- (void)configureTrajectory:(id)trajectoryItem;
{
	// type
	[trajectoryItem setValue:[NSNumber numberWithInt:trajectoryType] forKey:@"trajectoryType"];
	id trajectory = [trajectoryItem valueForKey:@"trajectory"];
	
	// initial position
	[trajectoryItem setValue:[NSNumber numberWithBool:adaptiveInitialPosition] forKey:@"adaptiveInitialPosition"];
	
	switch (trajectoryType)
	{
		case breakpointType:
			[trajectory setValue:[NSNumber numberWithUnsignedLong:durationInMiliseconds] forKey:@"duration"];
			break;

		case rotationType:
			[trajectory setValue:initialPosition forKey:@"initialPosition"];
			[trajectory setValue:centre forKey:@"rotationCentre"];
			[trajectory setValue:[NSNumber numberWithFloat:rotationSpeed] forKey:@"speed"];
			break;

		case randomType:
			[trajectory setValue:initialPosition forKey:@"initialPosition"];

			[trajectory setValue:boundingVolumePoint1 forKey:@"boundingVolumePoint1"];
			[trajectory setValue:boundingVolumePoint2 forKey:@"boundingVolumePoint2"];

			[trajectory setValue:[NSNumber numberWithFloat:minRandomSpeed] forKey:@"minSpeed"];
			[trajectory setValue:[NSNumber numberWithFloat:maxRandomSpeed] forKey:@"maxSpeed"];
			[trajectory setValue:[NSNumber numberWithFloat:randomStability] forKey:@"stability"];
			break;
	}
	
	[trajectoryItem archiveData];

}

@end
