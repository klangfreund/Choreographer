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
    An AudioSource that generates correlated pink noise. I.e. all the channels
    are fed with the same (mono) pink noise signal.

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
    void setAmplitude (const double newAmplitude_);		

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
	bool newAmplitudeSet;
    double amplitude;
	double newAmplitude;
	double b0, b1, b2; // used for the "pink noise filter"
	Random juceRandom;

    PinkNoiseGeneratorAudioSource (const PinkNoiseGeneratorAudioSource&);
    PinkNoiseGeneratorAudioSource& operator= (const PinkNoiseGeneratorAudioSource&);
};

END_JUCE_NAMESPACE

#endif   // __PINKNOISEGENERATORAUDIOSOURCE_JUCEHEADER__
