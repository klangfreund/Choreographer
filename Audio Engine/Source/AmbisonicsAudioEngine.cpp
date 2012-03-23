/*
 *  AmbisonicsAudioEngine.cpp
 *  AudioPlayer
 *
 *  Created by sam on 10 04 01.
 *  Copyright 2010 klangfreund.com. All rights reserved.
 *
 */

#include "AmbisonicsAudioEngine.h"

#define AUDIOTRANSPORT_BUFFER 2048 // (choose a value >1024)
#define SAMPLES_PER_BLOCK_FOR_BOUNCE_TO_DISK 512

// constructor
AmbisonicsAudioEngine::AmbisonicsAudioEngine ()
    : audioDeviceManager(),
      audioSourcePlayer(),
      audioTransportSource(),
      audioRegionMixer(),
	  audioSpeakerGainAndRouting(&audioRegionMixer)
{
	
	DEB("AmbisonicsAudioEngine: constructor called.");


// OPTION 1:
	// initialise settings file
//	ApplicationProperties::getInstance()
//	->setStorageParameters (T("Choreographer Ambisonics Audio Engine"),
//							T("settings"), String::empty, 1000,
//							PropertiesFile::storeAsXML);
//	
//	// load the previously selected settings for the audio device
//	XmlElement* const savedAudioState = ApplicationProperties::getInstance()->getUserSettings()
//	->getXmlValue (T("audioDeviceState"));
//	String err;
//    err = audioDeviceManager.initialise (256, 256, savedAudioState, true);
//	    // If you ever intend to remove this initialising block here in the constructor:
//	    // Keep in mind that you still have to call audioDeviceManager.initialise once. This
//	    // is the only occurence of this call in the whole Choreographer code.
//    delete savedAudioState;
//	if (err != T(""))
//	{
//		DEB(T("AmbisonicsAudioEngine: audioDeviceManager, initialisation error = ") + err);
//	}

// OPTION 2:
//	String err;
//	err = audioDeviceManager.initialise (256, 256, 0, true);
//	    // This doesn't work :(. This way, the initial AudioDeviceSetup (thats used internally by the
//	    // audioDeviceManager) is kind of messed up.
//	    // E.g. AudioDeviceSetup.outputChannels.toInteger() = 268435455 .
//	    // The playhead of the Choreographer doesn't move, when initialised this way.

	
	// Initialize the audioDeviceManager (and with it the audioDevice).
	// ---------------------------------
	String errorString;
	int numInputChannelsNeeded = 256;
	int numOutputChannelsNeeded = 256;
	bool selectDefaultDeviceOnFailure = true;
	errorString = audioDeviceManager.initialise (numInputChannelsNeeded, 
										 numOutputChannelsNeeded, 
										 0, 
										 selectDefaultDeviceOnFailure);
	if (errorString.isNotEmpty())
	{
		DEB("AmbisonicsAudioEngine, constructor: audioDeviceManager, initialisation error = " + errorString);
	}
	
	// TEMP: Select an audioDevice
	// ---------------------------
	
	// Get the audioDevices names
	StringArray deviceNames;
	deviceNames = getAvailableAudioDeviceNames();
	
	// Check if there are audioDevices available at all.
	if (deviceNames.size() == 0)
	{
		DEB("AmbisonicsAudioEngine, constructor: Can't find a Core Audio device.");
	}
	else
	{
		DEB("AmbisonicsAudioEngine, constructor: Available audio devices:");
		for (int i = 0; i < deviceNames.size(); ++i)
		{
			DEB(deviceNames[i]);
			// Output on the console on my system:
			//	Built-in Output
			//	Soundflower (2ch)
			//	Soundflower (16ch)
		}
		
		// Select an audioDevice
		String chosenOutputDevice = deviceNames[0];
        DEB("AmbisonicsAudioEngine, chosenOutputDevice = " + chosenOutputDevice);
		//String chosenOutputDevice = T("bla");		
		String errorString;
		errorString = setAudioDevice(chosenOutputDevice);
            // This will call enableNewRouting() and in there,
            //audioTransportSource.setSource (&audioRegionMixer,
            //								numberOfActiveOutputChannels,
            //								AUDIOTRANSPORT_BUFFER);
            // is called.
		if (errorString.isNotEmpty())
		{
			DEB("AmbisonicsAudioEngine, constructor: Wasn't able to set the audio device " + chosenOutputDevice);
			DEB(errorString);
		}		
	}
    	
	// Connect the objects together (for a better understanding, please take a 
    // look at the picture in the AmbisonicsAudioEngine Class Reference in the
    // documentation):
    // (Some lines above, the audioRegionMixer and the audioTransportSource
    // have already been connected.)
	audioSpeakerGainAndRouting.setSource (&audioTransportSource);
    audioSourcePlayer.setSource (&audioSpeakerGainAndRouting);
	audioDeviceManager.addAudioCallback (&audioSourcePlayer);
	
    
	// temp (test) ----------------------
	
//	addAepChannel(0, 1.0, false, false, false, -1.0, 0.0, 0.0);
//	addAepChannel(1, 1.0, false, false, false, 0.0, 1.0, 0.0);
//	addAepChannel(2, 1.0, false, false, false, 1.0, 0.0, 0.0);
//	addAepChannel(3, 1.0, false, false, false, 0.0, -1.0, 0.0);
//	setNewRouting(0, 0);
//	setNewRouting(1, 1);
//	setNewRouting(2, 2);
//	setNewRouting(3, 3);	
//	enableNewRouting();
//	activatePinkNoise(1, true);
	
	// end temp (test) ------------------
}
	
