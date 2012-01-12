/*
 *  AudioSourceAmbipanning.cpp
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 120104.
 *  Copyright 2012. All rights reserved.
 *
 */

#include "AudioSourceDopplerEffect.h"

//==============================================================================

AudioSourceDopplerEffect::AudioSourceDopplerEffect (AudioSourceGainEnvelope& audioSourceGainEnvelope_, double sampleRate_)
  : audioSourceGainEnvelope (audioSourceGainEnvelope_),
    sampleRate (sampleRate_),
    newSpacialEnvelopeSet (false),
    previousSpacialPoint (),
    nextSpacialPoint (),
    sourceBuffer(1,0)
{
	DEB("AudioSourceDopplerEffect: constructor called.");
    
    sourceInfo.buffer = &sourceBuffer;
}

AudioSourceDopplerEffect::~AudioSourceDopplerEffect()
{
	DEB("AudioSourceDopplerEffect: destructor called.");
}

/** Implementation of the AudioSource method. */
void AudioSourceDopplerEffect::prepareToPlay (int samplesPerBlockExpected_, double sampleRate_)
{
    sampleRate = sampleRate_;
    samplesPerBlockExpected = samplesPerBlockExpected_;
    
    // It is assumed that
	//      audioSourceGainEnvelope.prepareToPlay (samplesPerBlockExpected, sampleRate);
    // is called outside.
}

/** Implementation of the AudioSource method. */
void AudioSourceDopplerEffect::releaseResources()
{
    // It is assumed that
	//      audioSourceGainEnvelope.releaseResources();
    // is called outside.
}

/** Implementation of the AudioSource method. */
void AudioSourceDopplerEffect::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
    // DEB("AudioSourceDopplerEffect::getNextAudioBlock: nextPlayPosition = " + String(nextPlayPosition))
    
    int audioBlockStartPosition = nextPlayPosition;
    // To be precise, audioBlockEndPosition is actually the
    // audioBlockStartPosition of the next audio block.
    audioBlockEndPosition = nextPlayPosition + info.numSamples;
    
    if (newSpacialEnvelopeSet)
    {
        // Apply a ramp from the first sample of this audio block
        // with the delay time from the old spacial envelope
        // to the last sample of this audio block with the delay time
        // from the new spacial envelope.
        
        spacialEnvelope = newSpacialEnvelope;
        
        // For the first sample (from the old spacial envelope).
        double delayOnFirstSample = delayOnCurrentSample;
        
        // For the last sample (from the new spacial envelope).
        double delayOnLastSample;

        if (spacialEnvelope.size() == 1)
        {
            constantSpacialPosition = true;
            nextSpacialPoint = spacialEnvelope[0];
            delayOnLastSample = nextSpacialPoint.getDistanceDelay();
            delayDelta = 0.0;
                // delayDelta = The difference in the delay time between
                // two adjacent samples AFTER this audio block. I.e. the
                // delayDelta for the new spacialEnvelope.
        }
        else
        {
            // We need to figure out the delay time on the last sample
            // (= the first sample of the next audio block)
            prepareForNewPosition(audioBlockEndPosition);
                // delayDelta = The difference in the delay time between
                // two adjacent samples AFTER this audio block. I.e. the
                // delayDelta for the new spacialEnvelope.
            
            delayOnLastSample = delayOnCurrentSample;
        }
        
        // Determine the delayDelta needed for this audioBlock.
        double delayDeltaForTheNextAudioBlock = delayDelta;
        delayDelta = (delayOnLastSample - delayOnFirstSample) / info.numSamples;
        
        // Figure out the lowest and highest sample positions needed.
        // (such that we can request a corresponding audio block from the
        //  audioSourceGainEnvelope.)
        int startSample = audioBlockStartPosition + 
                floor(delayOnFirstSample * sampleRate);
        int endSample = audioBlockEndPosition + 
                floor(delayOnLastSample * sampleRate);
        
        int firstSampleOfDesiredAudioBlock = floor(jmin(startSample, endSample));
        int lastSampleOfDesiredAudioBlock = ceil(jmax(startSample, endSample));
        int numberOfSamplesForAudioBlock = lastSampleOfDesiredAudioBlock -
                                           firstSampleOfDesiredAudioBlock;
        
        // The sourceInfo.buffer is big enough to hold the biggest audio blocks
        // for the current and for the next spacial envelope, but it might be
        // too small for this transition from the current to the next envelope.
        if (sourceInfo.buffer->getNumSamples() < numberOfSamplesForAudioBlock)
        {
            bool keepExistingContent = false;
            sourceInfo.buffer->setSize(1, 
                                       numberOfSamplesForAudioBlock, 
                                       keepExistingContent);
        }
                
        // Request the audio block from audioSourceGainEnvelope
        audioSourceGainEnvelope.setNextReadPosition(firstSampleOfDesiredAudioBlock);
        sourceInfo.startSample = 0;
        sourceInfo.numSamples = lastSampleOfDesiredAudioBlock - 
                                firstSampleOfDesiredAudioBlock;
        audioSourceGainEnvelope.getNextAudioBlock(sourceInfo);
        
        float * sampleOfSource = sourceInfo.buffer->getSampleData(0);
        float * sampleOfDestination = info.buffer->getSampleData(0);
        
        // \/  \/  \/  \/  \/  \/  \/
        // TODO: Implement proper interpolation!
        // HERE (the dirty implementation): Take the closest sample before.
        double absoluteSamplePositionInSeconds = audioBlockStartPosition/
                                                 sampleRate +
                                                 delayOnFirstSample;
        // Relative to the first sample of the audioSourceGainEnvelope audio
        // block.
        double relativeSamplePositionInSeconds = absoluteSamplePositionInSeconds -
        (startSample/sampleRate);
        
        for (int i=info.startSample; 
             i < (info.numSamples + info.startSample); ++i)
        {
            
            sampleOfDestination[i] = sampleOfSource[ int(floor(relativeSamplePositionInSeconds*sampleRate)) ];
            relativeSamplePositionInSeconds += delayDelta;
        }
        // /\  /\  /\  /\  /\  /\  /\
        
        
        
        delayDelta = delayDeltaForTheNextAudioBlock;
        newSpacialEnvelopeSet = false;
    }
    else
    {
        
        
        // Figure out the lowest and highest sample positions needed.
        // ----------------------------------------------------------
        // (such that we can request a corresponding audio block from the
        //  audioSourceGainEnvelope.)
        
        
        
        // It is assumed that a spacialEnvelope is set
    
    }
    
    nextPlayPosition = audioBlockEndPosition;
}

