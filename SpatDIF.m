//
//  SpatDIF.m
//  Choreographer
//
//  Created by Philippe Kocher on 14.03.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import "SpatDIF.h"
#import "TrajectoryItem.h"
#import "BreakpointTrajectory.h"

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
    [trajectoryNames release];
    [trajectories release];
    [super dealloc];
}


- (BOOL)parse
{
    if(![[[xmlDoc rootElement] name] isEqualToString:@"spatdif"])
        return NO;
    
    // meta - trajectory
	NSXMLElement *rootNode = [xmlDoc rootElement];
    NSArray *points;
    NSString *position;
    NSUInteger time;
	NSError *err;
    
    NSArray *trajectoryNodes = [rootNode nodesForXPath:@".//meta/trajectory" error:&err];
    if(err) return NO;

    NSMutableArray *tempTrajectoryNames = [[[NSMutableArray alloc] init] autorelease];
    NSMutableArray *tempTrajectories = [[[NSMutableArray alloc] init] autorelease];
    BreakpointTrajectory *trajectory;
    
    for(NSXMLElement *trajectoryNode in trajectoryNodes)
    {
        [tempTrajectoryNames addObject:[[trajectoryNode attributeForName:@"id"] stringValue]];
        
        trajectory = [[[BreakpointTrajectory alloc] init] autorelease];
        [tempTrajectories addObject:trajectory];

        points = [trajectoryNode nodesForXPath:@"point" error:&err];
        if(err) return NO;

        for(NSXMLElement *point in points)
        {
            time = [[[[point nodesForXPath:@"time" error:&err] objectAtIndex:0] objectValue] floatValue] * 1000;
            position = [[[point nodesForXPath:@"position" error:&err] objectAtIndex:0] stringValue];
            if(err) return NO;

            [trajectory addBreakpointAtPosition:[SpatialPosition positionFromString:position] time:time];
        }
        
        // adaptive
        if([[[trajectory positionBreakpointArray] objectAtIndex:0] time] != 0)
        {
            Breakpoint *bp = [[[Breakpoint alloc] init] autorelease];
            [bp setPosition:[SpatialPosition positionWithX:0 Y:0 Z:0]];
            [bp setTime:0];
            [bp setBreakpointType:breakpointTypeAdaptiveInitial];
            
            [[trajectory positionBreakpointArray] addBreakpoint:bp];
        }

    }
        
    trajectoryNames = [[NSArray arrayWithArray:tempTrajectoryNames] retain];
    trajectories = [[NSArray arrayWithArray:tempTrajectories] retain];
    
    return YES;
}

- (NSArray *)trajectoryNames { return trajectoryNames; }
- (NSArray *)trajectories { return trajectories; }

- (void)addTrajectories:(NSArray *)trajectories_
{
    trajectories = [trajectories_ retain];
}

- (BOOL)writeXmlToURL:(NSURL *)url
{
    // root
    NSXMLNode *spatdifVersionAttribute = [NSXMLNode attributeWithName:@"version" stringValue:@"0.3"];
    NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"spatdif" children:nil attributes:[NSArray arrayWithObject:spatdifVersionAttribute]];

    // meta
    NSXMLElement *meta = (NSXMLElement *)[NSXMLNode elementWithName:@"meta"];
    [root addChild:meta];
    
    // trajectory
    [meta addChild:[NSXMLNode elementWithName:@"extensions" stringValue:@"trajectory"]];

    NSXMLNode *trajectoryId;
    NSXMLElement *trajectoryNode;
    NSXMLElement *point;
    NSXMLElement *position;
    NSXMLElement *time;

    
    for(id trajectory in trajectories)
    {
        trajectoryId = [NSXMLNode attributeWithName:@"id" stringValue:[trajectory valueForKeyPath:@"name"]];
        trajectoryNode = (NSXMLElement *)[NSXMLNode elementWithName:@"trajectory" children:nil attributes:[NSArray arrayWithObject:trajectoryId]];
        [meta addChild:trajectoryNode];
                
        for(Breakpoint *bp in [[trajectory valueForKeyPath:@"item"] positionBreakpoints])
        {
            if([bp breakpointType] == breakpointTypeAdaptiveInitial) continue;
            
            position = [NSXMLNode elementWithName:@"position" stringValue:[[bp position] stringValue]];
            time = [NSXMLNode elementWithName:@"time" stringValue:[NSString stringWithFormat:@"%f",[bp time] * 0.001]]; // time in seconds
            point = [NSXMLNode elementWithName:@"point" children:[NSArray arrayWithObjects:time,position, nil] attributes:nil];
            
            [trajectoryNode addChild:point];
        }
    }
    
    // write to file
    xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
    [xmlDoc setVersion:@"1.0"];
    [xmlDoc setCharacterEncoding:@"UTF-8"];
    [xmlDoc setStandalone:YES];
    NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    if (![xmlData writeToURL:url atomically:YES])
    {
        NSLog(@"Could not write document out...");
        return NO;
    }
    
    return YES;
}


@end
