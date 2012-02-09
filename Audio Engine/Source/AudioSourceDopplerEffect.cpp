/*
 *  AudioSourceAmbipanning.cpp
 *  Choreographer
 *
 *  Created by Samuel Gaehwiler on 120104.
 *  Copyright 2012. All rights reserved.
 *
 */

#include "AudioSourceDopplerEffect.h"
#include <float.h> // To be able to use DBL_MAX

const double SpacialPosition::oneOverSpeedOfSound = 0.00294; // = 1.0/340.0 m/s

//==============================================================================

AudioSourceDopplerEffect::AudioSourceDopplerEffect (AudioSourceGainEnvelope& audioSourceGainEnvelope_, double sampleRate_)
  : audioSourceGainEnvelope (audioSourceGainEnvelope_),
    sampleRate (sampleRate_),
    newSpacialEnvelopeSet (false),
    previousSpacialPoint (),
    nextSpacialPoint (),
    currentSpacialPosition (),
    deltaSpacialPosition (),
    sourceBuffer(1,0)
{
	DEB("AudioSourceDopplerEffect: constructor called.");
    
    sourceInfo.buffer = &sourceBuffer;
    oneOverSampleRate = 1/sampleRate_;
    
    // Define an initial spacial envelope.
	newSpacialEnvelope.add(new SpacialEnvelopePoint(0,      // time (in samples)
                                                    0,      // x
                                                    0,      // y
                                                    0));	// z);
	spacialEnvelope.addCopiesOf(newSpacialEnvelope);
	
	constantSpacialPosition = true;
}

AudioSourceDopplerEffect::~AudioSourceDopplerEffect()
{
	DEB("AudioSourceDopplerEffect: destructor called.");
}