/** Implements the PositionableAudioSource method. */
void AudioSourceDopplerEffect::setNextReadPosition (int64 newPosition)
{
	// if the newPosition is not at the expected position, right after the end
	// of the last audio block
	if (audioBlockEndPosition != newPosition && !constantSpacialPosition)
	{
		DEB("AudioSourceAmbipanning.setNextReadPosition: newPosition = "
            + String(newPosition))
		DEB("AudioSourceAmbipanning.setNextReadPosition: expected newPosition: " 
			+ String(audioBlockEndPosition))
		
		// figure out between which audioEnvelopePoints we are right now
		// and set up all variables needed by getNextAudioBlock(..)
		prepareForNewPosition(newPosition);	
	}
	
	nextPlayPosition = newPosition;
    
    // TODO: Think about this. Add delay?
	audioSourceGainEnvelope.setNextReadPosition (newPosition);
}

/** Implements the PositionableAudioSource method. */
int64 AudioSourceDopplerEffect::getNextReadPosition () const
{
	// return audioSourceGainEnvelope.getNextReadPosition();
    return 0;
}

/** Implements the PositionableAudioSource method. */
int64 AudioSourceDopplerEffect::getTotalLength () const
{
	return audioSourceGainEnvelope.getTotalLength();
}

/** Implements the PositionableAudioSource method. */
bool AudioSourceDopplerEffect::isLooping () const
{
	return audioSourceGainEnvelope.isLooping();
}

