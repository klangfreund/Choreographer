/*
 *  AudioRegionMixer.cpp
 *  AudioPlayer
 *
 *  Created by sam (sg@klangfreund.com) on 100425.
 *  Copyright 2010. All rights reserved.
 *
 */

//BEGIN_JUCE_NAMESPACE

#include "AudioSourceFilePrelistener.h"

//==============================================================================
AudioSourceFilePrelistener::AudioSourceFilePrelistener()
:   runPlayback (false),
    bufferingAudioSource (NULL),
    samplesPerBlockExpected (256), // Some initial value
    sampleRate (44100.0) // Some initial value
{
	DEB("AudioSourceFilePreview: constructor called.");
}

AudioSourceFilePrelistener::~AudioSourceFilePrelistener()
{
	DEB("AudioSourceFilePreview: destructor called.");
}

bool AudioSourceFilePrelistener::play(const String& absolutePathToAudioFile,
          const int& startPosition_, 
          const int& endPosition_)
{
    DEB("AudioSourceFilePreview::play called.");
    
    // If a new audio file is specified,
    // delete the old bufferingAudioSource and
    // create a new bufferingAudioSource
    if (absolutePathToAudioFile != previouslyUsedPathToAudioFile)
    {
        // delete the old audioFormatReaderSource
        // (exept the first time, when there is no audioFormatReaderSource)
        if (bufferingAudioSource != NULL)
        {
            bufferingAudioSource->releaseResources();
            delete bufferingAudioSource;
        }
        
        // \/ \/ \/ Similar to AudioRegionMixer::addRegion \/ \/ \/
        
        // --- begin{audio file stuff} ---
        File audioFile(absolutePathToAudioFile);
        
        // get a format manager and set it up with the basic types (wav and aiff).
        AudioFormatManager audioFormatManager;
        audioFormatManager.registerBasicFormats();
        // Currently, this registers the WAV and AIFF formats.
        
        AudioFormatReader* audioFormatReader = audioFormatManager.createReaderFor (audioFile);
        // This audioFormatReader will be deleted when the audioFormatReaderSource will
        // be deleted
        // --- end{audio file stuff} ---
        
        // if the previous lines of code weren't successful
        if (audioFormatReader == NULL)
        {
            DEB("AudioSourceFilePrelistener: The audio file couldn't be read.")
            delete audioFormatReader;
            bufferingAudioSource = NULL;
            runPlayback = false;
            return false;
        }
        // Check if this input set is invalid
        if (startPosition_ >= endPosition_
                 || startPosition_ < 0
                 || endPosition_ > audioFormatReader->lengthInSamples)
        {
            DEB("AudioSourceFilePrelistener: Didn't play because the given" 
                "startPosition (" + String(startPosition_) + ") and endPosition ("
                + String(endPosition_) + ") don't make sense.")
            delete audioFormatReader;
            bufferingAudioSource = NULL;
            runPlayback = false;
            return false;
        }
        
        // /\ /\ /\ End of similar to AudioRegionMixer::addRegion /\ /\ /\

        const bool deleteAudioFormatReaderWhenDeleted = true;
        AudioFormatReaderSource* audioFormatReaderSource = new AudioFormatReaderSource (audioFormatReader, deleteAudioFormatReaderWhenDeleted);
        bool deleteSourceWhenDeleted = true;
        bufferingAudioSource = new BufferingAudioSource (audioFormatReaderSource, deleteSourceWhenDeleted, 32768);
        bufferingAudioSource->prepareToPlay(samplesPerBlockExpected, sampleRate);
    }
    else
    // if (absolutePathToAudioFile == previouslyUsedPathToAudioFile)
    {
        // Check if this input set is invalid
        if (startPosition_ >= endPosition
            || startPosition_ < 0
            || endPosition_ > bufferingAudioSource->getTotalLength())
        {
            DEB("AudioSourceFilePrelistener: Didn't play because the given" 
                "startPosition (" + String(startPosition_) + ") and endPosition ("
                + String(endPosition_) + ") don't make sense.")
            runPlayback = false;
            return false;
        }
    }
    
    nextPlayPosition = startPosition_;
    endPosition = endPosition_;
    bufferingAudioSource->setNextReadPosition (nextPlayPosition);
    
    runPlayback = true;
    return true;
}

void AudioSourceFilePrelistener::stop()
{
    DEB("AudioSourceFilePreview::play called.");
    
    runPlayback = false;
}

bool AudioSourceFilePrelistener::isPlaying()
{
    return runPlayback;
}

void AudioSourceFilePrelistener::prepareToPlay (int samplesPerBlockExpected_, double sampleRate_)
{
	DEB("AudioSourceFilePreview: prepareToPlay called.");
	
	samplesPerBlockExpected = samplesPerBlockExpected_;
	sampleRate = sampleRate_;	
}

// Implementation of the AudioSource method.
void AudioSourceFilePrelistener::releaseResources()
{
	DEB("AudioSourceFilePreview: releaseResources called.");
	
	// Nothing to do..
}

// Implementation of the AudioSource method.
void AudioSourceFilePrelistener::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
    DEB("AudioSourceFilePreview::getNextAudioBlock called.");

	if (info.numSamples > 0 && runPlayback)
	{
        int audioBlockEnd = nextPlayPosition + info.numSamples;
        
        if (audioBlockEnd <= endPosition)
        {
            bufferingAudioSource->getNextAudioBlock(info);
            nextPlayPosition = audioBlockEnd;
            bufferingAudioSource->setNextReadPosition(audioBlockEnd);
        }
        else
            // if (audioBlockEnd > endPosition)
        {
            // We don't have enough samples left to put info.numSamples
            // onto the buffer.
            
            AudioSourceChannelInfo infoWithSameBufferButLessUsedSamples = info;
            infoWithSameBufferButLessUsedSamples.numSamples = endPosition - nextPlayPosition;
            
            bufferingAudioSource->getNextAudioBlock(infoWithSameBufferButLessUsedSamples);
            nextPlayPosition = endPosition;
            
            runPlayback = false;
        }
	}
}

	
//END_JUCE_NAMESPACE