/*
 * AKDocView.m
 *
 * Created by Andy Lee on Thu Sep 02 2002.
 * Copyright (c) 2003, 2004 Andy Lee. All rights reserved.
 */

#import "AKDocView.h"

#import "AKTextView.h"
#import "AKPrefUtils.h"
#import "AKTextUtils.h"
#import "AKFileSection.h"
#import "AKDoc.h"
#import "AKDocLocator.h"


#pragma mark -
#pragma mark Forward declarations of private methods

@interface AKDocView (Private)

- (void)_updateDocDisplay;
- (void)_useWebViewToDisplayHTML:(NSData *)htmlData    fromFile:(NSString *)htmlFilePath   isPlainText:(BOOL)isPlainText;


@end


@implementation AKDocView


#pragma mark -
#pragma mark Init/awake/dealloc


-(void)_setup
{
    _headerFontName = @"Monaco";
    _headerFontSize = 10;
    _docMagnifier = 100;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]))
    {
        [self _setup];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [ self _setup ];
    }
    return self;
}

- (void)awakeFromNib
{


    [self setPolicyDelegate:_docListController];
    [self setUIDelegate:_docListController];
    
    // Update ivars with values from user prefs.
    [self applyPrefs];
    
}

- (void)dealloc
{
    [_docLocator release];
    [_headerFontName release];
    [_originalPreviousKeyView release];
    [_originalNextKeyView release];

    [super dealloc];
}


#pragma mark -
#pragma mark Getters and setters

- (void)setDocLocator:(AKDocLocator *)docLocator
{
    if ([docLocator isEqual:_docLocator])  // handles nil cases
    {
        return;
    }

    // Standard setter pattern.
    [docLocator retain];
    [_docLocator release];
    _docLocator = docLocator;

    // Update the display.
    [self _updateDocDisplay];
}


#pragma mark -
#pragma mark UI behavior

- (void)applyPrefs
{
    if (![[_docLocator docToDisplay] isPlainText])
    {
        NSInteger docMagnifierPref = [AKPrefUtils intValueForPref:AKDocMagnificationPrefName];

        if (_docMagnifier != docMagnifierPref)
        {
            _docMagnifier = docMagnifierPref;
            [self _updateDocDisplay];
        }
    }
    else
    {
        NSString *headerFontNamePref =
            [AKPrefUtils stringValueForPref:AKHeaderFontNamePrefName];
        NSInteger headerFontSizePref =
            [AKPrefUtils intValueForPref:AKHeaderFontSizePrefName];
        BOOL headerFontChanged = NO;

        if (![_headerFontName isEqualToString:headerFontNamePref])
        {
            headerFontChanged = YES;

            // Standard setter pattern.
            [headerFontNamePref retain];
            [_headerFontName release];
            _headerFontName = headerFontNamePref;
        }

        if (_headerFontSize != headerFontSizePref)
        {
            headerFontChanged = YES;

            _headerFontSize = headerFontSizePref;
        }

        if (headerFontChanged)
        {
            [self _updateDocDisplay];
        }
    }
}

- (NSView *)grabFocus
{
    [[self window] makeFirstResponder:self];
    return self;
}


#pragma mark -
#pragma mark NSView methods

// Return YES so we can be part of the key view loop.
- (BOOL)acceptsFirstResponder
{
    return YES;
}

@end



#pragma mark -
#pragma mark Private methods

@implementation AKDocView (Private)


- (void)_updateDocDisplay
{
    if (_docLocator == nil)
    {
        return;  // [agl] should I empty out the text view?
    }

    //  Figure out what text to display.
    AKDoc *docToDisplay = [_docLocator docToDisplay];
    AKFileSection *fileSection = [docToDisplay fileSection];
    NSString *htmlFilePath = [fileSection filePath];
    NSData *textData = [docToDisplay docTextData];


    [self _useWebViewToDisplayHTML:textData fromFile:htmlFilePath isPlainText:[docToDisplay isPlainText]];

}

- (void)_useWebViewToDisplayHTML:(NSData *)htmlData    fromFile:(NSString *)htmlFilePath   isPlainText:(BOOL)isPlainText
{

    // Apply the user's magnification preference.
    //float multiplier = ((float)_docMagnifier) / 100.0f;

    //[self setTextSizeMultiplier:multiplier];

    // Display the HTML in self.
    NSString *htmlString = @"";
    if (htmlData)
    {
        NSMutableData *zData = [NSMutableData dataWithData:htmlData];
        [zData setLength:([zData length] + 1)];
        htmlString = [NSString stringWithUTF8String:[zData bytes]];
        if (isPlainText)
        {
            // load custom JavaScript from local bundle
            NSURL *syntaxHighlightBaseURL = [[NSBundle mainBundle] resourceURL ];
            syntaxHighlightBaseURL = [syntaxHighlightBaseURL URLByAppendingPathComponent:@"syntaxhighlighter" isDirectory:YES ];
            
            NSURL* scriptBaseURL = [ syntaxHighlightBaseURL URLByAppendingPathComponent:@"scripts" isDirectory:YES ];
            NSURL* styleBaseURL = [ syntaxHighlightBaseURL URLByAppendingPathComponent:@"styles" isDirectory:YES ];
            
            NSString* coreJsURLString = [[ scriptBaseURL URLByAppendingPathComponent:@"shCore.js" isDirectory:NO ] absoluteString] ;
            NSString* brushJsURLString = [[ scriptBaseURL URLByAppendingPathComponent:@"shBrushObjectiveC.js" isDirectory:NO ] absoluteString] ;
            NSString* coreCssURLString = [[ styleBaseURL URLByAppendingPathComponent:@"shCore.css" isDirectory:NO ]absoluteString] ;
            NSString* brushCssURLString = [[ styleBaseURL URLByAppendingPathComponent:@"shThemeDefault.css" isDirectory:NO ] absoluteString] ;

            htmlString=[ NSString stringWithFormat:@"<html><head><script type=\"text/javascript\" src=\"%@\"></script><script type=\"text/javascript\" src=\"%@\"></script><link rel=\"StyleSheet\" type=\"text/css\" href=\"%@\"><link rel=\"StyleSheet\" type=\"text/css\" href=\"%@\"></head><body><pre class=\"brush: objc; gutter: false;\">%@</pre><script type=\"text/javascript\">SyntaxHighlighter.all()</script></body></html>",coreJsURLString, brushJsURLString, coreCssURLString,brushCssURLString , htmlString ];
        }
    }

    if (htmlFilePath)
    {
        [[self mainFrame]
            loadHTMLString:htmlString
            baseURL:[NSURL fileURLWithPath:htmlFilePath]];
    }
    else
    {
        [[self mainFrame]
            loadHTMLString:htmlString
            baseURL:nil];
    }
}

@end
