//
//  Path.m
//  Choreographer
//
//  Created by Philippe Kocher on 23.03.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "Path.h"


@implementation Path

+ (NSString *)path:(NSURL *)path relativeTo:(NSURL *)base
{
	NSArray *pathComponents = [path pathComponents];
	NSArray *baseComponents = [base pathComponents];
	NSMutableString *relativePath = [[NSMutableString new] autorelease];
	int i = 0, j;
	
	while([[pathComponents objectAtIndex:i] isEqualToString:[baseComponents objectAtIndex:i]])
	{
		i++;
	}
	
	for(j=i;j<[baseComponents count] - 1;j++)
	{
		[relativePath appendString:@"../"];
	}

	for(;i<[pathComponents count] - 1;i++)
	{
		[relativePath appendFormat:@"%@/",[pathComponents objectAtIndex:i]];
	}

	[relativePath appendString:[pathComponents lastObject]];

	return [relativePath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
}

@end
