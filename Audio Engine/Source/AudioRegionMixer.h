/*
 *  AudioRegionMixer.h
 *  AudioPlayer
 *
 *  Created by sam (sg@klangfreund.com) on 100425.
 *  Copyright 2010. All rights reserved.
 *
 */

#ifndef __AUDIOREGIONMIXER_HEADER__
#define __AUDIOREGIONMIXER_HEADER__

#include "../JuceLibraryCode/JuceHeader.h"
#include "AudioSourceAmbipanning.h"

//==============================================================================
/**
 An AudioRegion represents a section of an audio file, that should be played at
 a certain position in time. In the GUI, the AudioRegions are represented by
 blocks in the timeline.
 AudioRegion is used exclusively by the AudioRegionMixer.
 */
struct JUCE_API  AudioRegion
{
    /** The ID of this region. 
     Must be unique, such that the region can be modified or be deleted later.
     */
    int regionID;
	
    /** The position in time, where this region starts.
     Specified in samples.
     */
    int startPosition;
	
    /** The position in time, where this region ends.
     To be precise, this specifies the first sample after the end of the region. 
     Specified in samples.
     */
    int endPosition;
	
	/** The position in the audio file, where this region starts. Specified in samples. */
    //int startSampleInTheAudioFile;
	
    /** Specifies, at which sample to start in the audio file.
     The start sample in the audio file = startPosition - startPositionOfAudioFileInTimeline.
     It should be obvious that this value must be smaller or equal than startPosition.
     This "strange representation" (e.g. instead of the startSampleInTheAudioFile)
     has been chosen because it makes the calculation in the AudioRegionMixer easy. */
    int startPositionOfAudioFileInTimeline;  // must be <= startPosition !!!
	
    /** This is a pointer to the positionable audio source that is actually delivering
     the streams of audio.
     At this stage, gain- and spacialautomation has already been applied, by the way. */
    AudioSourceAmbipanning* audioSourceAmbipanning;	
};


//==============================================================================
/**
 A PositionableAudioSource that keeps track of AudioRegion s and mixes them
 together.

 There are no such things as tracks or busses here.
 */
class JUCE_API  AudioRegionMixer  : public PositionableAudioSource
{
public:
    //==============================================================================
    /** Constructor: Creates an AudioRegionMixer.
	 */
    AudioRegionMixer();
	
    /** Destructor. */
    ~AudioRegionMixer();
    
    /**
     Adds an audio region to the pool of audio regions.

     @param regionID				The unique ID of the region. See
     						AudioRegion::regionID .
     @param startPosition			The position in time, where this region starts.
						See AudioRegion::startPosition .
     @param endPosition				The position in time, where this region ends.
						See AudioRegion::endPosition .
     @param startPositionOfAudioFileInTimeline	Specifies, at which sample to start 
     						in the audio file. See 
						AudioRegion::startPositionOfAudioFileInTimeline .
     @param absolutePathToAudioFile		Needed by the AudioFormatReader that
                                                is created in this method.
     @param sampleRateOfTheAudioDevice		The samplerate is needed for the
     						sample rate conversion in the
						AudioSourceGainEnvelope.
						(not yet implemented)

     @return					The success of the operation.
     */
    bool addRegion (const int& regionID, 
                    const int& startPosition, 
                    const int& endPosition,
                    const int& startPositionOfAudioFileInTimeline, 
                    const String& absolutePathToAudioFile,
                    const double& sampleRateOfTheAudioDevice);

    /**
     Modifies an audio region to the pool of audio regions.

     @param regionID				The unique ID of the region. See
     						AudioRegion::regionID .
     @param newStartPosition			The new position in time, where this region starts.
						See AudioRegion::startPosition .
     @param newEndPosition			The new position in time, where this region ends.
						See AudioRegion::endPosition .
     @param startPositionOfAudioFileInTimeline	Specifies, at which new position (in samples) to start 
     						in the audio file. See 
						AudioRegion::startPositionOfAudioFileInTimeline .

     @return					The success of the operation.
     */	
    bool modifyRegion (const int& regionID, 
                       const int& newStartPosition, 
                       const int& newEndPosition,
                       const int& newStartPositionOfAudioFileInTimeline);
	
    /**
     Removes an audio region from the pool of audio regions.

     @param regionID				The unique ID of the region. See
     						AudioRegion::regionID .

     @return					The success of the operation.
     */	
    bool removeRegion (const int regionID);

    /**
     Removes all audio regions.
     */	
    void removeAllRegions ();
	
    /**
     Attaches a gain envelope to a region.
    
     The gain envelope contains points - pairs of time (in samples) and volume values.
     These define the change of volume over time. Linear interpolation is used.
     For all time instances before the first point, the volume value of the first point is
     used. For all time instances after the last point, the volume value of the last point
     is used.
    
     @param regionID		The ID of the region.
     @param gainEnvelope        A gainEnvelope is a void*-Array. The void 
                                pointers need to be typecasted to pointers to
                                AudioEnvelopePoint
    				( (AudioEnvelopePoint*)gainEnvelope[pointNumber_StartingAtZero] ).
    				The gainEnvelope and all involved AudioEnvelopePoints
    				will be deleted in
    				AudioSourceGainEnvelope::setGainEnvelope 
    				or in AudioSourceGainEnvelope::~AudioSourceGainEnvelope,
    				so you don't have to care about.
    
     @return		 	The success of this operation.
     */
    bool setGainEnvelopeForRegion (const int regionID, Array<void*> gainEnvelope);

