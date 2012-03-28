//
//  AudioFile.m
//  Choreographer
//
//  Created by Philippe Kocher on 24.08.09.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "AudioFile.h"
#import "ProgressPanel.h"


@implementation AudioFile


#pragma mark -
#pragma mark class methods

+ (AudioFileID)idOfAudioFileAtPath:(NSString *)filePath
{
	AudioFileID audioFileID;
	
	// make CFURLRef from path
	const char *path = [filePath cStringUsingEncoding:NSASCIIStringEncoding];
	CFURLRef fileRef = CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault, (UInt8 *)path, strlen(path), false);
	
	// open audio file
	memset(&audioFileID, 0, sizeof(AudioFileID));
	/* OSStatus err = */AudioFileOpenURL(fileRef, fsRdPerm, 0, &audioFileID);
	
	return audioFileID;
}


+ (AudioStreamBasicDescription)descriptionOfAudioFile:(AudioFileID)audioFileID;
{
	OSStatus err;
	AudioStreamBasicDescription basicDescription;
	UInt32 propsize = sizeof(AudioStreamBasicDescription);
	
	memset(&basicDescription, 0, propsize);
	
	if(audioFileID)
	{
		err = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &propsize, &basicDescription);
		NSAssert1(!err,@"AudioFileGetProperty failed with error %i",err);
	}

		//				printf("AUDIO FILE...\n");
		//				printf("SampleRate %f\n",basicDescription.mSampleRate);
		//				printf("FormatID %ld\n",basicDescription.mFormatID);
		//				printf("FormatFlags %ld\n",basicDescription.mFormatFlags);
		//				printf("BytesPerPacket %ld\n",basicDescription.mBytesPerPacket);
		//				printf("FramesPerPacket %ld\n",basicDescription.mFramesPerPacket);
		//				printf("BytesPerFrame %ld\n",basicDescription.mBytesPerFrame);
		//				printf("ChannelsPerFrame %ld\n",basicDescription.mChannelsPerFrame);

	return basicDescription;
}

+ (UInt64)dataPacketsOfAudioFile:(AudioFileID)audioFileID;
{
	OSStatus err;

	UInt64 dataPackets;						
	UInt32 propsize = sizeof(UInt64);

	err = AudioFileGetProperty(audioFileID,
							   kAudioFilePropertyAudioDataPacketCount,
							   &propsize,
							   &dataPackets);
	
	return dataPackets;
}

+ (NSUInteger)durationOfAudioFileAtPath:(NSString *)filePath
{
	AudioFileID audioFileID = [AudioFile idOfAudioFileAtPath:filePath];

	if(!audioFileID)
		return 0;

	AudioStreamBasicDescription basicDescription = [AudioFile descriptionOfAudioFile:audioFileID];
	UInt64 dataPackets = [AudioFile dataPacketsOfAudioFile:audioFileID];
	
	// duration
	NSUInteger duration = dataPackets * basicDescription.mFramesPerPacket / basicDescription.mSampleRate * 1000;
	
	return duration;
}

+ (NSArray *)allowedFileTypes
{
    return [NSArray arrayWithObjects: @"sd2", @"AIFF", @"aif", @"aiff", @"aifc", @"wav", @"WAV", NULL];
}


#pragma mark -
#pragma mark life cycle

- (void)awakeFromInsert
{
	[super awakeFromInsert];
	//NSLog(@"AudioFile %x awakeFromInsert", self);
}

- (void)awakeFromFetch
{
	[super awakeFromFetch];
	//NSLog(@"AudioFile awakeFromFetch, path: %@", [self valueForKey:@"relativeFilePath"]);
	[self reopenAudioFile];
}

- (void)dealloc
{
	NSLog(@"AudioFile: dealloc");
	[super dealloc];
	[waveformImage dealloc];
}

#pragma mark -
#pragma mark accessors

- (AudioFileID)audioFileID
{
    if(audioFileID) return audioFileID;
    
	audioFileID = [AudioFile idOfAudioFileAtPath:[self filePathString]];
    return audioFileID;
}

- (void)setAudioFileID:(AudioFileID)fileID
{}


#pragma mark -
#pragma mark file

- (NSString *)filePathString
{
	NSDocument *document = [[NSApplication sharedApplication] valueForKeyPath:@"delegate.currentProjectDocument"];
	return [[NSURL URLWithString:[self valueForKey:@"relativeFilePath"] relativeToURL:[document fileURL]] path];
}


