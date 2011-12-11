//
//  GainSlider.h
//  Choreographer
//
//  Created by Philippe Kocher on 15.08.11.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GainSlider : NSSlider {
    
}

-(void)propagateValue:(id)value forBinding:(NSString*)binding;

@end
