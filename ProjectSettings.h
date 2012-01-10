//
//  ProjectSettings.h
//  Choreographer
//
//  Created by Philippe Kocher on 10.01.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface ProjectSettings : NSObject
{
    NSMutableDictionary *theDictionary;
}

- (id)initWithDefaults;

@end