- (BOOL)openAudioFile
{	
	audioFileID = [AudioFile idOfAudioFileAtPath:[self filePathString]];

	// file successfully opened?
	if(!audioFileID)
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"Unreadable audio file"
										 defaultButton:@"Can't import"
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:[NSString stringWithFormat:@"%@", [self filePathString]]];
			
		// show alert in a modal dialog
		[alert runModal];

		return NO;
	}
	
	
	AudioStreamBasicDescription basicDescription = [AudioFile descriptionOfAudioFile:audioFileID];
	UInt64 dataPackets = [AudioFile dataPacketsOfAudioFile:audioFileID];
	
	// check sample rate
	if(basicDescription.mSampleRate != [[[NSApplication sharedApplication] valueForKeyPath:@"delegate.currentProjectDocument.projectSettings.projectSampleRate"] intValue])
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"Wrong sample rate"
										 defaultButton:@"Can't import"
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:[NSString stringWithFormat:@"%@ doesn't have the appropriate sample rate (%d instead of %d)",
                                                        [self filePathString],
                                                        (int)basicDescription.mSampleRate,
                                                        [[[NSApplication sharedApplication] valueForKeyPath:@"delegate.currentProjectDocument.projectSettings.projectSampleRate"] intValue]]];
		
		// show alert in a modal dialog
		[alert runModal];
		return NO;
	}
	
	// check channels
	if(basicDescription.mChannelsPerFrame != 1)
	{
		NSAlert *alert = [NSAlert alertWithMessageText:@"Wrong number of channels"
										 defaultButton:@"Can't import"
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:[NSString stringWithFormat:@"%@ is not a mono audio file", [self filePathString]]];
		
		// show alert in a modal dialog
		[alert runModal];
		return NO;
	}
	
	// get duration
	duration = dataPackets * basicDescription.mFramesPerPacket / basicDescription.mSampleRate * 1000;
	
	// [self calculateOverviewImage];
	return YES;
}

- (void)reopenAudioFile
{	
	audioFileID = [AudioFile idOfAudioFileAtPath:[self filePathString]];

	// file successfully opened?
	if(!audioFileID)
	{
		// get filename from path
		NSArray *listPath = [[self filePathString] componentsSeparatedByString:@"/"];
		NSString *theName = [NSString stringWithString:[listPath objectAtIndex:[listPath count]-1]];

		NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Can't find audio file %@", theName]
										 defaultButton:@"Relink"
									   alternateButton:nil //@"Delete"
										   otherButton:@"Skip"
							 informativeTextWithFormat:[NSString stringWithFormat:@"%@", [self filePathString]]];
		
		// show alert in a modal dialog
		int button = [alert runModal];
		
		
		switch(button)
		{
			case NSAlertDefaultReturn: // relink
				[self relinkAudioFile];
				break;
							
			case NSAlertAlternateReturn: // delete reference
				break;

			default: // skip (that is, do nothing)
				break;
		}
		
		return;
	}
	
	// get duration
	AudioStreamBasicDescription basicDescription = [AudioFile descriptionOfAudioFile:audioFileID];
	UInt64 dataPackets = [AudioFile dataPacketsOfAudioFile:audioFileID];
	duration = dataPackets * basicDescription.mFramesPerPacket / basicDescription.mSampleRate * 1000;
}