    /**
     Sets the positions of the connected speakers.
    
     @param positionOfSpeaker	The positionOfSpeaker is a void*-Array. The void 
                                pointers need to be typecasted to pointers to
                                SpeakerPosition
    				( (SpeakerPosition*)positionOfSpeaker[speakerNumber_StartingAtZero] ).
     */
    void setSpeakerPositions (const Array<SpeakerPosition>& positionOfSpeaker);
    
    /**
     Attaches a spacial envelope to a region. 
    
     The spacial envelope contains points. Such a point holds four values: The position
     (the time information, measured in samples) and the x, y and z coordinates.
     The spacial envelope defines the change of the coordinates over time. Linear interpolation
     of the resulting gain values for the speakers for this source is used in between points.
     For all time instances before the first point, the coordinates of the first point is
     used. For all time instances after the last point, the coordinates of the last point
     is used.
    
     @param regionID		The ID of the region.
     @param spacialEnvelope     A spacialEnvelope is a void*-Array. The void 
                                pointers need to be typecasted to pointers to
                                SpacialEnvelopePoint
    				( (SpacialEnvelopePoint*)spacialEnvelope[pointNumber_StartingAtZero] ).
    				The spacialEnvelope and all involved
    				SpacialEnvelopePoints will be deleted in the 
    				AudioSourceAmbipanning::setSpacialEnvelope
    				or in the 
    				AudioSourceAmbipanning::~AudioSourceAmbipanning,
    				so you don't have to care about.
    
     @return		 	The success of this operation.
     */
    bool setSpacialEnvelopeForRegion (const int& regionID, Array<SpacialEnvelopePoint> spacialEnvelope);
    
    /**
     Enables or disables the buffering for each individual audio region.
     
     For realtime operation, buffering
     should always be engaged at some point. For non-realtime operation
     (e.g. bounce to disk), buffering should be disabled.
     */
    void enableBuffering(bool enable);
    
    /**
     Returns true, if buffering is enabled and false otherwise.
     */
    bool getBufferingState();
    
    /**
     Enables or disables the doppler effect.
     
     It is disabled by default.
     */  
    void enableDopplerEffect (bool enable);
    
    /**
     Enables or disables the distance based filtering.
     
     Disabled by default.
     */  
    void enableDistanceBasedFiltering(bool enable);
	

    //==============================================================================
    /** Implements the AudioSource method. */
    void prepareToPlay (int samplesPerBlockExpected, double sampleRate);
    
    /** Will call the prepareToPlay method on all regions.
     
     This needs to be done every time the playback starts again in the sequencer.
     Without doing it, the BufferingAudioSources don't work exact (e.g. they
     skip samples at the beginning and/or the end of the region they belong to).
     */
    void prepareAllRegionsToPlay ();
	
    /** Implements the AudioSource method. */
    void releaseResources();
	
    /** Implements the AudioSource method. */
    void getNextAudioBlock (const AudioSourceChannelInfo& info);
	

    //==============================================================================
    /** Implements the PositionableAudioSource method. */
    void setNextReadPosition (int64 newPosition);
    
    /** Sets the read position on all regions.
     
    The setReadPosition of a region is only called from the
    getNextAudioBlock iff the region is under the play head.
    But especially if the playhead is relocated back in time, a region
    should be aware of it since all of a sudden it has to deliver sound again.
    This is particular crucial for an AudioFormatReader.
     */
    void setNextReadPositionOnAllRegions (int64 newPosition);
	
    /** Implements the PositionableAudioSource method. */
    int64 getNextReadPosition() const;
	
    /** Implements the PositionableAudioSource method. */
    int64 getTotalLength() const;
	
    /** Implements the PositionableAudioSource method. */
    bool isLooping() const;
	
    //==============================================================================
    juce_UseDebuggingNewOperator
	
private:
    //==============================================================================
	
    /** If the region with the specified regionID is found, it returns
      * true and writes the position in the regions array to index. */
    bool findRegion(const int regionID, int& index);
	
    /** The array that keeps track of the AudioRegions. The void pointers
     have to be typecasted to AudioRegion.

     (Exemplar was the 'inputs' in MixerAudioSource.) */	
    Array<void*> regions;
    
    /** Specifies the next play position - the start of the next audio block.
     Set by the AudioRegionMixer::setNextReadPosition.
     */
    int volatile nextPlayPosition;

    /** Equals the endPosition (in samples) of the last audio region. */
    int totalLength;

    AudioSampleBuffer tempBuffer; ///< Used in AudioRegionMixer::getNextAudioBlock.
    int samplesPerBlockExpected;  ///< Used in AudioRegionMixer::addRegion
				  ///< (for prepareToPlay(..) of the new region).
    				  ///< Set in AudioRegionMixer::prepareToPlay.
    double sampleRate; ///< Used in AudioRegionMixer::addRegion 
                       ///< (for prepareToPlay(..) of the new region).
                       ///< Set in AudioRegionMixer::prepareToPlay.
    
    /** Tells, if an audioSourceBuffer object is used in front of the audio file
     reader of each audio region. */
    bool bufferingEnabled;

    /** Used in AudioRegionMixer::setGainEnvelopeForRegion. */
    AudioEnvelopePointComparator audioEnvelopePointComparator; 

    /** Used in AudioRegionMixer::setSpacialEnvelopeForRegion. */
    SpacialEnvelopePointComparator spacialEnvelopePointComparator; 
    
    /** Used for scope locking in AudioRegionMixer::setSpeakerPositions. */
    CriticalSection lock;
	
	JUCE_LEAK_DETECTOR (AudioRegionMixer);
};


#endif   // __AUDIOREGIONMIXER_HEADER__
