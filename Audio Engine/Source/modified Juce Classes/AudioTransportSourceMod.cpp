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

// #include "../../core/juce_StandardHeader.h"

// BEGIN_JUCE_NAMESPACE

#include "AudioTransportSourceMod.h"
// #include "../../threads/juce_ScopedLock.h"
// #include "../../containers/juce_ScopedPointer.h"


//==============================================================================
AudioTransportSourceMod::AudioTransportSourceMod()
: source (0),
bufferingSource (0),
positionableSource (0),
masterSource (0),
gain (1.0f),
lastGain (1.0f),
playing (false),
stopped (true),
sampleRate (44100.0),
blockSize (128),
readAheadBufferSize (0),
isPrepared (false),
inputStreamEOF (false),
arrangerIsLooping (false),
fadeInCurrentAudioBlock (false)
{
}

AudioTransportSourceMod::~AudioTransportSourceMod()
{
    setSource (0, 1);
	
    releaseResources();
}

void AudioTransportSourceMod::setSource (PositionableAudioSource* const newSource,
										 int numberOfChannels,
										 int readAheadBufferSize_)
{
    if (source == newSource)
    {
        if (source == 0)
            return;
		
        setSource (0, 0, 0); // deselect and reselect to avoid releasing resources wrongly
    }
	
    readAheadBufferSize = readAheadBufferSize_;
	
    BufferingAudioSourceMod* newBufferingSource = 0;
    PositionableAudioSource* newPositionableSource = 0;
    AudioSource* newMasterSource = 0;
	
	ScopedPointer <BufferingAudioSourceMod> oldBufferingSource (bufferingSource);
	    // Deletes the object when this section of code is left.
    AudioSource* oldMasterSource = masterSource;
	
    if (newSource != 0)
    {
        newPositionableSource = newSource;
		
        if (readAheadBufferSize_ > 0)
            newPositionableSource = newBufferingSource
			= new BufferingAudioSourceMod (newPositionableSource, false, numberOfChannels, readAheadBufferSize_);
		
        newPositionableSource->setNextReadPosition (0);

		newMasterSource = newPositionableSource;
		
        if (isPrepared)
        {
			newMasterSource->prepareToPlay (blockSize, sampleRate);
        }
    }
	
    {
        const ScopedLock sl (callbackLock);
		
        source = newSource;
        bufferingSource = newBufferingSource;
        masterSource = newMasterSource;
        positionableSource = newPositionableSource;
		
        playing = false;
    }
	
    if (oldMasterSource != 0)
        oldMasterSource->releaseResources();
}

void AudioTransportSourceMod::start()
{
    if ((! playing) && masterSource != 0)
    {
        {
            const ScopedLock sl (callbackLock);
            playing = true;
            // stopped = false;
            inputStreamEOF = false;
        }
		
        sendChangeMessage ();
    }
}

void AudioTransportSourceMod::stop()
{
    if (playing)
    {
        {
            const ScopedLock sl (callbackLock);
            playing = false;
        }
		
        int n = 500;
        while (--n >= 0 && ! stopped)
            Thread::sleep (2);
		
        sendChangeMessage ();
    }
}

void AudioTransportSourceMod::setPosition (double newPosition)
{
    if (sampleRate > 0.0)
        setNextReadPosition (roundToInt (newPosition * sampleRate));
}

double AudioTransportSourceMod::getCurrentPosition() const
{
    if (sampleRate > 0.0)
        return getNextReadPosition() / sampleRate;
    else
        return 0.0;
}

double AudioTransportSourceMod::getLengthInSeconds() const
{
    return getTotalLength() / sampleRate;
}

void AudioTransportSourceMod::setNextReadPosition (int64 newPosition)
{
    if (positionableSource != 0)
    {	
        positionableSource->setNextReadPosition (newPosition);
    }
}

int64 AudioTransportSourceMod::getNextReadPosition() const
{
    if (positionableSource != 0)
    {
        return (int64) (positionableSource->getNextReadPosition());
    }
	
    return 0;
}

