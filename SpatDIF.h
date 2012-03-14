//
//  SpatDIF.h
//  Choreographer
//
//  Created by Philippe Kocher on 14.03.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrajectoryItem.h"

@interface SpatDIF : NSObject
{
    NSXMLDocument *xmlDoc;
}

- (id)initWithXmlDoc:(NSXMLDocument *)xmlDoc_;
- (BOOL)validate;

- (int)countTrajectoryDefinitions;

//+ (void)trajectory:(TrajectoryItem *)trajectoryItem toSpatDifXML:(NSXMLDocument *)xmlDoc;
@end