// destructor
AmbisonicsAudioEngine::~AmbisonicsAudioEngine ()
{	
	DEB("AmbisonicsAudioEngine: destructor called.");
	
	audioTransportSource.setSource (0, 1);
    audioSourcePlayer.setSource (0);
	audioDeviceManager.removeAudioCallback (&audioSourcePlayer);
	audioDeviceManager.closeAudioDevice();
	
	// close setting file
    //ApplicationProperties::getInstance()->closeFiles();
	
}
	
// This opens a dialogWindow to set up the audioDeviceManager
void AmbisonicsAudioEngine::showAudioSettingsWindow()
{
	//stop();
	    // I know, it would be nicer to be able to change it when the music is
	    // playing, but without this it will crash when lowering the number of
	    // active output ports.
	int currentPosition = getCurrentPosition();
	
	const bool showMidiInputOptions = false;
	const bool showMidiOutputSelector = false;
	const bool showChannelsAsStereoPairs = false;
	const bool hideAdvancedOptionsWithButton = false;
	AudioDeviceSelectorComponent audioDeviceSelectorComponent (audioDeviceManager,
													0, 0,
													0, 256,
													showMidiInputOptions, 
													showMidiOutputSelector, 
													showChannelsAsStereoPairs, 
													hideAdvancedOptionsWithButton);
	
	audioDeviceSelectorComponent.setSize (500, 350);
	
	DialogWindow::showModalDialog (T("Audio Settings"),
								   &audioDeviceSelectorComponent,
								   0,
								   Colours::lightgrey,
								   true);
	// Alternative. Not working yet.
//	// Open the dialog window.
//	// Done the same way as in DialogWindow::showModalDialog
//	DialogWindow dialogWindow (T("Audio Settings"),
//							   Colours::lightgrey,
//							   true,
//							   false);
//	dialogWindow.setContentComponent(&audioDeviceSelectorComponent, true, true);
//	dialogWindow.centreAroundComponent (0, dialogWindow.getWidth(), dialogWindow.getHeight());
//	dialogWindow.setResizable(false, false);
//	dialogWindow.setUsingNativeTitleBar(true);
//	dialogWindow.setAlwaysOnTop(true);
//	dialogWindow.runModalLoop();
//	dialogWindow.setContentComponent(0, false);
	
	// store this settings...
//	XmlElement* const audioState = audioDeviceManager.createStateXml();
//	
//	ApplicationProperties::getInstance()->getUserSettings()
//	->setValue (T("audioDeviceState"), audioState);
//	
//	delete audioState;
//	
//	ApplicationProperties::getInstance()->getUserSettings()->saveIfNeeded();

    audioDeviceManager.removeAudioCallback(&audioSourcePlayer);
    
	// Let others know about this new number of hardware output channels:
	audioSpeakerGainAndRouting.enableNewRouting(&audioDeviceManager);
    
    audioDeviceManager.addAudioCallback(&audioSourcePlayer);
	
	// audioTransportSource.setSource(..) puts the playhead to 0. This will 
	// put it back to the current position:
	setPosition(currentPosition);
	
	// Temp
//	addAepChannel(0, 1.0, false, false, false, -1.0, 0.0, 0.0);
//	addAepChannel(1, 1.0, false, false, false, 0.0, 1.0, 0.0);
//	addAepChannel(2, 1.0, false, false, false, 1.0, 0.0, 0.0);
//	addAepChannel(3, 1.0, false, false, false, 0.0, -1.0, 0.0);
//	setNewRouting(0, 0);
//	setNewRouting(1, 1);
//	setNewRouting(2, 2);
//	setNewRouting(3, 3);	
//	enableNewRouting();
	

}

