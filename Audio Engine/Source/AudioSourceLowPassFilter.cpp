/*
 *  AudioSourceDopplerEffect.cpp
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 120402.
 *  Copyright 2012. All rights reserved.
 *
 */

#include "AudioSourceLowPassFilter.h"

//==============================================================================

AudioSourceLowPassFilter::AudioSourceLowPassFilter (PositionableAudioSource * positionableAudioSource_, double sampleRate_)
  : positionableAudioSource (positionableAudioSource_),
    sampleRate (sampleRate_),
    constantSpacialPosition (true),
    previousSpacialPoint (),
    nextSpacialPoint (),
    currentSpacialPosition (),
    iirFilter()
{
	DEB("AudioSourceLowPassFilter: constructor called.");
  
    // Define an initial spacial envelope.
    Array<SpacialEnvelopePoint> initialSpacialEnvelope;
	initialSpacialEnvelope.add(SpacialEnvelopePoint(0,      // time (in samples)
                                                    0,      // x
                                                    0,      // y
                                                    0));	// z);
    setSpacialEnvelope(initialSpacialEnvelope);
}

AudioSourceLowPassFilter::~AudioSourceLowPassFilter()
{
	DEB("AudioSourceLowPassFilter: destructor called.");
}

/** Implementation of the AudioSource method. */
void AudioSourceLowPassFilter::prepareToPlay (int samplesPerBlockExpected_, double sampleRate_)
{
    sampleRate = sampleRate_;
    samplesPerBlockExpected = samplesPerBlockExpected_;
    
    // It is assumed that
	//      positionableAudioSource.prepareToPlay (samplesPerBlockExpected, sampleRate);
    // is called outside.
}

/** Implementation of the AudioSource method. */
void AudioSourceLowPassFilter::releaseResources()
{
    // It is assumed that
	//      positionableAudioSource.releaseResources();
    // is called outside.
}

/** Implements the PositionableAudioSource method. */
void AudioSourceLowPassFilter::setNextReadPosition (int64 newPosition)
{	
    if (newPosition != nextPlayPosition)
    {
        nextPlayPosition = newPosition;
        
        if (!constantSpacialPosition)
        {
            // Ensure that the nextSpacialPointIndex, the previousSpacialPoint
            // and the nextSpacialPoint are set correctly.
            nextSpacialPointIndex = 1;
            prepareForNewPosition(newPosition,
                                  &nextSpacialPointIndex,
                                  &previousSpacialPoint,
                                  &nextSpacialPoint,
                                  &currentSpacialPosition);
        }
    }
    
    positionableAudioSource->setNextReadPosition(newPosition);
}

/** Implementation of the AudioSource method. */
void AudioSourceLowPassFilter::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
    // DEB("AudioSourceLowPassFilter: getNextAudioBlock called.");
    
    // For every audio block, the (spacial) distance of the audio source at the
    // first sample is calculated. The resulting cutoff frequency is used for
    // the whole block.
    
    // Step 1: Get the samples 
    // -----------------------
    positionableAudioSource->getNextAudioBlock(info);
    
    // Step 2: Filter them
    // -------------------
    
    // Determine the cutoffFrequency
    if (!constantSpacialPosition)
    {
        prepareForNewPosition(nextPlayPosition,
                              &nextSpacialPointIndex,
                              &previousSpacialPoint,
                              &nextSpacialPoint,
                              &currentSpacialPosition);
        double distanceWithHalfTheCutoffFrequency = 0.1;
        double lambda = log(2.0)/distanceWithHalfTheCutoffFrequency;
        double cutoffFrequency = 21000.0 * exp(-lambda * currentSpacialPosition.getDistance());
        // Set the filter with this cutoffFrequency
        iirFilter.makeLowPass(sampleRate, cutoffFrequency);
    }
    
    // Filter this block
    iirFilter.processSamples(info.buffer->getSampleData(0), info.numSamples);
    
    nextPlayPosition += info.numSamples;
}

/** Implements the PositionableAudioSource method. */
int64 AudioSourceLowPassFilter::getNextReadPosition () const
{
	return positionableAudioSource->getNextReadPosition();
}

