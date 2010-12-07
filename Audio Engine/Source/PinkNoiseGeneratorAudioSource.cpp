/*
  ==============================================================================

   This file is a modification of juce_ToneGeneratorAudioSource.cpp, which is
   a sine generator.

  ==============================================================================
*/



// #include "../../core/juce_StandardHeader.h"
#include "PinkNoiseGeneratorAudioSource.h"


//==============================================================================
PinkNoiseGeneratorAudioSource::PinkNoiseGeneratorAudioSource()
    : sampleRate (44100.0),
      amplitude (0.5f),
      makeNoiseOnThisChannels (0),
      fadeIn (0),
      fadeOut (0),
      b0 (0.0f),
      b1 (0.0f),
      b2 (0.0f),
      juceRandom (Time::currentTimeMillis())
{
	// They will be replaced in PinkNoiseGeneratorAudioSource::setNumberOfChannels asap.
	numberOfChannels = 0;
}

PinkNoiseGeneratorAudioSource::~PinkNoiseGeneratorAudioSource()
{
}

//==============================================================================
void PinkNoiseGeneratorAudioSource::setNumberOfChannels (const int numberOfChannels_)
{
	numberOfChannels = numberOfChannels_;
}

bool PinkNoiseGeneratorAudioSource::toggleNoise(int channelNumber)
{
	if (channelNumber >= numberOfChannels || channelNumber < 0)
	{
		// don't do anything, the specified channelNumber is not valid.
		return false;
	}
	if (makeNoiseOnThisChannels[channelNumber] == false)
	{
		// noise on this channel is off, so turn it on.
		makeNoiseOnThisChannels.setBit(channelNumber);
		fadeIn.setBit(channelNumber);
		fadeOut.clearBit(channelNumber);
		return true; // meaning: its know on
	}
	else
	{
		// noise on this channel is on, so turn it off.
		fadeIn.clearBit(channelNumber);
		fadeOut.setBit(channelNumber);
		return false; // meaning: its know off
	}

}

void PinkNoiseGeneratorAudioSource::setAmplitude (const float newAmplitude)
{
    amplitude = newAmplitude;
}

//==============================================================================
void PinkNoiseGeneratorAudioSource::prepareToPlay (int /*samplesPerBlockExpected*/,
                                              double sampleRate_)
{
    sampleRate = sampleRate_;
}

void PinkNoiseGeneratorAudioSource::releaseResources()
{
}

void PinkNoiseGeneratorAudioSource::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
	// only do something if there is at least one channel selected to make noise.
	if (!makeNoiseOnThisChannels.isZero())
	{
		int lastChannel = info.buffer->getNumChannels() - 1;
		
		// generate pink noise and put it on the last channel
		for (int i = 0; i < info.numSamples; ++i)
		{
			// calculation of white noise
			const float white = amplitude * ((2 * juceRandom.nextFloat()) -1);
			// calculation of pink noise (by filtering the white noise)
			//  source: http://www.firstpr.com.au/dsp/pink-noise/
			//   -> Paul Kellet's economy method
			b0 = 0.99765f * b0 + white * 0.0990460f; 
			b1 = 0.96300f * b1 + white * 0.2965164f; 
			b2 = 0.57000f * b2 + white * 1.0526913f; 
			const float pink = b0 + b1 + b2 + white * 0.1848f;
			// const float pink = white;
			
			*info.buffer->getSampleData (lastChannel, info.startSample + i) = pink;
		}
		
		// put the noise to the channels
		int numberOfSetBits = makeNoiseOnThisChannels.countNumberOfSetBits();
		int n = 0; // indicates the current bit that is set.
		for (int i = 0; i < numberOfSetBits; i++)
		{
			n = makeNoiseOnThisChannels.findNextSetBit(n);
			if (n != lastChannel)
			{
			info.buffer->copyFrom(n, info.startSample, *info.buffer, lastChannel, info.startSample, info.numSamples);
			}
			
			if (fadeIn[n] == true)
			{
				info.buffer->applyGainRamp(n, info.startSample, info.numSamples, 0.0, 1.0);
				fadeIn.clearBit(n);
			}
			if (fadeOut[n] == true) 
			{
				info.buffer->applyGainRamp(n, info.startSample, info.numSamples, 1.0, 0.0);
				fadeOut.clearBit(n);
				makeNoiseOnThisChannels.clearBit(n);
			}
			n++;
		}
		
		
		// the last channel was used as temporary buffer. In case it should be silent:
		if (makeNoiseOnThisChannels[lastChannel] == false) 
		{
			info.buffer->clear(lastChannel, info.startSample, info.numSamples);
		}
	}
}