//
//  AudioFile.h
//  Choreographer
//
//  Created by Philippe Kocher on 24.08.09.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioToolbox.h>


@interface AudioFile : NSManagedObject
{
	AudioFileID audioFileID;
//	unsigned int sampleRate;
	unsigned int bytesPerPacket;
	UInt32 numOfFrames;
	
	NSUInteger duration;
	
	NSData *overviewData;
	NSImage *waveformImage;
	id progress;
}

@property AudioFileID audioFileID;

+ (AudioFileID)idOfAudioFileAtPath:(NSString *)filePath;
+ (AudioStreamBasicDescription)descriptionOfAudioFile:(AudioFileID)audioFileID;
+ (UInt64)dataPacketsOfAudioFile:(AudioFileID)audioFileID;
+ (NSUInteger)durationOfAudioFileAtPath:(NSString *)filePath;

+ (NSArray *)allowedFileTypes;

// accessor
- (AudioFileID)audioFileID;
- (void)setAudioFileID:(AudioFileID)fileID;

- (NSString *)filePathString;
- (BOOL)openAudioFile;
- (void)reopenAudioFile;
- (void)relinkAudioFile;
- (void)calculateOverviewImage;
- (void)calculateOverviewImageThread;
- (void)setOverviewData;

@end