- (void)relinkAudioFile
{
	// choose audio file in an open panel
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
    [openPanel setTreatsFilePackagesAsDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
	[openPanel setAllowedFileTypes:[AudioFile allowedFileTypes]];
	[openPanel setPrompt:@"Relink"];
	
	if([openPanel runModal] == NSOKButton)
	{
		[openPanel orderOut:self];
		[self setValue:[[openPanel filenames] objectAtIndex:0] forKey:@"relativeFilePath"];
		[self openAudioFile];	
	}
}

- (void) calculateOverviewImage
{
	progress = [[ProgressPanel sharedProgressPanel] addProgressWithTitle:[NSString stringWithFormat:@"Calculating overview for %@", [self valueForKey:@"relativeFilePath"]]];
	
	[NSThread detachNewThreadSelector:@selector(calculateOverviewImageThread)
							 toTarget:self
						   withObject:nil];

}

- (void)calculateOverviewImageThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int framesPerPixel = 50;
	NSUInteger dataLength = ceil(numOfFrames / framesPerPixel);
	
	char *buffer = malloc(dataLength * 2); // min and max values
	char min, max;
	
	int i,j;
	for (i=0;i<dataLength;i++)
	{
		[progress setProgressValue: (float)i / dataLength / 2];
		
		/*----------------------------------------------------------------------------------
		 AudioFileReadPackets - Read packets of audio data from the audio file. For all 
		 uncompressed formats, packet = frame. 
		 ioNumPackets less than requested indicates end of file.
		 
		 
		 inUseCache 			- true if it is desired to cache the data upon read, else false
		 outNumBytes 			- on output, the number of bytes actually returned
		 outPacketDescriptions 	- on output, an array of packet descriptions describing
		 the packets being returned. NULL may be passed for this
		 parameter. Nothing will be returned for linear pcm data.   
		 inStartingPacket 		- the packet index of the first packet desired to be returned
		 ioNumPackets 			- on input, the number of packets to read, on output, the number of
		 packets actually read.
		 outBuffer 				- outBuffer should be a pointer to user allocated memory of size: 
		 number of packets requested times file's maximum (or upper bound on)
		 packet size.
		 //----------------------------------------------------------------------------------*/
		
		UInt32 ioNumPackets = framesPerPixel;
		UInt32 outNumBytes = ioNumPackets * bytesPerPacket;
		SInt16 outBuffer[ioNumPackets];
						
		OSStatus err = AudioFileReadPackets(audioFileID,
											NO,
											&outNumBytes,
											NULL,
											i * ioNumPackets, 
											&ioNumPackets, 
											outBuffer);
		
		
		NSAssert1(!err, @"AudioFileReadPackets failed with error %i", err);
		
		min = max = outBuffer[0];

		for(j=1;j<ioNumPackets;j++)
		{
			char sample = rand() / RAND_MAX * 128; //outBuffer[j];
			min = sample < min ? sample : min;
			max = sample > max ? sample : max;
		}
		
		buffer[i] = min;
		buffer[i + dataLength] = max;
	}
	
	
//	overviewData = [[NSData alloc] initWithBytes:buffer length:dataLength * 2];
//	[self setOverviewData];
	
	float overviewHeight, overviewBaseline, overviewWidth;
	
	overviewWidth = dataLength;
	overviewHeight = 60;
	overviewBaseline = 30;

	[waveformImage release];
	waveformImage = [[NSImage alloc] initWithSize:NSMakeSize(overviewWidth, overviewHeight)];
	NSBezierPath *waveformPath = [NSBezierPath bezierPath];
		
		
	float stepsize = dataLength / overviewWidth / 2;
	float index;
	float y1, y2;
	
	for(i=0,index=stepsize;index<dataLength * 0.5;i++, index += stepsize)
	{
		[progress setProgressValue: 0.5 + (float)index / dataLength];

		y1 = y2 = 0;
		for(j=floor(index);j<index+stepsize;j++)
		{
			y1 += (float)buffer[j] / 128;
			y2 += (float)buffer[j + (int)(dataLength * 0.5)] / 128;
		}
		
		y1 /= ceil(stepsize);
		y1 *= overviewHeight * 0.5;
		y2 /= ceil(stepsize);
		y2 *= overviewHeight * 0.5;
		[waveformPath moveToPoint: NSMakePoint(i, overviewBaseline + y1)];
		[waveformPath lineToPoint: NSMakePoint(i, overviewBaseline - y1)];
	}
	
	[waveformImage lockFocus];
	[[NSColor colorWithDeviceWhite:1.0 alpha:0.] set];
	[NSBezierPath fillRect: NSMakeRect(0, 0, overviewWidth, overviewHeight)] ;
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
	[[NSColor blackColor] set];
	[waveformPath setLineWidth : 0.0];		
	[waveformPath stroke];
	[waveformImage unlockFocus];
	
	
	// ---
	//NSLog(@"....finished calculateOverviewImage");
	for(id audioItem in [self valueForKey:@"audioItems"])
	{
		if([[audioItem valueForKey:@"audioRegions"] count])
		{
			NSView *arrangerView = [[[NSDocumentController sharedDocumentController] currentDocument] valueForKey:@"arrangerView"];
			[arrangerView setNeedsDisplay:YES];		
			break;
		}
	}
	// ---
	
	[[ProgressPanel sharedProgressPanel] removeProgress:progress];

	[pool release];	
	free(buffer);
	
}

- (void)setOverviewData
{
	// the waveform data is now stored in the model
	// this action is excluded from the undo chain
	[[self managedObjectContext] processPendingChanges];
	[[[self managedObjectContext] undoManager] disableUndoRegistration];
	[self setValue:overviewData forKey:@"overview"];
	[[self managedObjectContext] processPendingChanges];
	[[[self managedObjectContext] undoManager] enableUndoRegistration];
	
}

@end