StringArray AmbisonicsAudioEngine::getAvailableAudioDeviceNames()
{
	// Figure out if there is an audioIODeviceType called "CoreAudio".
	AudioIODeviceType* audioIODeviceTypeCoreAudio = 0;
	String coreAudioString("CoreAudio");
	for (int i = 0; i < audioDeviceManager.getAvailableDeviceTypes().size(); ++i)
	{
		if (audioDeviceManager.getAvailableDeviceTypes().getUnchecked(i)->getTypeName() == coreAudioString)
		{
			DEB("AmbisonicsAudioEngine::getAvailableCoreAudioDeviceNames(): Got the AudioIODeviceType for the CoreAudio.");
			audioIODeviceTypeCoreAudio = audioDeviceManager.getAvailableDeviceTypes().getUnchecked(i);			
		}
	}
	
	if (audioIODeviceTypeCoreAudio == 0)
	{
		DEB("AmbisonicsAudioEngine::getAvailableCoreAudioDeviceNames(): Couldn't find CoreAudio.");
		StringArray returnValue; // An empty StringArray.
		return returnValue;
	}
	else
	{
		audioIODeviceTypeCoreAudio->scanForDevices();
		StringArray deviceNames;
		bool wantInputNames = false;
		deviceNames = audioIODeviceTypeCoreAudio->getDeviceNames(wantInputNames);
		
		return deviceNames;
	}	
}

String AmbisonicsAudioEngine::setAudioDevice(const String& audioDeviceName)
{
    // Is the audioDeviceName the name of an actual audio Device?
    StringArray availableAudioDeviceNames = getAvailableAudioDeviceNames();

    String errorString; // The string that will be returned.
    
    if (availableAudioDeviceNames.contains(audioDeviceName))
    {
        
        // Stop the playback, if it was running.
        bool wasPlaying = audioTransportSource.isPlaying();
        int currentPosition;
        if (wasPlaying)
        {
            currentPosition = getCurrentPosition();
            stop();
        }

        {
            //const ScopedLock sl (lock);
            audioDeviceManager.removeAudioCallback(&audioSourcePlayer);
            
            // Choose the new output device for the audio output.
            AudioDeviceManager::AudioDeviceSetup audioDeviceSetup;
            audioDeviceSetup.outputDeviceName = audioDeviceName;
            bool treatAsChosenDevice = true;
            
            errorString = audioDeviceManager.setAudioDeviceSetup(audioDeviceSetup, treatAsChosenDevice);
            
            // On failure, initialise the audioDeviceManager again, such that there is at
            // least something available for audio output.
            if (errorString.isNotEmpty())
            {
                DEB("AmbisonicsAudioEngine::setAudioDevice: Because an initialisation error occured the default device will be tried to be initialised instead. Error message = " + errorString);
                
                String errorString2;
                //int numInputChannelsNeeded = 256;
                int numInputChannelsNeeded = 0;
                int numOutputChannelsNeeded = 256;
                const int savedState = 0;
                bool selectDefaultDeviceOnFailure = true;
                errorString2 = audioDeviceManager.initialise (numInputChannelsNeeded, 
                                                              numOutputChannelsNeeded, 
                                                              savedState, 
                                                              selectDefaultDeviceOnFailure);
                if (errorString2.isNotEmpty())
                {
                    DEB("AmbisonicsAudioEngine::setAudioDevice: It wasn't even possible to properly initialize the default device. Error = " + errorString2);
                }
            }
            
            // Let everybody know about this new output device:
            enableNewRouting();
                // audioDeviceManager.addAudioCallback(&audioSourcePlayer);
                // is called by the enableNewRouting()
        }
        
        if (wasPlaying)
        {
            setPosition(currentPosition);
            start();
        }
    }
    else
    {
        errorString = "There is no audio device available with the name " 
                      + audioDeviceName;
    }
	
	return errorString;
}

const String & AmbisonicsAudioEngine::getNameOfCurrentAudioDevice ()
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	return currentAudioIODevice->getName();
}

StringArray AmbisonicsAudioEngine::getOutputChannelNames()
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
    
    return currentAudioIODevice->getOutputChannelNames();
}

Array<double> AmbisonicsAudioEngine::getAvailableSampleRates()
{
    // The return value.
    Array<double>   availableSampleRates;
    
    AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
    for (int i=0; i < currentAudioIODevice->getNumSampleRates(); ++i)
    {
        availableSampleRates.add(currentAudioIODevice->getSampleRate(i));
    }
    
    return availableSampleRates;
}

