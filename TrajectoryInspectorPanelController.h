//
//  TrajectoryInspectorPanelController.h
//  Choreographer
//
//  Created by Philippe Kocher on 17.08.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SpatialPosition.h"
#import "TrajectoryItem.h"
#import "CHGlobals.h"

//typedef struct _BoundingVolume
//{
//	int		type;
//	float	x, y, z;
//	float   angle, aperture;
//} BoundingVolume;


@interface TrajectoryInspectorPanelController : NSWindowController
{
	IBOutlet id newTrajectoryPanel;

	IBOutlet id initialPositionXYZFields;
	IBOutlet id initialPositionAEDFields;
	IBOutlet id adaptiveInitialPositionCheckbox;

	IBOutlet id durationField;

	IBOutlet id breakpointParameterPanel;
	IBOutlet id rotationParameterPanel;
	IBOutlet id randomParameterPanel;

	IBOutlet id centreXYZFields;
	IBOutlet id centreAEDFields;
	IBOutlet id centreFieldsPanel;

	IBOutlet id boundingBoxFields;
	IBOutlet id boundingBoxFieldsPanel;

	IBOutlet id nameField;

	BOOL cancel;
	
	NSString			*name;
	int					trajectoryType;	
	SpatialPosition		*initialPosition;
	BOOL				adaptiveInitialPosition;
	unsigned long		durationInMiliseconds;
	float				rotationSpeed;
	float				minRandomSpeed, maxRandomSpeed;
	unsigned long		randomStability;
	SpatialPosition		*centre;
	int					boundingVolumeType;
	SpatialPosition		*boundingVolumePoint1, *boundingVolumePoint2;

}


+ (id)sharedTrajectoryInspectorPanelController;

- (BOOL)newTrajectoryPanel;

// "New Trajectory" panel methods
// -------------------------------------------------

- (IBAction)tabViewSelection:(id)sender;

- (IBAction)initialPositionXYZ:(id)sender;
- (IBAction)initialPositionAED:(id)sender;
- (IBAction)adaptiveFlag:(id)sender;

- (IBAction)duration:(id)sender;
- (IBAction)rotationSpeed:(id)sender;
- (IBAction)minRandomSpeed:(id)sender;
- (IBAction)maxRandomSpeed:(id)sender;
- (IBAction)randomStability:(id)sender;

- (IBAction)centreXYZ:(id)sender;
- (IBAction)centreAED:(id)sender;
- (IBAction)boundingBox:(id)sender;


- (void)setXYZ:(NSForm *)theXYZForm AED:(NSForm *)theAEDForm position:(SpatialPosition *)thePosition;

- (IBAction)cancelButton:(id)sender;
- (IBAction)newButton:(id)sender;

- (void)adjustPanelSize;

// getters
- (NSString *)name;
- (void)configureTrajectory:(id)trajectoryItem;


@end