int64 AudioTransportSourceMod::getTotalLength() const
{
    const ScopedLock sl (callbackLock);
	
    if (positionableSource != 0)
    {
        return (int64) (positionableSource->getTotalLength()); // * ratio);
    }
	
    return 0;
}

bool AudioTransportSourceMod::isLooping() const
{
    const ScopedLock sl (callbackLock);
	
    return positionableSource != 0
	&& positionableSource->isLooping();
}

bool AudioTransportSourceMod::enableArrangerLoop(double loopStart_inSeconds, double loopEnd_inSeconds, double loopFadeTime_inSeconds)
{
	if (loopStart_inSeconds < loopEnd_inSeconds && loopFadeTime_inSeconds >= 0 && sampleRate > 0.0) // this is a valid configuration
	{		
		arrangerIsLooping = true;
		loopStart = (int64) (loopStart_inSeconds * sampleRate);
		loopEnd = (int64) (loopEnd_inSeconds * sampleRate);
		loopFadeTime = (int64) (loopFadeTime_inSeconds * sampleRate);
		return true;
	}
	else // if the input is not a valid configuration
	{
		return false;
	}

}

bool AudioTransportSourceMod::reenableArrangerLoop()
{
	if (loopStart < loopEnd && loopFadeTime >= 0.0 && sampleRate > 0.0) // this is a valid configuration
	{		
		arrangerIsLooping = true;
		return true;
	}
	else // if the input is not a valid configuration
	{
		return false;
	}
    
}

void AudioTransportSourceMod::disableArrangerLoop()
{
	arrangerIsLooping = false;
}

bool AudioTransportSourceMod::getArrangerLoopStatus()
{
	return arrangerIsLooping;
}


void AudioTransportSourceMod::setGain (const float newGain) throw()
{
    gain = newGain;
}

void AudioTransportSourceMod::prepareToPlay (int samplesPerBlockExpected,
                                          double sampleRate_)
{
	DEB("AudioTransportSourceMod: prepareToPlay called")
	
    const ScopedLock sl (callbackLock);
	
    sampleRate = sampleRate_;
    blockSize = samplesPerBlockExpected;
	
    if (masterSource != 0)
        masterSource->prepareToPlay (samplesPerBlockExpected, sampleRate);
	
    isPrepared = true;
}

void AudioTransportSourceMod::releaseResources()
{
    const ScopedLock sl (callbackLock);
	
    if (masterSource != 0)
	{
        masterSource->releaseResources();
		    // Removes the bufferingAudioSourceMod from the 
		    // SharedBufferingAudioSourceModThread.
	}
	
    isPrepared = false;
}