String AmbisonicsAudioEngine::setSampleRate(const double& sampleRate)
{
    Array<double> availableSampleRates = getAvailableSampleRates();

    String errorString; // The string that will be returned.
    
    if (availableSampleRates.contains(sampleRate))
    {
        
        // Stop the playback, if it was running.
        bool wasPlaying = audioTransportSource.isPlaying();
        int currentPosition;
        if (wasPlaying)
        {
            currentPosition = getCurrentPosition();
            stop();
        }
        
        {
            //const ScopedLock sl (lock);
            audioDeviceManager.removeAudioCallback(&audioSourcePlayer);
            
            AudioDeviceManager::AudioDeviceSetup audioDeviceSetup;
            audioDeviceManager.getAudioDeviceSetup(audioDeviceSetup);
            audioDeviceSetup.sampleRate = sampleRate;
            
            bool treatAsChosenDevice = true;
            errorString = audioDeviceManager.setAudioDeviceSetup(audioDeviceSetup, treatAsChosenDevice);
            
            // On failure, initialise the audioDeviceManager again, such that there is at
            // least something available for audio output.
            if (errorString.isNotEmpty())
            {
                DEB("AmbisonicsAudioEngine::setSampleRate: Because an "
                    "initialisation error occured the default device is "
                    "tried to be initialised instead. Error message = " 
                    + errorString);
                
                String errorString2;
                //int numInputChannelsNeeded = 256;
                int numInputChannelsNeeded = 0;
                int numOutputChannelsNeeded = 256;
                const int savedState = 0;
                bool selectDefaultDeviceOnFailure = true;
                errorString2 = audioDeviceManager.initialise (numInputChannelsNeeded, 
                                                              numOutputChannelsNeeded, 
                                                              savedState, 
                                                              selectDefaultDeviceOnFailure);
                if (errorString2.isNotEmpty())
                {
                    DEB("AmbisonicsAudioEngine::setSampleRate: It wasn't even possible to properly initialize the default device. Error = " + errorString2);
                }
            }
            
            audioDeviceManager.addAudioCallback(&audioSourcePlayer);
        }
        
        if (wasPlaying)
        {
            setPosition(currentPosition);
            start();
        }
    }
    else
    {
        errorString = "The sample rate " + String(sampleRate) 
            + "is not supported by the current audio io device.";
    }
    
    return errorString;
}

double AmbisonicsAudioEngine::getCurrentSampleRate ()
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	return currentAudioIODevice->getCurrentSampleRate();
}

Array<int> AmbisonicsAudioEngine::getAvailableBufferSizes()
{
    // The return value.
    Array<int> availableBufferSizes;
    
    AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
    
    for (int i=0; i < currentAudioIODevice->getNumBufferSizesAvailable(); ++i)
    {
        availableBufferSizes.add(currentAudioIODevice->getBufferSizeSamples(i));
    }
    
    return availableBufferSizes;
}

int AmbisonicsAudioEngine::getDefaultBufferSize()
{
    AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
    return currentAudioIODevice->getDefaultBufferSize();
}

int AmbisonicsAudioEngine::getCurrentBufferSize()
{
    AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
    return currentAudioIODevice->getCurrentBufferSizeSamples();
}

String AmbisonicsAudioEngine::setBufferSize(const int & bufferSizeInSamples)
{
    Array<int> availableBufferSizes = getAvailableBufferSizes();
    
    String errorString; // The string that will be returned.
    
    if (availableBufferSizes.contains(bufferSizeInSamples))
    {
        
        // Stop the playback, if it was running.
        bool wasPlaying = audioTransportSource.isPlaying();
        int currentPosition;
        if (wasPlaying)
        {
            currentPosition = getCurrentPosition();
            stop();
        }
        
        {
            //const ScopedLock sl (lock);
            audioDeviceManager.removeAudioCallback(&audioSourcePlayer);
            
            AudioDeviceManager::AudioDeviceSetup audioDeviceSetup;
            audioDeviceManager.getAudioDeviceSetup(audioDeviceSetup);
            audioDeviceSetup.bufferSize = bufferSizeInSamples;
            
            bool treatAsChosenDevice = true;
            errorString = audioDeviceManager.setAudioDeviceSetup(audioDeviceSetup, treatAsChosenDevice);
            
            // On failure, initialise the audioDeviceManager again, such that there is at
            // least something available for audio output.
            if (errorString.isNotEmpty())
            {
                DEB("AmbisonicsAudioEngine::setBufferSize: Because an "
                    "initialisation error occured the default device is "
                    "tried to be initialised instead. Error message = " 
                    + errorString);
                
                String errorString2;
                //int numInputChannelsNeeded = 256;
                int numInputChannelsNeeded = 0;
                int numOutputChannelsNeeded = 256;
                const int savedState = 0;
                bool selectDefaultDeviceOnFailure = true;
                errorString2 = audioDeviceManager.initialise (numInputChannelsNeeded, 
                                                              numOutputChannelsNeeded, 
                                                              savedState, 
                                                              selectDefaultDeviceOnFailure);
                if (errorString2.isNotEmpty())
                {
                    DEB("AmbisonicsAudioEngine::setBufferSize: It wasn't even possible to properly initialize the default device. Error = " + errorString2);
                }
            }
            
            audioDeviceManager.addAudioCallback(&audioSourcePlayer);
        }
        
        if (wasPlaying)
        {
            setPosition(currentPosition);
            start();
        }
    }
    else
    {
        errorString = "The buffer size " + String(bufferSizeInSamples) 
        + "is not supported by the current audio io device.";
    }
    
    return errorString;
}

