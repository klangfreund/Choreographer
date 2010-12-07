how to get and install juce
---------------------------

A1. Get Juce via
     git clone --depth 1 git://juce.git.sourceforge.net/gitroot/juce/juce

A2. Open ./Builds/MacOSX/Juce.xcodeproj .

A3. Maybe:
    Open Project "Juce" Info window and check the
    "Build Active Architecture Only"

A4. Build it, once for the "Debug" configuration, once for the
    "Release" configuration.


how to modify the Choreographer code to work with your freshly installed juce
-----------------------------------------------------------------------------

B1. Open the Choreographer.xcodeproj .

B2. Edit the file "Audio Engine/JuceLibraryCode/JuceHeader.h" and change
    the path on line 17 appropriately:
      #include "/Users/sam/data/res/projects_dev/juce100923/juce/juce.h"

B3. Open the tree in the Overview pane: "Frameworks/Juce Frameworks".
    Remove the "Juce.xcodeproj" and replace it with
     ./Builds/MacOSX/Juce.xcodeproj
    (via drag and drop from the finder).

B4. In this Overview pane, drag and drop the 
    "Frameworks/Juce Frameworks/Juce.xcodeproj/libjuce.a" to
    "Targets/Choreographer/Link Binary With Libraries"

You're ready to build :)