void AudioSourceDopplerEffect::setSpacialEnvelope (const Array<SpacialEnvelopePoint>& newSpacialEnvelope_)
{
    DEB("AudioSourceDopplerEffect: setSpacialEnvelope called")
	
	if (newSpacialEnvelope_.size() != 0)
	{
        newSpacialEnvelope = newSpacialEnvelope_;
        
        // this Array must be sorted for the code in getNextAudioBlock(..)
        // to work.
        newSpacialEnvelope.sort(spacialEnvelopePointComparator);
        
        // Set the buffer size such that it is big enough for the fastest
        // movements in the new spacial envelope.
        // --------------------------------------------------------------
        double highestSlope = 0.0; // seconds / sample
        double lowestSlope = 0.0; // seconds / sample
        // if newSpacialEnvelope.size() == 1, highestSlope = lowestSlope = 0
        if (newSpacialEnvelope.size() > 1)
        {
            for (int k=1; k<newSpacialEnvelope.size(); k++)
            {
                SpacialEnvelopePoint& previousEnvPoint = newSpacialEnvelope.getReference(k-1);
                SpacialEnvelopePoint& nextEnvPoint = newSpacialEnvelope.getReference(k);
                
                double slope = (nextEnvPoint.getDistanceDelay() 
                                - previousEnvPoint.getDistanceDelay()) /
                               (nextEnvPoint.getPosition() 
                                - previousEnvPoint.getPosition());
                    // seconds / sample
                highestSlope = jmax(highestSlope, slope); // will be >= 0
                lowestSlope = jmin(lowestSlope, slope); // will be <= 0
            }
        }
        // The highest and lowest time difference between two adjacent
        // (output) samples.
        double regularDifference = 1.0 / sampleRate;
        // A positive slope means the sound source is moving away and therefore
        // the playback speed is decreasing.
        // lowestTimeDifference <= regularDifference.
        double lowestTimeDifference = regularDifference - highestSlope;
        // A negative slope means the sound source is moving closer and 
        // therefore the playback speed is increasing.
        // highestTimeDifference >= regularDifference.
        double highestTimeDifference = regularDifference - lowestSlope;
        
        double biggestTimeDifference = jmax(highestTimeDifference, 
                                            std::abs(lowestTimeDifference));
        
        double audioBlockStretchFactor = biggestTimeDifference / regularDifference;
        
        // If this estimation is wrong and a bigger audio block is needed in
        // getNextAudioBlock(), memory allocation will be done there again.
        // (hopefully the audio driver behaves nice and it is not neccessary).
        double estimatedMaxToExpectedAudioBlockRatio = 1.5;
        int maxSamplesPerBlockForSource = std::ceil(samplesPerBlockExpected * 
                                                    audioBlockStretchFactor *
                                                    estimatedMaxToExpectedAudioBlockRatio);
        // Allocate memory for the buffer used for the
        // AudioSourceGainEnvelope.getNextAudioBlock() in this 
        // getNextAudioBlock() when the new spacial envelope is engaged.
        // Since this change might happen while getNextAudioBlock() is working
        // with the current spacial envelope, only growth is allowed.
        if (sourceInfo.buffer->getNumSamples() < maxSamplesPerBlockForSource)
        {
            bool keepExistingContent = true;
            sourceInfo.buffer->setSize(1, 
                                       maxSamplesPerBlockForSource, 
                                       keepExistingContent);
        }
        
        // TODO: Also do this when fading from old to new envelope.
        
        newSpacialEnvelopeSet = true; // when set, the spacial value 
        // is faded from the old spacial envelope to the new one, in 
        // the interval of one audio block in the upcoming call of
        // getNextAudioBlock(..).
    }
    else
    {
		DEB("AudioSourceDopplerEffect: The newSpacialEnvelope is empty! The spacial envelope hasn't been changed.")
	}
}

inline void AudioSourceDopplerEffect::prepareForNewPosition(int newPosition)
{
    // figure out between which audioEnvelopePoints we are right now
	// and set up all variables needed by getNextAudioBlock(..)
	nextSpacialPointIndex = 1; // since the first audioEnvelopePoint has to be at position 0 
	while (spacialEnvelope[nextSpacialPointIndex].getPosition() <= newPosition)
	{
		nextSpacialPointIndex++;
	}
	
	previousSpacialPoint = spacialEnvelope[nextSpacialPointIndex - 1];
	nextSpacialPoint = spacialEnvelope[nextSpacialPointIndex];

	
	double distance = double (nextSpacialPoint.getPosition() 
                              - previousSpacialPoint.getPosition());
    
	double distanceFromPreviousSpacialPointPosToCurrentPos = double(newPosition 
    - previousSpacialPoint.getPosition());
    
    delayDelta = (nextSpacialPoint.getDistanceDelay() - previousSpacialPoint.getDistanceDelay() ) / distance;
    
    delayOnCurrentSample = previousSpacialPoint.getDistanceDelay()
    + delayDelta * distanceFromPreviousSpacialPointPosToCurrentPos;
}