int AmbisonicsAudioEngine::getNumberOfHardwareOutputChannels()
{
	return audioSpeakerGainAndRouting.getNumberOfHardwareOutputChannels();
}

int AmbisonicsAudioEngine::getNumberOfAepChannels()
{
	return audioSpeakerGainAndRouting.getNumberOfAepChannels();
}

bool AmbisonicsAudioEngine::bounceToDisk(String absolutePathToAudioFile, 
										 int bitsPerSample, 
										 String description,
										 String originator,
										 String originatorRef,
										 String codingHistory,
										 int startSample,
										 int numberOfSamplesToRead)
{
	File fileToWriteTo(absolutePathToAudioFile);	
	// If this file exists, it needs to be deleted.
	// (Otherwise the bounced audio would be appended to the existing file.)
	fileToWriteTo.deleteFile();
	
	FileOutputStream* fileOutputStream = fileToWriteTo.createOutputStream();	
	
	if (getCurrentSampleRate() > 0 && fileOutputStream != 0)
	{	
        // Stop the playback.
        stop(); 
        
		// Remember the current playhead position. (It's assumed that the playback has been stopped).
		int currentPosition = getCurrentPosition();  
        
        // Remember if the loop in the arranger is enabled or not.
        bool arrangerLoopEnabled = audioTransportSource.getArrangerLoopStatus();
        // Disable the arranger loop
        audioTransportSource.disableArrangerLoop();
		
		// Disconnect from the audioDeviceManager
		audioDeviceManager.removeAudioCallback(&audioSourcePlayer);
		
		// Put the audioSpeakerGainAndRouting into bounce mode
		int virtualNumberOfActiveOutputChannels = audioSpeakerGainAndRouting.switchToBounceMode(true);
        
        // When set by the cancelBounceToDisk method during the upcoming
        // bounce process, it will be interrupted and the file will be deleted.
        stopBounceToDisk = false;
		
		bool success = false; // This will be returned if virtualNumberOfActiveOutputChannels = 0.
		
		// Since the numberOfActiveOutputChannels has changed, audioTransportSource needs to know this:
		if (virtualNumberOfActiveOutputChannels > 0)
		{
			// Generate the metadataValues for the wav file.
			Time dateAndTime;
			dateAndTime = Time::getCurrentTime();
			/*
			 source: http://www.audiobanter.com/showthread.php?t=18755
			 "TimeReference This field contains the timecode of the sequence. It is a
			 64-bit value which contains
			 the first sample count since midnight. The number of samples per second
			 depends
			 on the sample frequency which is defined in the field <nSamplesPerSec> from
			 the <format chunk>."
			 */
			int64 timeReferenceSamples = (dateAndTime.getHours()*3600
										  + dateAndTime.getMinutes() * 60
										  + dateAndTime.getSeconds()
										  + dateAndTime.getMilliseconds() * 0.001)*getCurrentSampleRate();
			const StringPairArray metadataValues = WavAudioFormat::createBWAVMetadata(description,
																					  originator, 
																					  originatorRef, 
																					  dateAndTime, 
																					  timeReferenceSamples, 
																					  codingHistory);
			
			// Set up the audioFormatWriter.
			WavAudioFormat wavAudioFormat;
			int qualityOptionIndex = 0; // no compression.
			ScopedPointer<AudioFormatWriter> audioFormatWriter; 
			audioFormatWriter = wavAudioFormat.createWriterFor(fileOutputStream, 
															   getCurrentSampleRate(), 
															   virtualNumberOfActiveOutputChannels, 
															   bitsPerSample, 
															   metadataValues, 
															   qualityOptionIndex);
            
            // Disable the buffering for the audio format readers...
			audioRegionMixer.enableBuffering(false);
            // ...as well as the buffering for the audio transport source.
            // And also set the virtualNumberOfActiveOutputChannels.
			audioTransportSource.setSource (&audioRegionMixer,
											virtualNumberOfActiveOutputChannels,
											0);
                // The 0 tells it to NOT use a BufferingAudioSource, e.g.
                // to not buffer.
			
			
			
			// Jump to the desired position and engage the playback
			audioSpeakerGainAndRouting.prepareToPlay(SAMPLES_PER_BLOCK_FOR_BOUNCE_TO_DISK, getCurrentSampleRate());
			setPosition(startSample);
			start();
            
            // The upcoming bounce process could have been written like this:
            //    success = audioFormatWriter->writeFromAudioSource(audioSpeakerGainAndRouting, 
            //                                                  numberOfSamplesToRead, 
            //                                                  SAMPLES_PER_BLOCK_FOR_BOUNCE_TO_DISK);
            // But this way it would not be possible to interrupt it.
            // So we do it like it is done inside the
            // audioFormatWriter->writeFromAudioSource method with the
            // additional check of stopBounceToDisk.
			
			//		bool AudioFormatWriter::writeFromAudioSource (AudioSource& source, int numSamplesToRead, const int samplesPerBlock)
            
			AudioSampleBuffer tempBuffer (virtualNumberOfActiveOutputChannels, 
                                          SAMPLES_PER_BLOCK_FOR_BOUNCE_TO_DISK);
            success = true;	
			while (numberOfSamplesToRead > 0)
			{
                const int numToDo = jmin (numberOfSamplesToRead, SAMPLES_PER_BLOCK_FOR_BOUNCE_TO_DISK);
                
                AudioSourceChannelInfo info;
                info.buffer = &tempBuffer;
                info.startSample = 0;
                info.numSamples = numToDo;
                info.clearActiveBufferRegion();
                
                audioSpeakerGainAndRouting.getNextAudioBlock (info);
                
                if (! audioFormatWriter->writeFromAudioSampleBuffer (tempBuffer, 0, numToDo) || stopBounceToDisk)
                {
                    success = false;
                    break;
                }
                
                numberOfSamplesToRead -= numToDo;
            }	
			
			stop();
            
            // Delete the audio file if the bouncing process has been
            // canceled by the user.
            if (stopBounceToDisk)
            {
                fileToWriteTo.deleteFile();
            }
        }
		
		// Put the audioSpeakerGainAndRouting into regular mode
		int numberOfActiveOutputChannels = audioSpeakerGainAndRouting.switchToBounceMode(false);
		
        // Reenable the buffering.
        audioRegionMixer.enableBuffering(true);
		audioTransportSource.setSource (&audioRegionMixer,
										numberOfActiveOutputChannels,
										AUDIOTRANSPORT_BUFFER); // tells it to buffer this many samples ahead (choose a value >1024)
		
		// Reconnect with the audioDeviceManager
		audioDeviceManager.addAudioCallback(&audioSourcePlayer);
		
		// Reset the playhead position
		setPosition(currentPosition);
        
        // Reenable the arranger loop if it was engaged before
        if (arrangerLoopEnabled)
        {
            audioTransportSource.reenableArrangerLoop();
        }
		
		DEB("AmbisonicsAudioEngine::bounceToDisc: success = " + String(success));
		
		return success;
	}
	else
	{
		return false;
	}

}