/** Implements the PositionableAudioSource method. */
int64 AudioSourceLowPassFilter::getTotalLength () const
{
	return positionableAudioSource->getTotalLength();
}

/** Implements the PositionableAudioSource method. */
bool AudioSourceLowPassFilter::isLooping () const
{
	return positionableAudioSource->isLooping();
}

void AudioSourceLowPassFilter::setSpacialEnvelope (const Array<SpacialEnvelopePoint>& newSpacialEnvelope_)
{
    DEB("AudioSourceLowPassFilter: setSpacialEnvelope called")
    
	if (newSpacialEnvelope_.size() != 0)
	{
        const ScopedLock sl (lock);
        
        // To ensure that the filter doesn't start oscillating.
        iirFilter.reset();
        
        // Copy the elements over from the Array newSpacialEnvelope_ to the
        // OwnedArray newSpacialEnvelope.
        spacialEnvelope.clear();
        for (int i=0; i!=newSpacialEnvelope_.size(); ++i)
        {
            spacialEnvelope.add(new SpacialEnvelopePoint(newSpacialEnvelope_[i]));
        }
        
        if (spacialEnvelope.size() == 1)
        {
            constantSpacialPosition = true;
            
            currentSpacialPosition = SpacialPosition(*(spacialEnvelope[0]));
            
            // Determine the cutoff frequency and set the filter coefficients.
            double distanceWithHalfTheCutoffFrequency = 0.1;
            double lambda = log(2.0)/distanceWithHalfTheCutoffFrequency;
            double cutoffFrequency = 21000.0 * exp(-lambda * currentSpacialPosition.getDistance());
            DEB("cutoffFreq = " + String(cutoffFrequency))
            iirFilter.makeLowPass(sampleRate, cutoffFrequency);
        }
        else
        {
            constantSpacialPosition = false;
        }
    }
    else
    {
		DEB("AudioSourceLowPassFilter: The newSpacialEnvelope is empty! The spacial envelope hasn't been changed.")
	}
}

void AudioSourceLowPassFilter::setSource (PositionableAudioSource * positionableAudioSource_)
{
    DEB("AudioSourceLowPassFilter: setSource called")
    
    positionableAudioSource = positionableAudioSource_;
    positionableAudioSource->setNextReadPosition(nextPlayPosition);
}


inline void AudioSourceLowPassFilter::prepareForNewPosition (int newPosition,
                                   int * nextSpacialPointIndex_,
                                   SpacialEnvelopePoint ** previousSpacialPoint_,
                                   SpacialEnvelopePoint ** nextSpacialPoint_,
                                   SpacialPosition * currentSpacialPosition_)
{    
    // Figure out between which audioEnvelopePoints we are right now
	// and set up
    // - nextSpacialPointIndex_
    // - previousSpacialPoint_
    // - nextSpacialPoint_
	while (spacialEnvelope[nextSpacialPointIndex]->getPosition() <= newPosition)
	{
		(*nextSpacialPointIndex_)++;
	}
	*previousSpacialPoint_ = spacialEnvelope[*nextSpacialPointIndex_ - 1];
	*nextSpacialPoint_ = spacialEnvelope[*nextSpacialPointIndex_];

	// Figure out the *currentSpacialPosition_
    // ---------------------------------------
    
    // The distance in time. In samples.
	double distance = double ((*nextSpacialPoint_)->getPosition() 
                              - (*previousSpacialPoint_)->getPosition());
    // In samples.
	double distanceFromPreviousSpacialPointPosToCurrentPos = double(newPosition 
    - (*previousSpacialPoint_)->getPosition());
    
    double factor = distanceFromPreviousSpacialPointPosToCurrentPos / distance;
    
    currentSpacialPosition_->x = (*previousSpacialPoint_)->getX() + factor * ((*nextSpacialPoint_)->getX() - (*previousSpacialPoint_)->getX());
    currentSpacialPosition_->y = (*previousSpacialPoint_)->getY() + factor * ((*nextSpacialPoint_)->getY() - (*previousSpacialPoint_)->getY());
    currentSpacialPosition_->z = (*previousSpacialPoint_)->getZ() + factor * ((*nextSpacialPoint_)->getZ() - (*previousSpacialPoint_)->getZ());
}