/*
  ==============================================================================

  This is an automatically generated file created by the Jucer!

  Creation date:  14 Sep 2010 2:37:48pm

  Be careful when adding custom code to these files, as only the code within
  the "//[xyz]" and "//[/xyz]" sections will be retained when the file is loaded
  and re-saved.

  Jucer version: 1.12

  ------------------------------------------------------------------------------

  The Jucer is part of the JUCE library - "Jules' Utility Class Extensions"
  Copyright 2004-6 by Raw Material Software ltd.

  ==============================================================================
*/

#ifndef __JUCER_HEADER_SPEAKERTESTCOMPONENT_SPEAKERTESTCOMPONENT_9D5EB4BE__
#define __JUCER_HEADER_SPEAKERTESTCOMPONENT_SPEAKERTESTCOMPONENT_9D5EB4BE__

//[Headers]     -- You can add your own extra header files here --
#include "../JuceLibraryCode/JuceHeader.h"
#include "PinkNoiseGeneratorAudioSource.h"
//[/Headers]



//==============================================================================
/**
                                                                    //[Comments]
    An auto-generated component, created by the Jucer.

    Describe your class and how it works here!
                                                                    //[/Comments]
*/
class SpeakerTestComponent  : public Component,
                              public ButtonListener,
                              public SliderListener
{
public:
    //==============================================================================
    SpeakerTestComponent (AudioDeviceManager* audioDeviceManager_);
    ~SpeakerTestComponent();

    //==============================================================================
    //[UserMethods]     -- You can add your own custom methods in this section.
    //[/UserMethods]

    void paint (Graphics& g);
    void resized();
    void buttonClicked (Button* buttonThatWasClicked);
    void sliderValueChanged (Slider* sliderThatWasMoved);


    //==============================================================================
    juce_UseDebuggingNewOperator

private:
    //[UserVariables]   -- You can add your own custom variables in this section.
	AudioDeviceManager* audioDeviceManager;
	AudioSourcePlayer audioSourcePlayer;
	PinkNoiseGeneratorAudioSource pinkNoiseGeneratorAudioSource;
    //[/UserVariables]

    //==============================================================================
    TextButton* textButtonTest;
    Label* labelSpeakerNumber;
    Label* labelGain;
    Slider* sliderSpeakerNumber;
    Slider* sliderGain;

    //==============================================================================
    // (prevent copy constructor and operator= being generated..)
    SpeakerTestComponent (const SpeakerTestComponent&);
    const SpeakerTestComponent& operator= (const SpeakerTestComponent&);
};


#endif   // __JUCER_HEADER_SPEAKERTESTCOMPONENT_SPEAKERTESTCOMPONENT_9D5EB4BE__
