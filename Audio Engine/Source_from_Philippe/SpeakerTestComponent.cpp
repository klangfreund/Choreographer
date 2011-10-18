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

//[Headers] You can add your own extra header files here...
//[/Headers]

#include "SpeakerTestComponent.h"


//[MiscUserDefs] You can add your own user definitions and misc code here...
//[/MiscUserDefs]

//==============================================================================
SpeakerTestComponent::SpeakerTestComponent (AudioDeviceManager* audioDeviceManager_)
    : textButtonTest (0),
      labelSpeakerNumber (0),
      labelGain (0),
      sliderSpeakerNumber (0),
      sliderGain (0),
      audioSourcePlayer(),
      pinkNoiseGeneratorAudioSource()
{
    addAndMakeVisible (textButtonTest = new TextButton (T("new button")));
    textButtonTest->setButtonText (T("toggle pink noise"));
    textButtonTest->addButtonListener (this);

    addAndMakeVisible (labelSpeakerNumber = new Label (T("new label"),
                                                       T("speaker number")));
    labelSpeakerNumber->setFont (Font (15.0000f, Font::plain));
    labelSpeakerNumber->setJustificationType (Justification::centredLeft);
    labelSpeakerNumber->setEditable (false, false, false);
    labelSpeakerNumber->setColour (TextEditor::textColourId, Colours::black);
    labelSpeakerNumber->setColour (TextEditor::backgroundColourId, Colour (0x0));

    addAndMakeVisible (labelGain = new Label (T("new label"),
                                              T("gain")));
    labelGain->setFont (Font (15.0000f, Font::plain));
    labelGain->setJustificationType (Justification::centredLeft);
    labelGain->setEditable (false, false, false);
    labelGain->setColour (TextEditor::textColourId, Colours::black);
    labelGain->setColour (TextEditor::backgroundColourId, Colour (0x0));

    addAndMakeVisible (sliderSpeakerNumber = new Slider (T("new slider")));
    sliderSpeakerNumber->setRange (0, 10, 1);
    sliderSpeakerNumber->setSliderStyle (Slider::IncDecButtons);
    sliderSpeakerNumber->setTextBoxStyle (Slider::TextBoxLeft, false, 80, 20);
    sliderSpeakerNumber->addListener (this);

    addAndMakeVisible (sliderGain = new Slider (T("new slider")));
    sliderGain->setRange (0, 1, 0);
    sliderGain->setSliderStyle (Slider::LinearHorizontal);
    sliderGain->setTextBoxStyle (Slider::TextBoxLeft, false, 80, 20);
    sliderGain->addListener (this);


    //[UserPreSize]
	sliderGain->setValue(0.1, true, false);
	
	audioDeviceManager = audioDeviceManager_;
	audioDeviceManager->addAudioCallback(&audioSourcePlayer);
	audioSourcePlayer.setSource(&pinkNoiseGeneratorAudioSource);
	
	// figure out the number of active output channels ...
	AudioIODevice* currentAudioDevice = audioDeviceManager->getCurrentAudioDevice();
	BigInteger activeOutputChannels = currentAudioDevice->getActiveOutputChannels();
	int numberOfActiveOutputChannels = activeOutputChannels.countNumberOfSetBits();
	// ... and report it
	pinkNoiseGeneratorAudioSource.setNumberOfChannels(numberOfActiveOutputChannels);
    //[/UserPreSize]

    setSize (400, 140);

    //[Constructor] You can add your own custom stuff here..
    //[/Constructor]
}

SpeakerTestComponent::~SpeakerTestComponent()
{
    //[Destructor_pre]. You can add your own custom destruction code here..
	audioDeviceManager->removeAudioCallback(&audioSourcePlayer);
    //[/Destructor_pre]

    deleteAndZero (textButtonTest);
    deleteAndZero (labelSpeakerNumber);
    deleteAndZero (labelGain);
    deleteAndZero (sliderSpeakerNumber);
    deleteAndZero (sliderGain);

    //[Destructor]. You can add your own custom destruction code here..
    //[/Destructor]
}

//==============================================================================
void SpeakerTestComponent::paint (Graphics& g)
{
    //[UserPrePaint] Add your own custom painting code here..
    //[/UserPrePaint]

    g.fillAll (Colours::white);

    //[UserPaint] Add your own custom painting code here..
    //[/UserPaint]
}