/** Implementation of the AudioSource method. */
void AudioSourceDopplerEffect::prepareToPlay (int samplesPerBlockExpected_, double sampleRate_)
{
    sampleRate = sampleRate_;
    oneOverSampleRate = 1/sampleRate_;
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

/** Implements the PositionableAudioSource method. */
void AudioSourceDopplerEffect::setNextReadPosition (int64 newPosition)
{
    DEB("AudioSourceDopplerEffect.setNextReadPosition: newPosition = " + String(newPosition))
    
	// If the newPosition is not at the expected position, right after the end
	// of the last audio block
	if (audioBlockEndPosition != newPosition)
	{
		DEB("AudioSourceDopplerEffect.setNextReadPosition: newPosition = "
            + String(newPosition))
		DEB("AudioSourceDopplerEffect.setNextReadPosition: expected newPosition: " 
			+ String(audioBlockEndPosition))
		
        if (!constantSpacialPosition)
        {
            // Figure out between which audioEnvelopePoints we are right now
            // and set up all variables needed by getNextAudioBlock(..)
            nextSpacialPointIndex = 1;
            prepareForNewPosition(newPosition, 
                                  &nextSpacialPointIndex,
                                  &previousSpacialPoint,
                                  &nextSpacialPoint,
                                  &currentSpacialPosition,
                                  &deltaSpacialPosition);
        }
	}
	
	nextPlayPosition = newPosition;
    
    // Set the nextPlayPosition for the audioSourceGainEnvelope
    // --------------------------------------------------------
    if (constantSpacialPosition)
    { 
        audioSourceGainEnvelope.setNextReadPosition(nextPlayPosition - constantSpacialPositionDelayTimeInSamples);
        // If the argument (nextPlayPosition - 
        // constantSpacialPositionDelayTimeInSamples) is smaller than zero,
        // this will set the playhead to the position (argument mod fileLength).
    }
    // If the spacial envelope contains multiple points.
    else
    {
        // audioSourceGainEnvelope.setNextReadPosition will be called in the
        // getNextAudioBlock.
    }
}

/** Implementation of the AudioSource method. */
void AudioSourceDopplerEffect::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
    DEB("AudioSourceDopplerEffect::getNextAudioBlock: nextPlayPosition = " + String(nextPlayPosition))
    DEB("AudioSourceDopplerEffect::getNextAudioBlock: info.numSamples = " + String(info.numSamples))

    
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
        
        spacialEnvelope.clear();
        spacialEnvelope.addCopiesOf(newSpacialEnvelope);
        
        // For the first sample (from the old spacial envelope).
//        double delayOnFirstSample = delayOnCurrentSample;
        SpacialPosition spacialPositionOfFirstSample = currentSpacialPosition;
        
        // For the last sample (from the new spacial envelope).
//        double delayOnLastSample;
        SpacialPosition spacialPositionOfLastSample;

        if (spacialEnvelope.size() == 1)
        {
            nextSpacialPoint = spacialEnvelope[0];
//            delayOnLastSample = nextSpacialPoint->getDistanceDelay();
            spacialPositionOfLastSample = SpacialPosition(*nextSpacialPoint);
            deltaSpacialPosition = SpacialPosition(0,0,0);
                // deltaSpacialPosition = The difference in space between
                // two adjacent samples AFTER this audio block. I.e. the
                // deltaSpacialPosition for the new spacialEnvelope.
                // It's not actually used in this case, but for convenience
                // it is set.
            
            constantSpacialPosition = true;
            constantSpacialPositionDelayTimeInSamples = int ( floor(sampleRate*SpacialPosition(*nextSpacialPoint).delay()) );
        }
        else
        {
            constantSpacialPosition = false;
            // We need to figure out the delay time on the last sample
            // (= the first sample of the next audio block)
            nextSpacialPointIndex = 1;
            prepareForNewPosition(audioBlockEndPosition,
                                  &nextSpacialPointIndex,
                                  &previousSpacialPoint,
                                  &nextSpacialPoint,
                                  &currentSpacialPosition,
                                  &deltaSpacialPosition);
                // deltaSpacialPosition = The difference between
                // two adjacent samples AFTER this audio block. I.e. the
                // deltaSpacialPosition for the new spacialEnvelope.
            
            // prepareForNewPosition will also set currentSpacialPosition for 
            // the position audioBlockEndPosition.
//            delayOnLastSample = delayOnCurrentSample;
            spacialPositionOfLastSample = currentSpacialPosition;
        }
        
        // Determine the deltaSpacialPosition needed for this audioBlock.
//        double timeDifferenceForTheNextAudioBlock = timeDifference;
        SpacialPosition deltaSpacialPositionForTheNextAudioBlock = deltaSpacialPosition;
//        timeDifference = oneOverSampleRate + (delayOnLastSample - delayOnFirstSample) / info.numSamples;
        deltaSpacialPosition = (spacialPositionOfLastSample - spacialPositionOfFirstSample)*(1.0/info.numSamples);
        
        // Figure out the lowest and highest sample positions needed.
        // (such that we can request a corresponding audio block from the
        //  audioSourceGainEnvelope.)
//        int startSample = audioBlockStartPosition + 
//                floor(delayOnFirstSample * sampleRate);
        int startSample = audioBlockStartPosition + 
        floor(spacialPositionOfFirstSample.delay() * sampleRate);
//        int endSample = audioBlockEndPosition + 
//                floor(delayOnLastSample * sampleRate);
        int endSample = audioBlockEndPosition + 
        floor(spacialPositionOfLastSample.delay() * sampleRate);
        
        int firstSampleOfDesiredAudioBlock = floor(jmin(startSample, endSample));
        int lastSampleOfDesiredAudioBlock = ceil(jmax(startSample, endSample));
        int numberOfSamplesForAudioBlock = lastSampleOfDesiredAudioBlock -
                                           firstSampleOfDesiredAudioBlock;
        
        // The sourceInfo.buffer is big enough to hold the biggest audio blocks
        // for the current and for the next spacial envelope, but it might be
        // too small for this transition from the current to the next envelope.
        // In this case we need to allocate more memory.
        if (sourceInfo.buffer->getNumSamples() < numberOfSamplesForAudioBlock)
        {
            DEB("AudioSourceDopplerEffect: MEMORY ALLOCATION in the "
                "getNextAudioBlock during the transition from an old "
                "to a new spacial envelope.")
            
            bool keepExistingContent = false;
            sourceInfo.buffer->setSize(1, 
                                       numberOfSamplesForAudioBlock, 
                                       keepExistingContent);
        }
                
        // Request the audio block from audioSourceGainEnvelope
        audioSourceGainEnvelope.setNextReadPosition(firstSampleOfDesiredAudioBlock);
        sourceInfo.startSample = 0;
        sourceInfo.numSamples = numberOfSamplesForAudioBlock;
        audioSourceGainEnvelope.getNextAudioBlock(sourceInfo);
        
        
        // Fill the info.buffer
        // --------------------
        float * sampleOfSource = sourceInfo.buffer->getSampleData(0);
        float * sampleOfDestination = info.buffer->getSampleData(0);
//        double absoluteSamplePositionInSeconds = audioBlockStartPosition/
//                                                 sampleRate +
//                                                 delayOf(spacialPositionOfFirstSample);
        // Relative to the first sample of the audioSourceGainEnvelope audio
        // block.
//        double relativeSamplePositionInSeconds = absoluteSamplePositionInSeconds -
//        (startSample * oneOverSampleRate);
        
        
        // The absolute position in the audio file without any delay. In seconds.
        double currentPositionWithoutDelay = audioBlockStartPosition*oneOverSampleRate;
        // The relative position in the audio file, relative to the 
        // firstSampleOfDesiredAudioBlock. In seconds.
        double currentRelativePositionWithoutDelay = currentPositionWithoutDelay 
            - firstSampleOfDesiredAudioBlock*oneOverSampleRate;
        currentSpacialPosition = spacialPositionOfFirstSample;
        for (int i=info.startSample; 
             i != (info.numSamples + info.startSample); ++i)
        {
            // \/  \/  \/  \/  \/  \/  \/
            // TODO: Implement proper interpolation!
            // HERE (the dirty implementation): Take the closest sample before.
            int posInSource = int(floor((currentRelativePositionWithoutDelay + currentSpacialPosition.delay())*sampleRate));
            sampleOfDestination[i] = sampleOfSource[ posInSource];
            // /\  /\  /\  /\  /\  /\  /\
            
//            relativeSamplePositionInSeconds += timeDifference;
            // To determine the next source sample:
            currentRelativePositionWithoutDelay += oneOverSampleRate;
            currentSpacialPosition += deltaSpacialPosition;
        }

//        timeDifference = timeDifferenceForTheNextAudioBlock;
        deltaSpacialPosition = deltaSpacialPositionForTheNextAudioBlock;
        currentSpacialPosition = spacialPositionOfLastSample;
        newSpacialEnvelopeSet = false;
    }
    
    // The regular case
    // ================
    else
    {
        // If the spacialEnvelop contains only one point.
		if (constantSpacialPosition)
		{
            // If there is only one point in the spacial envelope,
            // a constant delay is applied.
            // To avaid noise added by interpolation, we sacrify
            // delay time accuracy and adjust the delay time such that
            // the delay time is a multiple of 1/sampleRate.
            // See constantSpacialPositionDelayTimeInSamples.
            audioSourceGainEnvelope.getNextAudioBlock(info);
        }
        
        // If there are multiple points in the spacialEnvelope.
        else
        {
            // Get enough samples from the audioSourceGainEnvelope to interpolate.
            // -------------------------------------------------------------------
            
            // Figure out the lowest and highest sample positions needed.
            // ----------------------------------------------------------
            // (such that we can request a corresponding audio block from the
            //  audioSourceGainEnvelope.)
            // These values are absolute ones (according to the corresponding
            // audio file)
            double lowestPositionToRequestInSeconds = DBL_MAX;
            double highestPositionToRequestInSeconds = -DBL_MAX;
            
            // Remember the nextSpacialPointIndex.
            // (Needed a couple of lines below when calling
            // prepareForNewPosition for the audioBlockStartPosition.)
            int nextSpacialPointIndexForAudioBlockStartPosition = nextSpacialPointIndex;
            
            // Figure out the positions (incl. delay) of all spacial points
            // contained in this block - if any.
            while (nextSpacialPoint->getPosition() < audioBlockEndPosition)
            {
                prepareForNewPosition(nextSpacialPoint->getPosition(),
                                      &nextSpacialPointIndex,
                                      &previousSpacialPoint,
                                      &nextSpacialPoint,
                                      &currentSpacialPosition,
                                      &deltaSpacialPosition);
                    // This will set the nextSpacialPoint to
                    // the previousSpacialPoint!
                    // And set nextSpacialPoint to the next one.
                double positionOfPreviousSpacialPointInSeconds 
                    = previousSpacialPoint->getPosition()*oneOverSampleRate 
                    + currentSpacialPosition.delay();
                lowestPositionToRequestInSeconds 
                    = jmin(lowestPositionToRequestInSeconds,
                           positionOfPreviousSpacialPointInSeconds);
                highestPositionToRequestInSeconds 
                    = jmax(highestPositionToRequestInSeconds,
                           positionOfPreviousSpacialPointInSeconds);
            }
   
            // Figure out the position (incl. delay) of audioBlockEndPosition-1
            // (the last sample of this audio block):
            prepareForNewPosition(audioBlockEndPosition-1, 
                                  &nextSpacialPointIndex,
                                  &previousSpacialPoint,
                                  &nextSpacialPoint,
                                  &currentSpacialPosition,
                                  &deltaSpacialPosition);
                // To calculate the currentSpacialPosition
            double audioBlockEndPositionMinusOneInSeconds 
                = (audioBlockEndPosition-1)*oneOverSampleRate
                + currentSpacialPosition.delay();
            lowestPositionToRequestInSeconds = jmin(lowestPositionToRequestInSeconds,
                                                    audioBlockEndPositionMinusOneInSeconds);
            highestPositionToRequestInSeconds = jmax(highestPositionToRequestInSeconds,
                                                     audioBlockEndPositionMinusOneInSeconds);
            
            // Figure out the position (incl. delay) of audioBlockStartPosition:
            nextSpacialPointIndex = nextSpacialPointIndexForAudioBlockStartPosition;
            prepareForNewPosition(audioBlockStartPosition, 
                                  &nextSpacialPointIndex,
                                  &previousSpacialPoint,
                                  &nextSpacialPoint,
                                  &currentSpacialPosition,
                                  &deltaSpacialPosition);
                // This will reset the parameters as needed in the upcoming code.
                // It will also increase precision.
                // How come? Imagine we are between two spacial points that are
                // far away from each other. Of course the positions (incl. the
                // delay from the envelope) of all samples in between are well
                // defined by the position (incl. delay) of the first sample and
                // the timeDifference... if doubles would be totally accurate.
                // The error of timeDifference will grow linear in time. To avoid
                // big errors, on every first sample in an audio block the 
                // position (incl. delay) will be recalculated.
            double audioBlockStartPositionInSeconds 
                = audioBlockStartPosition * oneOverSampleRate
                + currentSpacialPosition.delay();
            lowestPositionToRequestInSeconds = jmin(lowestPositionToRequestInSeconds,
                                                    audioBlockStartPositionInSeconds);
            highestPositionToRequestInSeconds = jmax(highestPositionToRequestInSeconds,
                                                     audioBlockStartPositionInSeconds);
            


            // Fill the sourceBuffer with samples
            // ----------------------------------
            int lowestPositionToRequest = int(floor(lowestPositionToRequestInSeconds 
                * sampleRate));
            int highestPositionToRequest = int(ceil(highestPositionToRequestInSeconds
                * sampleRate));
            DEB("AudioSourceDopplerEffect::getNextAudioBlock: lowestPositionToRequest = " + String(lowestPositionToRequest))
            DEB("AudioSourceDopplerEffect::getNextAudioBlock: highestPositionToRequest = " + String(highestPositionToRequest))
            
            audioSourceGainEnvelope.setNextReadPosition(lowestPositionToRequest);
            
            int numberOfSamplesForAudioBlock = highestPositionToRequest - lowestPositionToRequest + 1;
                // Why "+1"?
                // Example: h=2, l=0  =>  numberOfSamples must be 3 (0,1 and 2).
            
            // The sourceInfo.buffer should actually be big enough.
            // This has been ensured in the method setSpacialEnvelope.
            // But if the info.buffer->getNumSamples() is much bigger than
            // the samplesPerBlockExpected we need to allocate more memory.
            if (sourceInfo.buffer->getNumSamples() < numberOfSamplesForAudioBlock)
            {
                DEB("AudioSourceDopplerEffect: MEMORY ALLOCATION in the "
                    "getNextAudioBlock! "
                    "info.buffer->getNumSamples() = " 
                    + String(info.buffer->getNumSamples()))
                
                bool keepExistingContent = false;
                sourceInfo.buffer->setSize(1, 
                                           numberOfSamplesForAudioBlock, 
                                           keepExistingContent);
            }
            sourceInfo.startSample = 0;
            sourceInfo.numSamples = numberOfSamplesForAudioBlock;
            audioSourceGainEnvelope.getNextAudioBlock(sourceInfo);
            
            
            // Do the actual work (fill that info buffer)
            // ==========================================
            int currentPosition = audioBlockStartPosition;
            
            // For every sample in the AudioSampleBuffer info, figure out the
            // (delayed) position in the audio file.
            
            // Even thought this is not necessary, 
            prepareForNewPosition(currentPosition, 
                                  &nextSpacialPointIndex,
                                  &previousSpacialPoint,
                                  &nextSpacialPoint,
                                  &currentSpacialPosition,
                                  &deltaSpacialPosition);
            
            // The position of the current sample (the one that is requested)
            // in the audio file.
//            double absolutePositionInSeconds = currentPosition * oneOverSampleRate
//                                                        + currentSpacialPosition.delay();
//            double relativePositionInSeconds = absolutePositionInSeconds -
//                                               lowestPositionToRequestInSeconds;
            
            // The absolute position in the audio file without any delay. In seconds.
            double currentPositionWithoutDelay = currentPosition*oneOverSampleRate;
            // The relative position in the audio file, relative to the 
            // firstSampleOfDesiredAudioBlock. In seconds.
            double currentRelativePositionWithoutDelay = currentPositionWithoutDelay 
            - lowestPositionToRequestInSeconds;
            
            float * sampleOfSource = sourceInfo.buffer->getSampleData(0);
            float * sampleOfDestination = info.buffer->getSampleData(0);
            // Maybe there is an offset for the source buffer, so take care
            // of that:
            sampleOfDestination += info.startSample;
            
            // Go through all spacial points lying inside of this audio block.
			while (true)
			{
                // If the next spacial point is outside of the current audio block
				// (audioBlockEndPosition is the position of to the first sample
				//  after the current block)
				if (nextSpacialPoint->getPosition() >= audioBlockEndPosition )
				{
                    while (currentPosition != audioBlockEndPosition) 
                    {
                        // \/  \/  \/  \/  \/  \/  \/
                        // TODO: Implement proper interpolation!
                        // HERE (the dirty implementation): Take the closest 
                        //      sample before.
//                        int posInSource = int(floor((currentRelativePositionWithoutDelay + currentSpacialPosition.delay())*sampleRate));
//                        *sampleOfDestination = sampleOfSource[ posInSource ];
                        *sampleOfDestination = *sampleOfSource;
                        ++sampleOfSource;
                        // ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^
                        
                        // Determine the next destination sample:
                        ++sampleOfDestination; // Point to the next sample
                        // To determine the next source sample:
                        currentRelativePositionWithoutDelay += oneOverSampleRate;
                        currentSpacialPosition += deltaSpacialPosition;
                        
                        ++currentPosition;
                    }
                    
                    // temp
//                    sampleOfDestination = info.buffer->getSampleData(0);
//                    for (int pos=0; pos!=info.numSamples; ++pos)
//                    {
//                        if (sampleOfDestination[pos] == 0.0)
//                        {
//                            DEB("A zero at pos = " + String(pos));
//                        }
//                    }
                    // end temp
                    
					break;
				}
                
                // If the next gain point is inside the current audio block
				else
				{
					// Apply the delay from the spacial envelope up to the 
                    // sample before the nextSpacialPoint
					while (currentPosition != nextSpacialPoint->getPosition())
					{
						// \/  \/  \/  \/  \/  \/  \/
                        // TODO: Implement proper interpolation!
                        // HERE (the dirty implementation): Take the closest 
                        //      sample before.
                        int posInSource = int(floor((currentRelativePositionWithoutDelay + currentSpacialPosition.delay())*sampleRate));
                        *sampleOfDestination = sampleOfSource[ posInSource ];
                        // ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^
                        
                        // Determine the next destination sample:
                        ++sampleOfDestination; // Point to the next sample
                        // To determine the next source sample:
                        currentRelativePositionWithoutDelay += oneOverSampleRate;
                        currentSpacialPosition += deltaSpacialPosition;
                        
                        ++currentPosition;
					}
                    
                    // Also process the sample at the nextSpacialPoint and set
                    // up the parameters for further processing.
                    prepareForNewPosition(currentPosition,
                                          &nextSpacialPointIndex,
                                          &previousSpacialPoint,
                                          &nextSpacialPoint,
                                          &currentSpacialPosition,
                                          &deltaSpacialPosition);
                    currentPositionWithoutDelay = currentPosition*oneOverSampleRate;
                    currentRelativePositionWithoutDelay = currentPositionWithoutDelay 
                    - highestPositionToRequestInSeconds;
                    // \/  \/  \/  \/  \/  \/  \/
                    // TODO: Implement proper interpolation!
                    // HERE (the dirty implementation): Take the closest 
                    //      sample before.
                    double delay = currentSpacialPosition.delay();
                    int posInSource = int(floor((currentRelativePositionWithoutDelay + delay)*sampleRate));
                    *sampleOfDestination = sampleOfSource[ posInSource ];
                    // ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^
                    
                    // Determine the next destination sample:
                    ++sampleOfDestination; // Point to the next sample
                    // To determine the next source sample:
                    currentRelativePositionWithoutDelay += oneOverSampleRate;
                    currentSpacialPosition += deltaSpacialPosition;
                    
                    ++currentPosition;
                }
            }   
        }
    }
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
        // STEP 1: Copy the envelope
        // -------------------------
        // Copy the elements over from the Array newSpacialEnvelope_ to the
        // OwnedArray newSpacialEnvelope.
        newSpacialEnvelope.clear();
        for (int i=0; i!=newSpacialEnvelope_.size(); ++i)
        {
            newSpacialEnvelope.add(new SpacialEnvelopePoint(newSpacialEnvelope_[i]));
        }
        
        // STEP 2: Set the buffer size
        // ---------------------------
        // Set the buffer size such that it is big enough for the fastest
        // movements in the new spacial envelope.
        // In STEP 3 we will add an additional point between 2 adjecent points
        // if the distance to the origin is closer than on the other two points.
        // The change in distance (per sample) is bigger on the 2 original
        // points. Thats why this step comes first (to save some calculations).
        
        double highestSlope = 0.0; // seconds / sample
        double lowestSlope = 0.0; // seconds / sample
        // if newSpacialEnvelope.size() == 1, highestSlope = lowestSlope = 0
        if (newSpacialEnvelope.size() > 1)
        {
            for (int k=1; k<newSpacialEnvelope.size(); k++)
            {
                SpacialEnvelopePoint * previousEnvPoint = newSpacialEnvelope[k-1];
                SpacialEnvelopePoint * nextEnvPoint = newSpacialEnvelope[k];
                
                if (previousEnvPoint != nextEnvPoint)
                {
                    // Figure out the highest and lowest change of [distance
                    // to origin] between two adjecent samples on this segment
                    // of the envelope.
                    
                    // The time distance in samples between the two
                    // spacial envelope points
                    double distance = double (nextEnvPoint->getPosition() - previousEnvPoint->getPosition());
                    
                    SpacialPosition previousPoint (*previousEnvPoint);
                    SpacialPosition nextPoint (*nextEnvPoint);
                    SpacialPosition spacialDelta = (nextPoint - previousPoint) * (1./distance);
                    SpacialPosition previousPointPlusOne = previousPoint + spacialDelta;
                    SpacialPosition nextPointMinusOne = nextPoint - spacialDelta;
                    
                    double slope1 = previousPointPlusOne.delay() - previousPoint.delay(); // seconds / sample
                    double slope2 = nextPoint.delay() - nextPointMinusOne.delay(); // seconds / sample
                    
                    highestSlope = jmax(jmax(highestSlope, slope1), slope2); // will be >= 0
                    lowestSlope = jmin(jmin(lowestSlope, slope1), slope2); // will be <= 0
                }
            }
        }
        // The highest and lowest time difference between two adjacent
        // (output) samples.
        double regularDifference = oneOverSampleRate;
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
        
        // STEP 3
        // ------
        // Figure out the points on the envelope that are locally closest to 
        // the origin. I.e. for two neighbouring envelope points check if there
        // might be a point in between that is closest to the origin.
        // If so, add this point to the envelope.
        // At the end of this procedure, the points closest and farest away
        // from the origin are explicit points of the envelope.
        OwnedArray<SpacialEnvelopePoint> closestPointsInBetween;
        if (newSpacialEnvelope.size()>1)
        {
            for (int i=1; i!=newSpacialEnvelope.size(); ++i)
            {
                SpacialPosition a = SpacialPosition(newSpacialEnvelope[i-1]->getX(),
                                                    newSpacialEnvelope[i-1]->getY(),
                                                    newSpacialEnvelope[i-1]->getZ());
                SpacialPosition b = SpacialPosition(newSpacialEnvelope[i]->getX(),
                                                    newSpacialEnvelope[i]->getY(),
                                                    newSpacialEnvelope[i]->getZ());
                // a and b are positions in space without a 4rd time argument
                // like SpacialEnvelopePoints.
                
                // If a == b they are at the same position in space and
                // all points in between are equally close to the origin.
                if (a != b)
                {
                    // See my notes 120123_doppler_fx_closest_point.tif for
                    // more details of the upcoming calculation.
                    
                    // n is a vector that specifies the direction of the line
                    // defined by a and b.
                    SpacialPosition n = b - a;
                    
                    // With the scalar product, we can specify a plane
                    // that is perpendicular to the line and intersects with
                    // the origin:
                    //  {r in Reals^3 ; <r,n> = 0}
                    //
                    // The line can be parametrised:
                    //  {a + t*n ; t in Reals}
                    //
                    // The intersection of the line and the plane will result
                    // in the point (p) on the line closest to the origin.
                    // So lets intersect!
                    // I.e. put the parametrised line into the equation of
                    // the plane and solve for t...
                    //  <a + tn, n> = 0
                    //  <a,n> + t <n,n> = 0
                    //  t = - <a,n>/<n,n>
                    // ... and put this t into the parametrisation of the line:
                    //  p = a - <a,n>/<n,n> * n
                    
                    // The point closest to the origin
                    SpacialPosition p = a - ((a*n)/(n*n))*n;
                    
                    // Does this point lie in between a and b?
                    // It is sufficient to look at one coordinate.
                    double * smallerX = a.x < b.x ? &a.x : &b.x;
                    double * biggerX =  a.x < b.x ? &b.x : &a.x;
                    if (p.x > *smallerX && p.x < *biggerX)
                    {
                        // If the point lies in between a and b,
                        // add it to the closestPointsInBetween array.
                        // (Otherwise don't)
                        
                        // Figure out the time position for this new point
                        double positionOfA = double (newSpacialEnvelope[i-1]->getPosition());
                        double positionOfB = double (newSpacialEnvelope[i]->getPosition());
                        
                        // (posOfP-posOfA)/(posOfB-posOfA) = (p.x-a.x)/(b.x-a.x)
                        double positionOfP = positionOfA + (p.x - a.x)/(b.x - a.x) * (positionOfB - positionOfA);
                        
                        SpacialEnvelopePoint* newSpacialEnvPoint = 
                            new SpacialEnvelopePoint(p.x, p.y, p.z,
                                                     floor(positionOfP + 0.5));
                            // positionOfP is positive
                            // => floor(positionOfP + 0.5) == round(positionOfP)
                        closestPointsInBetween.add(newSpacialEnvPoint);
                    }
                }
            }
        }
        
        // Add the points from closestPointsInBetween to the newSpacialEnvelope.
        if (closestPointsInBetween.size() > 0)
        {
            // start debugging
            for (int i=0; i!=closestPointsInBetween.size(); ++i)
            {
                DEB("AudioSourceDopplerEffect: setSpacialEnvelope:")
                DEB("closestPointsInBetween[" + String(i) + "]->getPosition() ="
                    + String(closestPointsInBetween[i]->getPosition()))
            }
            // end debugging
            
            // Add the newly found points to the newSpacialEnvelope.
            newSpacialEnvelope.addCopiesOf(closestPointsInBetween);
            
            // Sort the newSpacialEnvelope
            newSpacialEnvelope.sort(spacialEnvelopePointPointerComparator);
            
            // start debugging
            for (int i=0; i!=newSpacialEnvelope.size(); ++i)
            {
                DEB("AudioSourceDopplerEffect: setSpacialEnvelope:")
                DEB("newSpacialEnvelope[" + String(i) + "]->getPosition() ="
                    + String(newSpacialEnvelope[i]->getPosition()))
            }
            // end debugging
            
        }
        
        // STEP 4
        // ------
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

