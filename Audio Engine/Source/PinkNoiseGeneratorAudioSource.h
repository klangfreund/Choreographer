/*
  ==============================================================================

 This file is a modification of juce_ToneGeneratorAudioSource.h, which is
 a sine generator.

  ==============================================================================
*/

#ifndef __PINKNOISEGENERATORAUDIOSOURCE_JUCEHEADER__
#define __PINKNOISEGENERATORAUDIOSOURCE_JUCEHEADER__

#include "../JuceLibraryCode/JuceHeader.h"

BEGIN_JUCE_NAMESPACE

//==============================================================================
/**
    A simple AudioSource that generates pink noise.

*/
class JUCE_API  PinkNoiseGeneratorAudioSource  : public AudioSource
{
public:
    //==============================================================================
    /** Creates a PinkNoiseGeneratorAudioSource. */
    PinkNoiseGeneratorAudioSource();

    /** Destructor. */
    ~PinkNoiseGeneratorAudioSource();

    //==============================================================================
    /** Sets the signal's amplitude. */
    void setNumberOfChannels (const int numberOfChannels_);

    /** Toggles (on / off) the pink noise on the specified channel. */	
	bool toggleNoise(int channelNumber);
	
    /** Sets the signal's amplitude. */
    void setAmplitude (const float newAmplitude);	
	

    //==============================================================================
    /** Implementation of the AudioSource method. */
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate);

    /** Implementation of the AudioSource method. */
    void releaseResources();

    /** Implementation of the AudioSource method. */
    void getNextAudioBlock (const AudioSourceChannelInfo& bufferToFill);


    //==============================================================================
    juce_UseDebuggingNewOperator

private:
    //==============================================================================
	double sampleRate;
    float amplitude;
	float b0, b1, b2; // used for the "pink noise filter"
	Random juceRandom;
	
	int numberOfChannels; // These are the active channels. Its the same number as
						// info.buffer->getNumChannels() in getNextAudioBlock.
	BigInteger makeNoiseOnThisChannels; // The bits specifies, if noise should be
										// put on the corresponding channel.
	BigInteger fadeIn;
	BigInteger fadeOut;

    PinkNoiseGeneratorAudioSource (const PinkNoiseGeneratorAudioSource&);
    PinkNoiseGeneratorAudioSource& operator= (const PinkNoiseGeneratorAudioSource&);
};

END_JUCE_NAMESPACE

#endif   // __PINKNOISEGENERATORAUDIOSOURCE_JUCEHEADER__