void SpeakerTestComponent::resized()
{
    textButtonTest->setBounds (240, 104, 150, 24);
    labelSpeakerNumber->setBounds (8, 16, 120, 24);
    labelGain->setBounds (8, 48, 120, 24);
    sliderSpeakerNumber->setBounds (128, 16, 150, 24);
    sliderGain->setBounds (128, 48, 264, 24);
    //[UserResized] Add your own custom resize handling here..
    //[/UserResized]
}

void SpeakerTestComponent::buttonClicked (Button* buttonThatWasClicked)
{
    //[UserbuttonClicked_Pre]
    //[/UserbuttonClicked_Pre]

    if (buttonThatWasClicked == textButtonTest)
    {
        //[UserButtonCode_textButtonTest] -- add your button handler code here..
		pinkNoiseGeneratorAudioSource.toggleNoise(sliderSpeakerNumber->getValue());
        //[/UserButtonCode_textButtonTest]
    }

    //[UserbuttonClicked_Post]
    //[/UserbuttonClicked_Post]
}

void SpeakerTestComponent::sliderValueChanged (Slider* sliderThatWasMoved)
{
    //[UsersliderValueChanged_Pre]
    //[/UsersliderValueChanged_Pre]

    if (sliderThatWasMoved == sliderSpeakerNumber)
    {
        //[UserSliderCode_sliderSpeakerNumber] -- add your slider handling code here..
        //[/UserSliderCode_sliderSpeakerNumber]
    }
    else if (sliderThatWasMoved == sliderGain)
    {
        //[UserSliderCode_sliderGain] -- add your slider handling code here..
		pinkNoiseGeneratorAudioSource.setAmplitude(sliderGain->getValue());
        //[/UserSliderCode_sliderGain]
    }

    //[UsersliderValueChanged_Post]
    //[/UsersliderValueChanged_Post]
}



//[MiscUserCode] You can add your own definitions of your custom methods or any other code here...
//[/MiscUserCode]


//==============================================================================
#if 0
/*  -- Jucer information section --

    This is where the Jucer puts all of its metadata, so don't change anything in here!

BEGIN_JUCER_METADATA

<JUCER_COMPONENT documentType="Component" className="SpeakerTestComponent" componentName=""
                 parentClasses="public Component" constructorParams="" variableInitialisers=""
                 snapPixels="8" snapActive="1" snapShown="1" overlayOpacity="0.330000013"
                 fixedSize="1" initialWidth="400" initialHeight="140">
  <BACKGROUND backgroundColour="ffffffff"/>
  <TEXTBUTTON name="new button" id="d57e66a9bf5df91c" memberName="textButtonTest"
              virtualName="" explicitFocusOrder="0" pos="240 104 150 24" buttonText="test (pink noise)"
              connectedEdges="0" needsCallback="1" radioGroupId="0"/>
  <LABEL name="new label" id="d6e2fa3946725ad9" memberName="labelSpeakerNumber"
         virtualName="" explicitFocusOrder="0" pos="8 16 120 24" edTextCol="ff000000"
         edBkgCol="0" labelText="speaker number" editableSingleClick="0"
         editableDoubleClick="0" focusDiscardsChanges="0" fontname="Default font"
         fontsize="15" bold="0" italic="0" justification="33"/>
  <LABEL name="new label" id="69a6a4710fc0b14f" memberName="labelGain"
         virtualName="" explicitFocusOrder="0" pos="8 48 120 24" edTextCol="ff000000"
         edBkgCol="0" labelText="gain" editableSingleClick="0" editableDoubleClick="0"
         focusDiscardsChanges="0" fontname="Default font" fontsize="15"
         bold="0" italic="0" justification="33"/>
  <SLIDER name="new slider" id="d7890548123a0b0f" memberName="sliderSpeakerNumber"
          virtualName="" explicitFocusOrder="0" pos="128 16 150 24" min="0"
          max="10" int="1" style="IncDecButtons" textBoxPos="TextBoxLeft"
          textBoxEditable="1" textBoxWidth="80" textBoxHeight="20" skewFactor="1"/>
  <SLIDER name="new slider" id="62bbe6859d96d9e8" memberName="sliderGain"
          virtualName="" explicitFocusOrder="0" pos="128 48 264 24" min="0"
          max="1" int="0" style="LinearHorizontal" textBoxPos="TextBoxLeft"
          textBoxEditable="1" textBoxWidth="80" textBoxHeight="20" skewFactor="1"/>
</JUCER_COMPONENT>

END_JUCER_METADATA
*/
#endif
