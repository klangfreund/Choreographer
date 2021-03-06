/*
 ==============================================================================
 
 This file is part of the JUCE library - "Jules' Utility Class Extensions"
 Copyright 2004-10 by Raw Material Software Ltd.
 
 ------------------------------------------------------------------------------
 
 JUCE can be redistributed and/or modified under the terms of the GNU General
 Public License (Version 2), as published by the Free Software Foundation.
 A copy of the license is included in the JUCE distribution, or can be found
 online at www.gnu.org/licenses.
 
 JUCE is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 
 ------------------------------------------------------------------------------
 
 To release a closed-source product which uses JUCE, commercial licenses are
 available: visit www.rawmaterialsoftware.com/juce for more information.
 
 
 Slightly modified by sam
 
 ==============================================================================
 */

#ifndef __JUCE_BUFFERINGAUDIOSOURCEMOD_JUCEHEADER__
#define __JUCE_BUFFERINGAUDIOSOURCEMOD_JUCEHEADER__

#include "../../JuceLibraryCode/JuceHeader.h"
//#include "juce_PositionableAudioSource.h"
//#include "../../threads/juce_Thread.h"
//#include "../dsp/juce_AudioSampleBuffer.h"


//==============================================================================
/**
 An AudioSource which takes another source as input, and buffers it using a thread.
 
 Create this as a wrapper around another thread, and it will read-ahead with
 a background thread to smooth out playback. You can either create one of these
 directly, or use it indirectly using an AudioTransportSource.
 
 @see PositionableAudioSource, AudioTransportSource
 */
class JUCE_API  BufferingAudioSourceMod  : public PositionableAudioSource
{
public:
    //==============================================================================
    /** Creates a BufferingAudioSourceMod.
	 
	 by sam: This modification was needed because the standard BufferingAudioSource
	 allocates a buffer with a maximum of 2 channels. The only difference (to work
	 with this class) is the additional argument numberOfChannelsToBuffer_ in the 
	 constructor.
	 
	 @param source                   the input source to read from
	 @param deleteSourceWhenDeleted  if true, then the input source object will
	 be deleted when this object is deleted
	 @param numberOfChannels		 the number of channels to buffer. (On the
	 original BufferingAudioSource class, this is limited to 2 channels
	 @param numberOfSamplesToBuffer  the size of buffer to use for reading ahead
	 */
    BufferingAudioSourceMod (PositionableAudioSource* source,
							 const bool deleteSourceWhenDeleted,
							 int numberOfChannels,
							 int numberOfSamplesToBuffer);
	
    /** Destructor.
	 
	 The input source may be deleted depending on whether the deleteSourceWhenDeleted
	 flag was set in the constructor.
	 */
    ~BufferingAudioSourceMod();
	
    //==============================================================================
    /** Implementation of the AudioSource method. */
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate);
	
    /** Implementation of the AudioSource method. */
    void releaseResources();
	
    /** Implementation of the AudioSource method. */
    void getNextAudioBlock (const AudioSourceChannelInfo& bufferToFill);
	
    //==============================================================================
    /** Implements the PositionableAudioSource method. */
    void setNextReadPosition (int64 newPosition);
	
    /** Implements the PositionableAudioSource method. */
    int64 getNextReadPosition() const;
	
    /** Implements the PositionableAudioSource method. */
    int64 getTotalLength() const                  { return source->getTotalLength(); }
	
    /** Implements the PositionableAudioSource method. */
    bool isLooping() const                      { return source->isLooping(); }
	
    //==============================================================================
    juce_UseDebuggingNewOperator
	
private:
    //==============================================================================
    PositionableAudioSource* source;
    bool deleteSourceWhenDeleted;
	int numberOfChannelsToBuffer; // by sam: new
    int numberOfSamplesToBuffer;
    AudioSampleBuffer buffer;
    CriticalSection bufferStartPosLock;
    int64 volatile bufferValidStart, bufferValidEnd, nextPlayPos;
    bool wasSourceLooping;
    double volatile sampleRate;
	
    friend class SharedBufferingAudioSourceModThread;
    bool readNextBufferChunk();
    void readBufferSection (int64 start, int length, int bufferOffset);
	
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (BufferingAudioSourceMod);
};


#endif   // __JUCE_BUFFERINGAUDIOSOURCEMOD_JUCEHEADER__
