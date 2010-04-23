#import "CPAxisLabel.h"
#import "CPConstrainedPosition.h"
#import "CPDefinitions.h"
#import "CPExceptions.h"
#import "CPLineStyle.h"
#import "CPPlotArea.h"
#import "CPPlotRange.h"
#import "CPPlotSpace.h"
#import "CPUtilities.h"
#import "CPXYAxis.h"
#import "CPXYPlotSpace.h"
#import "CPXYGridLines.h"

///	@cond
@interface CPXYAxis ()

@property (readwrite, retain) CPConstrainedPosition *constrainedPosition;

-(void)drawTicksInContext:(CGContextRef)theContext atLocations:(NSSet *)locations withLength:(CGFloat)length isMajor:(BOOL)major; 

-(void)orthogonalCoordinateViewLowerBound:(CGFloat *)lower upperBound:(CGFloat *)upper;
-(CGPoint)viewPointForOrthogonalCoordinateDecimal:(NSDecimal)orthogonalCoord axisCoordinateDecimal:(NSDecimal)coordinateDecimalNumber;
-(void)updateConstraints;

@end
///	@endcond

#pragma mark -

/**	@brief A 2-dimensional cartesian (X-Y) axis class.
 **/
@implementation CPXYAxis

/**	@property orthogonalCoordinateDecimal
 *	@brief The data coordinate value where the axis crosses the orthogonal axis.
 **/
@synthesize orthogonalCoordinateDecimal;

/**	@property constraints
 *	@brief The constraints used when positioning relative to the plot area.
 *  For axes fixed in the plot coordinate system, this is ignored.
 **/
@synthesize constraints;

/**	@property positionedRelativeToPlotArea
 *	@brief True if the axis is constrained to move relative to the plot area.
 *  If false, the axes is fixed relative to the plot coordinates, and moves
 *  whenever the plot space ranges change.
 *  The default value is NO, meaning the axis is positioned in plot coordinates.
 **/
@synthesize positionedRelativeToPlotArea;

@synthesize constrainedPosition;

#pragma mark -
#pragma mark Init/Dealloc

-(id)initWithFrame:(CGRect)newFrame
{
	if ( self = [super initWithFrame:newFrame] ) {
    	CPConstraints newConstraints = {CPConstraintNone, CPConstraintNone};
        orthogonalCoordinateDecimal = [[NSDecimalNumber zero] decimalValue];
        positionedRelativeToPlotArea = NO;
        self.constraints = newConstraints;
		self.tickDirection = CPSignNone;
	}
	return self;
}

-(void)dealloc 
{
    [constrainedPosition release];
    [super dealloc];
}

#pragma mark -
#pragma mark Coordinate Transforms

-(void)orthogonalCoordinateViewLowerBound:(CGFloat *)lower upperBound:(CGFloat *)upper 
{
	NSDecimal zero = CPDecimalFromInteger(0);
    CPCoordinate orthogonalCoordinate = (self.coordinate == CPCoordinateX ? CPCoordinateY : CPCoordinateX);
    CPXYPlotSpace *xyPlotSpace = (CPXYPlotSpace *)self.plotSpace;
    CPPlotRange *orthogonalRange = [xyPlotSpace plotRangeForCoordinate:orthogonalCoordinate];
    CGPoint lowerBoundPoint = [self viewPointForOrthogonalCoordinateDecimal:orthogonalRange.location axisCoordinateDecimal:zero];
    CGPoint upperBoundPoint = [self viewPointForOrthogonalCoordinateDecimal:orthogonalRange.end axisCoordinateDecimal:zero];
    *lower = (self.coordinate == CPCoordinateX ? lowerBoundPoint.y : lowerBoundPoint.x);
    *upper = (self.coordinate == CPCoordinateX ? upperBoundPoint.y : upperBoundPoint.x);
}

-(CGPoint)viewPointForOrthogonalCoordinateDecimal:(NSDecimal)orthogonalCoord axisCoordinateDecimal:(NSDecimal)coordinateDecimalNumber
{
    CPCoordinate orthogonalCoordinate = (self.coordinate == CPCoordinateX ? CPCoordinateY : CPCoordinateX);
    NSDecimal plotPoint[2];
    plotPoint[self.coordinate] = coordinateDecimalNumber;
    plotPoint[orthogonalCoordinate] = orthogonalCoord;
    CGPoint point = [self convertPoint:[self.plotSpace plotAreaViewPointForPlotPoint:plotPoint] fromLayer:self.plotArea];
    return point;
}

-(CGPoint)viewPointForCoordinateDecimalNumber:(NSDecimal)coordinateDecimalNumber
{    
    CGPoint point = [self viewPointForOrthogonalCoordinateDecimal:self.orthogonalCoordinateDecimal axisCoordinateDecimal:coordinateDecimalNumber];
    
    if ( self.positionedRelativeToPlotArea ) {
        if ( self.constrainedPosition ) {
        	CGFloat lb, ub;
            [self orthogonalCoordinateViewLowerBound:&lb upperBound:&ub];
        	constrainedPosition.lowerBound = lb;
            constrainedPosition.upperBound = ub;
            CGFloat position = constrainedPosition.position;
            if ( self.coordinate == CPCoordinateX ) {
                point.y = position;
            }
            else {
                point.x = position;
            }
        }
        else {
			[NSException raise:CPException format:@"Plot area relative positioning requires a CPConstrainedPosition"];
        }
    }
    
    return point;
}

#pragma mark -
#pragma mark Drawing