void AudioTransportSourceMod::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
    const ScopedLock sl (callbackLock);
	
    inputStreamEOF = false;
	
    if (masterSource != 0 && ! stopped)
    {
		if (!arrangerIsLooping || positionableSource->getNextReadPosition() > loopEnd)
		// This section is taken from the original AudioTransportSource.
		{
			// remember: masterSource = positionableSource
			masterSource->getNextAudioBlock (info);
			  // attention!: after this call, the positionableSource->getNextReadPosition() has 
			  // changed to the position after the current audio block.
			
			if (! playing)
			{
				// just stopped playing, so fade out the last block..
				for (int i = info.buffer->getNumChannels(); --i >= 0;)
					info.buffer->applyGainRamp (i, info.startSample, jmin (256, info.numSamples), 1.0f, 0.0f);
				
				if (info.numSamples > 256)
					info.buffer->clear (info.startSample + 256, info.numSamples - 256);
			}
			
			if (positionableSource->getNextReadPosition() > positionableSource->getTotalLength() + 1
				&& ! positionableSource->isLooping())
			{
				playing = false;
				inputStreamEOF = true;
				sendChangeMessage ();
			}
			
			stopped = ! playing;
			
			for (int i = info.buffer->getNumChannels(); --i >= 0;)
			{
				info.buffer->applyGainRamp (i, info.startSample, info.numSamples,
											lastGain, gain);
			}
		}
		else // if (arrangerIsLooping)
		// This section is a modification of the original AudioTransportSource and contains the looping functionality.
		{			
			// remember: masterSource = positionableSource
			masterSource->getNextAudioBlock (info);
			// attention!: after this call, the positionableSource->getNextReadPosition() has 
			// changed to the position after the current audio block.
			
			if (! playing)
			{
				// just stopped playing, so fade out the last block..
				for (int i = info.buffer->getNumChannels(); --i >= 0;)
					info.buffer->applyGainRamp (i, info.startSample, jmin (256, info.numSamples), 1.0f, 0.0f);
				
				if (info.numSamples > 256)
					info.buffer->clear (info.startSample + 256, info.numSamples - 256);
			}
			else // if (playing)
			{
				int64 startOfCurrentAudioBlock = positionableSource->getNextReadPosition() - info.numSamples;
				int64 endOfCurrentAudioBlock = positionableSource->getNextReadPosition();
				
				if (startOfCurrentAudioBlock < loopEnd &&  endOfCurrentAudioBlock >= loopEnd)
				// the current audio block is crossing the end marker of the loop (loopEnd).
				{
					// Fade out the current audio block (to avoid audible clicks).
					// The fade out time = min(loopFadeTime, info.numSamples)
					if (loopFadeTime >= info.numSamples)
					{
						for (int i = info.buffer->getNumChannels(); --i >= 0;)
							info.buffer->applyGainRamp (i, info.startSample, info.numSamples, 1.0f, 0.0f);
					}
					else
					// if (loopFadeTime < info.numSamples)
					{
						int offset = info.numSamples - loopFadeTime;
						for (int i = info.buffer->getNumChannels(); --i >= 0;)
							info.buffer->applyGainRamp (i, info.startSample + offset, loopFadeTime, 1.0f, 0.0f);
					}
					
					// put the playhead to the right position at the start of the loop.
					positionableSource->setNextReadPosition(loopStart + endOfCurrentAudioBlock - loopEnd);
					
					// makes sure the next audio block will be faded in
					fadeInCurrentAudioBlock = true;
				}
				
				if (fadeInCurrentAudioBlock)
				// the previous audio block was at the end of the loop, the current one is at the
				// start. Thats why we fade it in (to avoid clicks).
				{
					if (loopFadeTime >= info.numSamples)
					{
						for (int i = info.buffer->getNumChannels(); --i >= 0;)
							info.buffer->applyGainRamp (i, info.startSample, info.numSamples, 0.0f, 1.0f);
					}
					else
						// if (loopFadeTime < info.numSamples)
					{
						for (int i = info.buffer->getNumChannels(); --i >= 0;)
							info.buffer->applyGainRamp (i, info.startSample, loopFadeTime, 0.0f, 1.0f);
					}
					
					fadeInCurrentAudioBlock = false;
				}
			}
			
			stopped = ! playing;
			
			for (int i = info.buffer->getNumChannels(); --i >= 0;)
			{
				info.buffer->applyGainRamp (i, info.startSample, info.numSamples,
											lastGain, gain);
			}
		}
        
        //temp
        //info.clearActiveBufferRegion();
    }
    else // stopped==true
    {
        if (playing)
        {
            // playing==true and stopped==true. We are about to start. Fade in.
            
            masterSource->getNextAudioBlock (info);
            
            int endOfRamp = jmin (256, info.numSamples);
            for (int i = info.buffer->getNumChannels(); --i >= 0;)
            {
                info.buffer->applyGainRamp (i, info.startSample, 
                                            endOfRamp, 0.0f, gain);
                if (info.numSamples > 256)
                    info.buffer->applyGain(i, info.startSample + endOfRamp, 
                                       info.numSamples-endOfRamp, gain);
            }   
            
            lastGain = gain;
            
            stopped = false;
        }
        else
        {
        // playing==false and stopped==true. Stopped -> return silence.
        info.clearActiveBufferRegion();
        stopped = true;
        }
    }
	
    lastGain = gain;
}

// END_JUCE_NAMESPACE