//
//  SpatDIF.m
//  Choreographer
//
//  Created by Philippe Kocher on 14.03.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import "SpatDIF.h"

@implementation SpatDIF

- (id)initWithXmlDoc:(NSXMLDocument *)xmlDoc_
{
    self = [super init];
    if (self)
    {
        xmlDoc = [xmlDoc_ retain];
    }
    
    return self;
}


- (void)dealloc
{
    [xmlDoc release];
    [super dealloc];
}


- (BOOL)validate
{
    if(![[[xmlDoc rootElement] name] isEqualToString:@"spatdif"])
        return NO;
    
    return YES;
}

- (int)countTrajectoryDefinitions
{
	NSXMLElement *rootNode = [xmlDoc rootElement];
	NSError *err;
    
    NSArray *array = [rootNode nodesForXPath:@".//meta/trajectory" error:&err];

    
    if(array)   return [array count];
    else        return 0;
}


@end
