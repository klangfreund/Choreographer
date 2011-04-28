//
//  ContainerView.m
//  Choreographer
//
//  Created by Philippe Kocher on 10.05.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "ContainerView.h"


@implementation ContainerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
	NSRect r = [self bounds];

	int i;
	float colorComponent;

	int height = r.size.height;
	for(i=rect.origin.y;i<=rect.origin.y + rect.size.height;i++)
	{
		if(i < height - 30)
			colorComponent = 0.55;
		else 
			colorComponent = 0.55 + 0.008 * (i + 30 - height);
		[[NSColor colorWithCalibratedRed: colorComponent green: colorComponent blue: colorComponent alpha: 1.0] set];
			
		r.origin.y = i;
		r.size.height = 1;
		NSRectFill(r);
	}
}
@end
