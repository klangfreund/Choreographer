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

AudioSourceDopplerEffect::AudioSourceDopplerEffect (AudioSourceGainEnvelope& audioSourceGainEnvelope_)
  : audioSourceGainEnvelope (audioSourceGainEnvelope_),
    newSpacialEnvelopeSet (false)
{
	DEB("AudioSourceDopplerEffect: constructor called.");
}

AudioSourceDopplerEffect::~AudioSourceDopplerEffect()
{
	DEB("AudioSourceDopplerEffect: destructor called.");
}

/** Implementation of the AudioSource method. */
void AudioSourceDopplerEffect::prepareToPlay (int samplesPerBlockExpected, double sampleRate)
{
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
}

/** Implements the PositionableAudioSource method. */
void AudioSourceDopplerEffect::setNextReadPosition (int64 newPosition)
{

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
    
    newSpacialEnvelopeSet = true; // when set, the spacial value 
    // is faded from the old spacial envelope to the new one, in 
    // the interval of one audio block in the getNextAudioBlock(..).
    }
    else
    {
		DEB("AudioSourceDopplerEffect: The newSpacialEnvelope is empty! The spacial envelope hasn't been changed.")
	}
}