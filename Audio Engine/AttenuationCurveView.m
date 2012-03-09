//
//  AttenuationCurveView.m
//  Choreographer
//
//  Created by Philippe Kocher on 17.01.12.
//  Copyright 2012 Zurich University of the Arts. All rights reserved.
//

#import "AttenuationCurveView.h"

@implementation AttenuationCurveView

@synthesize enabled;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // settings
    id document = [[NSApplication sharedApplication] valueForKeyPath:@"delegate.currentProjectDocument"];
    float centreZoneSize  = [[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationCentreZoneSize"] floatValue];
    float centreDB  = [[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationCentreDB"] floatValue];
	float centreGain = pow(10, 0.05 * centreDB);
    float centreExponent  = [[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationCentreExponent"] floatValue];
    int mode  = [[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationMode"] intValue];
    float dbFalloff  = [[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationDbFalloff"] floatValue];
    float attenuationExponent  = [[document valueForKeyPath:@"projectSettings.distanceBasedAttenuationExponent"] floatValue];

	// colors
    float alpha = enabled ? 1 : 0.5;
	NSColor *backgroundColor	= [NSColor colorWithCalibratedRed: 0.1 green: 0.1 blue: 0.1 alpha: alpha];
	NSColor *lineColor			= [NSColor colorWithCalibratedRed: 0.7 green: 0.7 blue: 0.9 alpha: alpha];
	NSColor *centreZoneColor    = [NSColor colorWithCalibratedRed: 0.25 green: 0.25 blue: 0.45 alpha: alpha];
    NSColor *curveColor			= [NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: alpha];

	
    // background
    NSRect r = [self bounds];
    [backgroundColor set];
    NSRectFill(r);
    
    // centre zone
    r.size.width -= (1 - centreZoneSize) * r.size.width;
    [centreZoneColor set];
    NSRectFill(r);
    
    // lines (ie units)
    r = [self bounds];
    [lineColor set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
    int i;
    for(i=0;i<11;i++)
    {
        [NSBezierPath strokeLineFromPoint:NSMakePoint(i * r.size.width * 0.1, 0) toPoint:NSMakePoint(i * r.size.width * 0.1, r.size.height)];
    }
    
    // curve inside centre zone
    r.size.height -= 1;
    float x,y;
    NSBezierPath *curve = [NSBezierPath bezierPath];
    [curveColor set];
	[[NSGraphicsContext currentContext] setShouldAntialias:NO];
    [curve moveToPoint:NSMakePoint(0,0)];
    for(i=0;i<centreZoneSize * 1000;i++)
    {
        x = i * r.size.width * 0.001;
        y = (pow(i * 0.001 / centreZoneSize, centreExponent) * (1.0 - centreGain) + centreGain) * r.size.height;
        [curve lineToPoint:NSMakePoint(x,y)];
    }
    
    // curve outside centre zone
    if(mode==0)
    {
        for(;i<1000;i++)
        {
            x = i * r.size.width * 0.001;
            y = pow(10, (i * 0.001 - centreZoneSize) * 10. * dbFalloff * 0.05) * r.size.height;
            [curve lineToPoint:NSMakePoint(x,y)];
        }
    }
    else
    {
        for(;i<1000;i++)
        {
            x = i * r.size.width * 0.001;
            y = pow(i * 0.01 + (1 - 10. * centreZoneSize), -attenuationExponent) * r.size.height;
            [curve lineToPoint:NSMakePoint(x,y)];
        }
    }
    [curve stroke];

}

@end