-(void)drawTicksInContext:(CGContextRef)theContext atLocations:(NSSet *)locations withLength:(CGFloat)length isMajor:(BOOL)major
{
	CPLineStyle *lineStyle = (major ? self.majorTickLineStyle : self.minorTickLineStyle);
    if ( !lineStyle ) return;
    
	[lineStyle setLineStyleInContext:theContext];
	CGContextBeginPath(theContext);

    for ( NSDecimalNumber *tickLocation in locations ) {
        // Tick end points
        CGPoint baseViewPoint = [self viewPointForCoordinateDecimalNumber:[tickLocation decimalValue]];
		CGPoint startViewPoint = baseViewPoint;
        CGPoint endViewPoint = baseViewPoint;
		
		CGFloat startFactor, endFactor;
		switch ( self.tickDirection ) {
			case CPSignPositive:
				startFactor = 0;
				endFactor = 1;
				break;
			case CPSignNegative:
				startFactor = 0;
				endFactor = -1;
				break;
			case CPSignNone:
				startFactor = -0.5;
				endFactor = 0.5;
				break;
			default:
				NSLog(@"Invalid sign in [CPXYAxis drawTicksInContext:]");
		}
		
        switch ( self.coordinate ) {
			case CPCoordinateX:
				startViewPoint.y += length * startFactor;
				endViewPoint.y += length * endFactor;
				break;
			case CPCoordinateY:
				startViewPoint.x += length * startFactor;
				endViewPoint.x += length * endFactor;
				break;
			default:
				NSLog(@"Invalid coordinate in [CPXYAxis drawTicksInContext:]");
		}
        
		startViewPoint = CPAlignPointToUserSpace(theContext, startViewPoint);
		endViewPoint = CPAlignPointToUserSpace(theContext, endViewPoint);
		
        // Add tick line
        CGContextMoveToPoint(theContext, startViewPoint.x, startViewPoint.y);
        CGContextAddLineToPoint(theContext, endViewPoint.x, endViewPoint.y);
    }    
	// Stroke tick line
	CGContextStrokePath(theContext);
}

-(void)renderAsVectorInContext:(CGContextRef)theContext
{
	[super renderAsVectorInContext:theContext];
	
	[self relabel];
	
    // Ticks
    [self drawTicksInContext:theContext atLocations:self.minorTickLocations withLength:self.minorTickLength isMajor:NO];
    [self drawTicksInContext:theContext atLocations:self.majorTickLocations withLength:self.majorTickLength isMajor:YES];
    
    // Axis Line
	if ( self.axisLineStyle ) {
		CPPlotRange *range = [[self.plotSpace plotRangeForCoordinate:self.coordinate] copy];
        if (self.visibleRange) {
            [range intersectionPlotRange:self.visibleRange];
        }
		CGPoint startViewPoint = CPAlignPointToUserSpace(theContext, [self viewPointForCoordinateDecimalNumber:range.location]);
		CGPoint endViewPoint = CPAlignPointToUserSpace(theContext, [self viewPointForCoordinateDecimalNumber:range.end]);
		[self.axisLineStyle setLineStyleInContext:theContext];
		CGContextBeginPath(theContext);
		CGContextMoveToPoint(theContext, startViewPoint.x, startViewPoint.y);
		CGContextAddLineToPoint(theContext, endViewPoint.x, endViewPoint.y);
		CGContextStrokePath(theContext);
        [range release];
	}
}

#pragma mark -
#pragma mark Description

-(NSString *)description
{
    CPPlotRange *range = [self.plotSpace plotRangeForCoordinate:self.coordinate];
	CGPoint startViewPoint = [self viewPointForCoordinateDecimalNumber:range.location];
    CGPoint endViewPoint = [self viewPointForCoordinateDecimalNumber:range.end];
	
	return [NSString stringWithFormat:@"<%@ with range: %@ viewCoordinates: %@ to %@>",
			[super description],
			range,
			CPStringFromPoint(startViewPoint),
			CPStringFromPoint(endViewPoint)];
};

#pragma mark -
#pragma mark Titles

// Center title in the plot range by default
-(NSDecimal)defaultTitleLocation
{
	CPPlotRange *axisRange = [self.plotSpace plotRangeForCoordinate:self.coordinate];
	
	return CPDecimalDivide(CPDecimalAdd(axisRange.location, axisRange.end), CPDecimalFromDouble(2.0));
}

#pragma mark -
#pragma mark Constraints

-(void)updateConstraints
{
    if ( self.plotSpace ) {
        CGPoint axisPoint = [self viewPointForOrthogonalCoordinateDecimal:self.orthogonalCoordinateDecimal axisCoordinateDecimal:CPDecimalFromInteger(0)];
        CGFloat position = (self.coordinate == CPCoordinateX ? axisPoint.y : axisPoint.x);
        
        CGFloat lb, ub;
        [self orthogonalCoordinateViewLowerBound:&lb upperBound:&ub];
        
		CPConstrainedPosition *cp = [[CPConstrainedPosition alloc] initWithPosition:position lowerBound:lb upperBound:ub];
		cp.constraints = self.constraints;
        self.constrainedPosition = cp;
        [cp release];         
    }
    else {
        self.constrainedPosition = nil;
    }
}

#pragma mark -
#pragma mark Accessors

-(void)setConstraints:(CPConstraints)newConstraints
{
    constraints = newConstraints;
	[self updateConstraints];
}

-(void)setOrthogonalCoordinateDecimal:(NSDecimal)newCoord 
{
    orthogonalCoordinateDecimal = newCoord;
    [self updateConstraints];
}

-(Class)gridLineClass
{
	return [CPXYGridLines class];
}

@end
