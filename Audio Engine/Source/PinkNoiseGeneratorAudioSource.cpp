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
    : amplitude (0.5),
      b0 (0.0),
      b1 (0.0),
      b2 (0.0),
      juceRandom (Time::currentTimeMillis())
{
}

PinkNoiseGeneratorAudioSource::~PinkNoiseGeneratorAudioSource()
{
}

//==============================================================================
void PinkNoiseGeneratorAudioSource::setAmplitude (const double newAmplitude)
{
    amplitude = newAmplitude;
}

//==============================================================================
void PinkNoiseGeneratorAudioSource::prepareToPlay (int samplesPerBlockExpected,
												   double sampleRate)
{
    return;
}

void PinkNoiseGeneratorAudioSource::releaseResources()
{
}

void PinkNoiseGeneratorAudioSource::getNextAudioBlock (const AudioSourceChannelInfo& info)
{
	int lastChannel = info.buffer->getNumChannels() - 1;
	
	// generate pink noise and put it on the last channel
	for (int i = 0; i < info.numSamples; ++i)
	{
		// calculation of white noise
		double white = amplitude * ((2.0 * juceRandom.nextDouble()) -1.0);
		// calculation of pink noise (by filtering the white noise)
		//  source: http://www.firstpr.com.au/dsp/pink-noise/
		//   -> Paul Kellet's economy method
		b0 = 0.99765f * b0 + white * 0.0990460f; 
		b1 = 0.96300f * b1 + white * 0.2965164f; 
		b2 = 0.57000f * b2 + white * 1.0526913f; 
		double pink = b0 + b1 + b2 + white * 0.1848f;
		// pink = white;
		
		*info.buffer->getSampleData (lastChannel, info.startSample + i) = pink;
	}
	
	// put the (same) noise to the remaining channels
	if (lastChannel > 0)
	{
		for (int i = 0; i < lastChannel; i++)
		{
				info.buffer->copyFrom(i, info.startSample, *info.buffer, lastChannel, info.startSample, info.numSamples);
		}
	}
}