inline void AudioSourceDopplerEffect::prepareForNewPosition (int newPosition,
                                   int * nextSpacialPointIndex_,
                                   SpacialEnvelopePoint ** previousSpacialPoint_,
                                   SpacialEnvelopePoint ** nextSpacialPoint_,
                                   SpacialPosition * currentSpacialPosition_,
                                   SpacialPosition * deltaSpacialPosition_)
{    
    // Figure out between which audioEnvelopePoints we are right now
	// and set up
    // - *nextSpacialPointIndex_
    // - previousSpacialPoint_
    // - nextSpacialPoint_
	while (spacialEnvelope[nextSpacialPointIndex]->getPosition() <= newPosition)
	{
		(*nextSpacialPointIndex_)++;
	}
	*previousSpacialPoint_ = spacialEnvelope[*nextSpacialPointIndex_ - 1];
	*nextSpacialPoint_ = spacialEnvelope[*nextSpacialPointIndex_];

	// Figure out
    // - *currentSpacialPosition_
    // - *deltaSpacialPosition_
    
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

    deltaSpacialPosition_->x = ((*nextSpacialPoint_)->getX() - (*previousSpacialPoint_)->getX())/distance;
    deltaSpacialPosition_->y = ((*nextSpacialPoint_)->getY() - (*previousSpacialPoint_)->getY())/distance;
    deltaSpacialPosition_->z = ((*nextSpacialPoint_)->getZ() - (*previousSpacialPoint_)->getZ())/distance;
}