//
//  SpatDIF.h
//  Choreographer
//
//  Created by Philippe Kocher on 14.03.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpatDIF : NSObject
{
    NSXMLDocument *xmlDoc;
    
    NSArray *trajectoryNames;
    NSArray *trajectories;
}

- (id)initWithXmlDoc:(NSXMLDocument *)xmlDoc_;
- (BOOL)parse;

- (NSArray *)trajectoryNames;
- (NSArray *)trajectories;

- (void)addTrajectories:(NSArray *)trajectories_;
- (BOOL)writeXmlToURL:(NSURL *)url;

@end