void AmbisonicsAudioEngine::cancelBounceToDisk()
{
    stopBounceToDisk = true;
}

bool AmbisonicsAudioEngine::addAepChannel(int aepChannel, double gain, 
										  bool solo, bool mute,
										  bool activatePinkNoise, double x, 
										  double y, double z)
{
	return audioSpeakerGainAndRouting.addAepChannel(aepChannel, gain, solo, 
													mute, activatePinkNoise,
													x, y, z);
}

bool AmbisonicsAudioEngine::removeAepChannel(int aepChannel)
{
	return audioSpeakerGainAndRouting.removeAepChannel(aepChannel);
}

bool AmbisonicsAudioEngine::setSpeakerPosition(int aepChannel, double x, 
											   double y, double z)
{
	return audioSpeakerGainAndRouting.setSpeakerPosition(aepChannel, x, 
														 y, z);
}

bool AmbisonicsAudioEngine::setGain(int aepChannel, double gain)
{
	return audioSpeakerGainAndRouting.setGain(aepChannel, gain);
}

bool AmbisonicsAudioEngine::setSolo(int aepChannel, bool enable)
{
	return audioSpeakerGainAndRouting.setSolo(aepChannel, enable);
}

bool AmbisonicsAudioEngine::setMute(int aepChannel, bool enable)
{
	return audioSpeakerGainAndRouting.setMute(aepChannel, enable);
}

