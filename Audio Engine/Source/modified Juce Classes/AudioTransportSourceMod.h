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

#ifndef __JUCE_AUDIOTRANSPORTSOURCEMOD_JUCEHEADER__
#define __JUCE_AUDIOTRANSPORTSOURCEMOD_JUCEHEADER__

#include "../../JuceLibraryCode/JuceHeader.h"
#include "BufferingAudioSourceMod.h"
//#include "juce_BufferingAudioSource.h"
//#include "juce_ResamplingAudioSource.h"
//#include "../../events/juce_ChangeBroadcaster.h"


//==============================================================================
/**
 An AudioSource that takes a PositionableAudioSource and allows it to be
 played, stopped, started, etc.
 
 This can also be told use a buffer and background thread to read ahead, and
 if can correct for different sample-rates.
 
 You may want to use one of these along with an AudioSourcePlayer and AudioIODevice
 to control playback of an audio file.
 
 sam: New in this mod: The numberOfChannels argument in the setSource(..) method.
 
 @see AudioSource, AudioSourcePlayer
 */
class JUCE_API  AudioTransportSourceMod
    : public PositionableAudioSource,
      public ChangeBroadcaster
{
public:
    //==============================================================================
    /** Creates an AudioTransportSourceMod.
	 
	 After creating one of these, use the setSource() method to select an input source.
	 */
    AudioTransportSourceMod();
	
    /** Destructor. */
    ~AudioTransportSourceMod();
	
    //==============================================================================
    /** Sets the reader that is being used as the input source.
	 
	 This will stop playback, reset the position to 0 and change to the new reader.
	 
	 The source passed in will not be deleted by this object, so must be managed by
	 the caller.
	 
	 @param newSource                        the new input source to use. This may be zero
	 @param numberOfChannels				 the number of channels to deliver
	 @param readAheadBufferSize              a size of buffer to use for reading ahead. If this
			                                 is zero, no reading ahead will be done; if it's
                                             greater than zero, a BufferingAudioSource will be used
                                             to do the reading-ahead.
	 @param sourceSampleRateToCorrectFor     if this is non-zero, it specifies the sample
                                             rate of the source, and playback will be sample-rate
                                             adjusted to maintain playback at the correct pitch. If
                                             this is 0, no sample-rate adjustment will be performed
	 */
    void setSource (PositionableAudioSource* const newSource,
					int numberOfChannels,
                    int readAheadBufferSize = 0);
	
    //==============================================================================
    /** Changes the current playback position in the source stream.
	 
	 The next time the getNextAudioBlock() method is called, this
	 is the time from which it'll read data.
	 
	 @see getPosition
	 */
    void setPosition (double newPosition);
	
    /** Returns the position that the next data block will be read from
	 
	 This is a time in seconds.
	 */
    double getCurrentPosition() const;
	
    /** Returns the stream's length in seconds. */
    double getLengthInSeconds() const;
	
    /** Returns true if the player has stopped because its input stream ran out of data.
	 */
    bool hasStreamFinished() const throw()              { return inputStreamEOF; }
	
    //==============================================================================
    /** Starts playing (if a source has been selected).
	 
	 If it starts playing, this will send a message to any ChangeListeners
	 that are registered with this object.
	 */
    void start();
	
    /** Stops playing.
	 
	 If it's actually playing, this will send a message to any ChangeListeners
	 that are registered with this object.
	 */
    void stop();
	
    /** Returns true if it's currently playing. */
    bool isPlaying() const throw()      { return playing; }
	
    //==============================================================================
    /** Changes the gain to apply to the output.
	 
	 @param newGain  a factor by which to multiply the outgoing samples,
	 so 1.0 = 0dB, 0.5 = -6dB, 2.0 = 6dB, etc.
	 */
    void setGain (const float newGain) throw();
	
    /** Returns the current gain setting.
	 
	 @see setGain
	 */
    float getGain() const throw()       { return gain; }
	
	
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
    int64 getTotalLength() const;
	
    /** Implements the PositionableAudioSource method. 
	  
	 Comment by Sam: This kind of loop means, that the
	 source is repeated for an infinite number of time.
	 Or stated differently, at any point in time, the
	 source is producing sound, since it is looping.
	 */
    bool isLooping() const;
	
	/**
	 Turns the loop (as specified in the arranger) on.
	 
	 @param loopFadeTime_inSeconds	Is used as the fade out and fade in time - 
                                    before and after the jump from the end to 
                                    the start marker of the loop (to avoid 
                                    clicks).
	 
	 @return	True, if the input data is a valid set.
	 */
	bool enableArrangerLoop(double loopStart_inSeconds, double loopEnd_inSeconds, double loopFadeTime_inSeconds);
    
    /** Reenables the loop (as specified in the arranger) as specified
     on the last call of enableArrangerLoop.
     */
    bool reenableArrangerLoop();

	/**
	 Turns the loop (as specified in the arranger) off.
	 */
	void disableArrangerLoop();
    
    /** Returns the status of the loop (as specified in the arranger).
     */
    bool getArrangerLoopStatus();
	
    //==============================================================================
    juce_UseDebuggingNewOperator
	
private:
    PositionableAudioSource* source;
    BufferingAudioSourceMod* bufferingSource;
    PositionableAudioSource* positionableSource;
    /** Here, the masterSource is always equal to the positionableSource.
     In the original code it is used if resampling is engaged. */
    AudioSource* masterSource;
	
    CriticalSection callbackLock;
    float volatile gain, lastGain;
    bool volatile playing, stopped;
    double sampleRate;
    int blockSize, readAheadBufferSize;
    bool isPrepared, inputStreamEOF;
	
	// looping in the arranger:
	bool arrangerIsLooping;
	int64 loopStart;					// measured in samples
	int64 loopEnd;						// measured in samples
	int64 loopFadeTime;				    // measured in samples, 
										//   defines the fade out as well as the fade in time
	bool fadeInCurrentAudioBlock;		// is used to fade in the first audio block after
										//   the jump to the start of the loop.
	
	JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (AudioTransportSourceMod);
};


#endif   // __JUCE_AUDIOTRANSPORTSOURCEMOD_JUCEHEADER__
