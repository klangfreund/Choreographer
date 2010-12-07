//
//  ProjectSettings.h
//  Choreographer
//
//  Created by Philippe Kocher on 26.10.10.
//  Copyright 2010 Zurich University of the Arts. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProjectSettings : NSManagedObject
{
	id projectSettingsDictionary;
}

// serialisation
- (void)archiveData;
- (void)unarchiveData;

@end

@interface ProjectSettingsDictionary : NSObject
{
	NSMutableDictionary *dictionary;
}

- (id)initWithDefaults;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

@end
