/*
 *  AudioSourceFilePreview.h
 *  AudioPlayer
 *
 *  Created by sam (sg@klangfreund.com) on 120628
 *  Copyright 2012. All rights reserved.
 *
 */

#ifndef __AUDIOSOURCEFILEPRELISTENER_HEADER__
#define __AUDIOSOURCEFILEPRELISTENER_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"

//==============================================================================
/**
 To preview (prelisten) audio files from the pool area of the Choreographer.
 */
class JUCE_API  AudioSourceFilePrelistener  : public AudioSource
{
public:
    //==============================================================================
    /** Constructor.
	 */
    AudioSourceFilePrelistener();
	
    /** Destructor. */
    ~AudioSourceFilePrelistener();
    
    /**
     Load and play an audio file.
     
     @param absolutePathToAudioFile		The file you want to listen to.
     @param startPosition               Where to start. Measured in samples.
     @param endPosition                 Where to stop. Measured in samples..

     @return                            The success of the operation.
     */
    bool play(const String& absolutePathToAudioFile,
              const int& startPosition, 
              const int& endPosition);
    
    /**
     Stop the playback of the selected audio file.
     */
    void stop();
    
    bool isPlaying();

    //==============================================================================
    /** Implements the AudioSource method. */
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate);
	
    /** Implements the AudioSource method. */
    void releaseResources();
	
    /** Implements the AudioSource method. */
    void getNextAudioBlock (const AudioSourceChannelInfo& info);
		
    //==============================================================================
    juce_UseDebuggingNewOperator
	
private:
    //==============================================================================
    String previouslyUsedPathToAudioFile;
    
    bool runPlayback;
    BufferingAudioSource* bufferingAudioSource;
    
    int nextPlayPosition;
    int endPosition;
    
    int samplesPerBlockExpected;
    double sampleRate;

	
	JUCE_LEAK_DETECTOR (AudioSourceFilePrelistener);
};


#endif   // __AUDIOSOURCEFILEPRELISTENER_HEADER__
