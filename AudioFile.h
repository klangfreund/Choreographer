//
//  AudioFile.h
//  Choreographer
//
//  Created by Philippe Kocher on 24.08.09.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>


@interface AudioFile : NSManagedObject
{
	CFURLRef fileRef;
	AudioFileID audioFileID;
	unsigned int sampleRate;
	unsigned int bytesPerPacket;
	UInt32 numOfFrames;
	
	NSUInteger duration;
	
	NSData *overviewData;
	NSImage *waveformImage;
	id progress;
}

- (BOOL)openAudioFile;
- (void)calculateOverviewImage;
- (void)calculateOverviewImageThread;
- (void)setOverviewData;

@end