bool AmbisonicsAudioEngine::activatePinkNoise(int aepChannel, bool enable)
{
	return audioSpeakerGainAndRouting.activatePinkNoise(aepChannel, enable);
}

void AmbisonicsAudioEngine::setAmplitudeOfPinkNoiseGenerator(const double amplitude)
{
	audioSpeakerGainAndRouting.setAmplitudeOfPinkNoiseGenerator(amplitude);
}

bool AmbisonicsAudioEngine::enableMeasurement(int aepChannel, bool enable)
{
	return audioSpeakerGainAndRouting.enableMeasurement(aepChannel, enable);
}

bool AmbisonicsAudioEngine::resetMeasuredPeakValue(int aepChannel)
{
	return audioSpeakerGainAndRouting.resetMeasuredPeakValue(aepChannel);
}

float AmbisonicsAudioEngine::getMeasuredDecayingValue(int aepChannel)
{
	return audioSpeakerGainAndRouting.getMeasuredDecayingValue(aepChannel);
}

float AmbisonicsAudioEngine::getMeasuredPeakValue(int aepChannel)
{
	return audioSpeakerGainAndRouting.getMeasuredPeakValue(aepChannel);
}

void AmbisonicsAudioEngine::setNewRouting(int aepChannel, int hardwareOutputChannel)
{
	audioSpeakerGainAndRouting.setNewRouting(aepChannel, hardwareOutputChannel);
}

void AmbisonicsAudioEngine::removeAllRoutings()
{
	audioSpeakerGainAndRouting.removeAllRoutings();
}

void AmbisonicsAudioEngine::enableNewRouting()
{
	// Since we're quite likely going to change the number of channels
	// in the audio callback, we have to stop these callbacks.
	bool wasPlaying = audioTransportSource.isPlaying();
	int currentPosition;
	if (wasPlaying)
	{
		currentPosition = getCurrentPosition();
		stop();
	}
	
	{
		// This section is scope locked.
		const ScopedLock sl (lock);
		audioDeviceManager.removeAudioCallback(&audioSourcePlayer);
        
        int numberOfActiveOutputChannels = audioSpeakerGainAndRouting.enableNewRouting(&audioDeviceManager);
        
        // Since the numberOfActiveOutputChannels has changed, audioTransportSource needs to know this:
        if (numberOfActiveOutputChannels != 0)
        {
            audioTransportSource.setSource (&audioRegionMixer,
                                            numberOfActiveOutputChannels,
                                            AUDIOTRANSPORT_BUFFER); // tells it to buffer this many samples ahead (choose a value >1024)
            
            audioDeviceManager.addAudioCallback(&audioSourcePlayer);
            
            if (wasPlaying)
            {
                
                setPosition(currentPosition);
                start();
            }
        }
        else
        {
            DEB("AmbisonicsAudioEngine::enableNewRouting: BIG PROBLEM: "
                  "The number of active output channels is 0. Therefore "
                  "the setSource() of the audio transport source can't be"
                  "called");
            
            // In the case of 0 channels,
            //		audioTransportSource.setSource (&audioRegionMixer,
            //										0,
            //										AUDIOTRANSPORT_BUFFER);
            // would lead to a crash because the audio buffer can't handle it.
            // With &audioRegionMixer = 0 the audioTransport doesn't create
            // an audio buffer at all.
            //		audioTransportSource.setSource (0,
            //										0,
            //										AUDIOTRANSPORT_BUFFER); // tells it to buffer this many samples ahead (choose a value >1024)
        }
	}
	

}

void AmbisonicsAudioEngine::removeAllRoutingsAndAllAepChannels()
{
	stop();
	audioTransportSource.setSource (0,0,AUDIOTRANSPORT_BUFFER);
	audioSpeakerGainAndRouting.removeAllRoutingsAndAllAepChannels();
}

int AmbisonicsAudioEngine::getCurrentPosition()
{
	AudioIODevice* currentAudioIODevice = audioDeviceManager.getCurrentAudioDevice();
	double sampleRateOfTheAudioDevice = currentAudioIODevice->getCurrentSampleRate();
	return (int) (audioTransportSource.getCurrentPosition() * sampleRateOfTheAudioDevice);
}

void AmbisonicsAudioEngine::setPosition(int positionInSamples)
{
    // DEB("AmbisonicsAudioEngine::setPosition called.")
    
	double sampleRateOfTheAudioDevice = getCurrentSampleRate();
	double positionInSeconds = (double)positionInSamples/sampleRateOfTheAudioDevice;
	audioTransportSource.setPosition(positionInSeconds);
    
    // The setReadPosition of a region is only called from the audioRegionMixers
    // getNextAudioBlock iff the region is under the play head.
    // But especially if the playhead is relocated back in time, a region
    // should be aware of it since all of a sudden it has to deliver sound again.
    // This is particular crucial for an AudioFormatReader.
    audioRegionMixer.setNextReadPositionOnAllRegions(getCurrentPosition());
}

