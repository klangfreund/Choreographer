/*
  ==============================================================================

   This file is part of the JUCE library - "Jules' Utility Class Extensions"
   Copyright 2004-10 by Raw Material Software Ltd.

  ------------------------------------------------------------------------------

   JUCE can be redistributed and/or modified under the terms of the GNU General
   Public License (Version 2), as published by the Free Software Foundation.
   A copy of the license is included in the JUCE distribution, or can be found
   online at www.gnu.org/licenses.

   JUCE is distributed in the hope that it will be useful, but WITHOUT ANY
   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
   A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

  ------------------------------------------------------------------------------

   To release a closed-source product which uses JUCE, commercial licenses are
   available: visit www.rawmaterialsoftware.com/juce for more information.

 
   Slightly modified by sam
 
  ==============================================================================
*/

//#include "../../../core/juce_StandardHeader.h"

#include "AudioDeviceSelectorComponentMod.h"
//#include "../buttons/juce_TextButton.h"
//#include "../menus/juce_PopupMenu.h"
//#include "../windows/juce_AlertWindow.h"
//#include "../lookandfeel/juce_LookAndFeel.h"
//#include "../../../text/juce_LocalisedStrings.h"


//==============================================================================
AudioDeviceSelectorComponentMod::AudioDeviceSelectorComponentMod (AudioDeviceManager& deviceManager_,
                                                            const int minInputChannels_,
                                                            const int maxInputChannels_,
                                                            const int minOutputChannels_,
                                                            const int maxOutputChannels_,
                                                            const bool showMidiInputOptions,
                                                            const bool showMidiOutputSelector,
                                                            const bool showChannelsAsStereoPairs_,
                                                            const bool hideAdvancedOptionsWithButton_)
    : AudioDeviceSelectorComponent(deviceManager_,
								   minInputChannels_,
								   maxInputChannels_,
								   minOutputChannels_,
								   maxOutputChannels_,
								   showMidiInputOptions,
								   showMidiOutputSelector,
								   showChannelsAsStereoPairs_,
								   hideAdvancedOptionsWithButton_)
{
}
