//
//  ToolbarController.m
//  Choreographer
//
//  Created by Philippe Kocher on 14.05.08.
//  Copyright 2011 Zurich University of the Arts. All rights reserved.
//

#import "ToolbarController.h"

// label, palettelabel, toolTip, action, and menu can all be NULL, depending upon what you want the item to do
static void addToolbarItem(NSMutableDictionary *theDict,NSString *identifier,NSString *label,NSString *paletteLabel,NSString *toolTip,id target,SEL settingSelector, id itemContent,SEL action, NSMenu * menu)
{
    NSMenuItem *mItem;
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:). Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
    // we set it up here. Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
    // so we create a dummy NSMenuItem that has our real menu as a submenu.
    if (menu!=NULL)
    {
		// we actually need an NSMenuItem here, so we construct one
		mItem=[[[NSMenuItem alloc] init] autorelease];
		[mItem setSubmenu: menu];
		[mItem setTitle: [menu title]];
		[item setMenuFormRepresentation:mItem];
    }
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
}

#pragma mark -
#pragma mark -
// -----------------------------------------------------------

@implementation ToolbarController

- (void)awakeFromNib
{	
	// create the dictionary to hold all of our "master" NSToolbarItems.
	toolbarItems=[[NSMutableDictionary dictionary] retain];
	// populate the dictionary
	addToolbarItem(toolbarItems,@"Counter",@"Counter",@"Counter",NULL,self,@selector(setView:),counterView,NULL,NULL);
	addToolbarItem(toolbarItems,@"Loop Counter",@"Loop Counter",@"Loop Counter",NULL,self,@selector(setView:),loopCounterView,NULL,NULL);
	addToolbarItem(toolbarItems,@"Transport",@"Transport",@"Transport",NULL,self,@selector(setView:),transportView,NULL,NULL);
	addToolbarItem(toolbarItems,@"Master Volume",@"Master Volume",@"Master Volume",NULL,self,@selector(setView:),masterVolumeSlider,NULL,NULL);

	addToolbarItem(toolbarItems,@"Duplicate",@"Duplicate",@"Duplicate",NULL,self,@selector(setView:),duplicateButton,NULL,NULL);
	addToolbarItem(toolbarItems,@"Repeat",@"Repeat",@"Repeat",NULL,self,@selector(setView:),repeatButton,NULL,NULL);
	addToolbarItem(toolbarItems,@"Delete",@"Delete",@"Delete",NULL,self,@selector(setView:),deleteAudioButton,NULL,NULL);
	addToolbarItem(toolbarItems,@"Split",@"Split",@"Split",NULL,self,@selector(setView:),splitButton,NULL,NULL);
	addToolbarItem(toolbarItems,@"Trim",@"Trim",@"Trim",NULL,self,@selector(setView:),trimButton,NULL,NULL);

	
	// create the toolbar
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"choreographerToolbar"] autorelease];

	// the toolbar wants to know who is going to handle processing of NSToolbarItems for it. This controller will.
	[toolbar setDelegate:self];

	// toolbar settings
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    [toolbar setAutosavesConfiguration:YES];

	// install the toolbar.
	[window setToolbar:toolbar];
}

- (void)dealloc
{
	NSLog(@"ToolbarController: dealloc");
    [toolbarItems release];
    [super dealloc];
}

- (IBAction)duplicate { [arrangerView performSelector:@selector(duplicate:) withObject:self]; }
- (IBAction)repeat { [arrangerView performSelector:@selector(repeat:) withObject:self]; }
- (IBAction)deleteAudio { [arrangerView performSelector:@selector(delete:) withObject:self]; }
- (IBAction)split { [arrangerView performSelector:@selector(split:) withObject:self]; }
- (IBAction)trim { [arrangerView performSelector:@selector(trim:) withObject:self]; }


#pragma mark -
#pragma mark toolbar delegate methods
// -----------------------------------------------------------

// This method is required of NSToolbar delegates.  It takes an identifier, and returns the matching NSToolbarItem.
// It also takes a parameter telling whether this toolbar item is going into an actual toolbar, or whether it's
// going to be displayed in a customization palette.
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	// We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    NSToolbarItem *item=[toolbarItems objectForKey:itemIdentifier];
   
    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=NULL)
    {
		[newItem setView:[item view]];
    }
    else
    {
		[newItem setImage:[item image]];
	}
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=NULL)
    {
		[newItem setMinSize:[[item view] bounds].size];
		[newItem setMaxSize:[[item view] bounds].size];
    }

    return newItem;
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.    
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:@"Transport",@"Counter",@"Loop Counter",NSToolbarFlexibleSpaceItemIdentifier,@"Master Volume",nil];
}

// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar. Any not listed here will not be available in the customization palette.
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	NSMutableArray *tempArray = [NSMutableArray arrayWithObjects: NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, nil];
	[tempArray addObjectsFromArray:[toolbarItems allKeys]];
	return tempArray;
	
//    return [NSArray arrayWithObjects:@"Transport",@"Counter", NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier,nil];
}



@end