void AmbisonicsAudioEngine::start()
{
    audioRegionMixer.prepareAllRegionsToPlay();

	audioTransportSource.start();
}
	
void AmbisonicsAudioEngine::stop()
{
	if (audioTransportSource.isPlaying())
	{
		audioTransportSource.stop();
	}
	else
	{
		// jump back to the start, if audio wasn't playing before
		audioTransportSource.setPosition(0);
	}
}

bool AmbisonicsAudioEngine::enableArrangerLoop(double loopStartInSeconds, 
                                               double loopEndInSeconds, 
                                               double loopFadeTimeInSeconds)
{
	return audioTransportSource.enableArrangerLoop(loopStartInSeconds, 
												   loopEndInSeconds,
												   loopFadeTimeInSeconds);
}

void AmbisonicsAudioEngine::disableArrangerLoop()
{
	audioTransportSource.disableArrangerLoop();
}

double AmbisonicsAudioEngine::getCpuUsage ()
{
	return audioDeviceManager.getCpuUsage();
}

bool AmbisonicsAudioEngine::addAudioRegion (const int regionID,
										    const int startPosition,
										    const int duration,
										    const int offsetInFile,
										    String absolutePathToAudioFile)
{
	int endPosition = startPosition + duration;
	int startPositionOfAudioFileInTimeline = startPosition - offsetInFile;
	
	double sampleRateOfTheAudioDevice = (audioDeviceManager.getCurrentAudioDevice())->getCurrentSampleRate();
	
	return audioRegionMixer.addRegion(regionID, startPosition, endPosition,
		        startPositionOfAudioFileInTimeline, absolutePathToAudioFile,
				sampleRateOfTheAudioDevice);
}

bool AmbisonicsAudioEngine::modifyAudioRegion(const int regionID, 
											  const int newStartPosition, 
											  const int newDuration,
											  const int newOffsetInFile)
{
	int newEndPosition = newStartPosition + newDuration;
	int newStartPositionOfAudioFileInTimeline = newStartPosition - newOffsetInFile;
	
	return audioRegionMixer.modifyRegion(regionID, newStartPosition, newEndPosition,
										 newStartPositionOfAudioFileInTimeline);
}

bool AmbisonicsAudioEngine::removeRegion (const int regionID)
{
	return audioRegionMixer.removeRegion(regionID);
}

void AmbisonicsAudioEngine::removeAllRegions ()
{
	audioRegionMixer.removeAllRegions();
}

bool AmbisonicsAudioEngine::setGainEnvelopeForRegion (const int regionID,
													  Array<void*> gainEnvelope)
{
	return audioRegionMixer.setGainEnvelopeForRegion(regionID, gainEnvelope);
}

void AmbisonicsAudioEngine::setMasterGain(const float newGain)
{
	audioTransportSource.setGain(newGain);
}

void AmbisonicsAudioEngine::enableDopplerEffect (bool enable)
{
    audioRegionMixer.enableDopplerEffect(enable);
}

void AmbisonicsAudioEngine::setAEPOrder (const double order)
{
	AudioSourceAmbipanning::setOrder(order);
}

void AmbisonicsAudioEngine::setAEPDistanceModeTo0 ()
{
	AudioSourceAmbipanning::setDistanceModeTo0();
}

void AmbisonicsAudioEngine::setAEPDistanceModeTo1 (double centerRadius, 
                                                   double centerExponent,
                                                   double centerAttenuationInDB,
                                                   double dBFalloffPerUnit)
{
	AudioSourceAmbipanning::setDistanceModeTo1(centerRadius, 
											   centerExponent,
											   centerAttenuationInDB,
											   dBFalloffPerUnit);
}

void AmbisonicsAudioEngine::setAEPDistanceModeTo2 (double centerRadius, 
                                                   double centerExponent,
                                                   double centerAttenuationInDB,
                                                   double outsideCenterExponent)
{
	AudioSourceAmbipanning::setDistanceModeTo2(centerRadius, 
											   centerExponent,
											   centerAttenuationInDB,
											   outsideCenterExponent);
}

bool AmbisonicsAudioEngine::setSpacialEnvelopeForRegion (const int& regionID,
													     const Array<SpacialEnvelopePoint>& spacialEnvelope)
{
	return audioRegionMixer.setSpacialEnvelopeForRegion(regionID, spacialEnvelope);
}
