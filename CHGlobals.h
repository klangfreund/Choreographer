//
//  CHGlobals.h
//  Choreographer
//
//  Created by Philippe Kocher on 10.11.07.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//


// types for drag and drop
#define CHAudioItemType @"audio"
#define CHTrajectoryType @"trajectory"
#define CHFolderType @"folder"


#define AUDIO_BLOCK_HEIGHT 60
#define REGION_NAME_BLOCK_HEIGHT 16
#define REGION_TRAJECTORY_BLOCK_HEIGHT 16

#define TIMELINE_EDITOR_AUDIO_HEIGHT 60
#define TIMELINE_EDITOR_DATA_HEIGHT 60

#define MOUSE_POINTER_SIZE 5			// tolerance for hit detection in graphical breakpoint editors


#define ARRANGER_OFFSET 10		// display below 0



//___________________________________________________________________________________________________________________________

// type definitions
//___________________________________________________________________________________________________________________________

// Arranger Modes

typedef enum _ArrangerDisplayMode
{
	arrangerDisplayModeRegions = 0,
	arrangerDisplayModeGain
} ArrangerDisplayMode;


typedef enum _ArrangerEditMode
{
	arrangerModeNone = 0,
	arrangerModeSelectMultiple,
	arrangerModeDuplicate,
	arrangerModeMarquee,
	arrangerModeCropLeft,
	arrangerModeCropRight,
	arrangerModeCursor
} ArrangerEditMode;


//___________________________________________________________________________________________________________________________

// Editor Mode

typedef enum _EditorDisplayMode
{
	noDisplayMode = 0,
	locatorDisplayMode = 1,
	regionDisplayMode = 2,
	trajectoryDisplayMode = 3
} EditorDisplayMode;


//___________________________________________________________________________________________________________________________

// Trajectory Type

typedef enum _TrajectoryType
{
	notSet = -1,
	breakpointType = 0,
	rotationType,
	randomType,
	externalType
} TrajectoryType;


//___________________________________________________________________________________________________________________________

// Modifiers

typedef enum _Modifiers
{
	modifierNone = 0,
	modifierShift, modifierControl, modifierAlt, modifierCommand,
	modifierAltCommand,
	modifierShiftAltCommand
} Modifiers;



