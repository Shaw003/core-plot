#import <Foundation/Foundation.h>
#import "CPLayer.h"

@class CPAxisLabelGroup;
@class CPAxisSet;
@class CPPlotGroup;
@class CPLineStyle;
@class CPFill;

@interface CPPlotArea : CPLayer {
@private
	CPLayer *minorGridLineGroup;
	CPLayer *majorGridLineGroup;
	CPAxisSet *axisSet;
	CPPlotGroup *plotGroup;
	CPAxisLabelGroup *axisLabelGroup;
	CPAxisLabelGroup *axisTitleGroup;
	CPFill *fill;
}

@property (nonatomic, readwrite, retain) CPLayer *minorGridLineGroup;
@property (nonatomic, readwrite, retain) CPLayer *majorGridLineGroup;
@property (nonatomic, readwrite, retain) CPAxisSet *axisSet;
@property (nonatomic, readwrite, retain) CPPlotGroup *plotGroup;
@property (nonatomic, readwrite, retain) CPAxisLabelGroup *axisLabelGroup;
@property (nonatomic, readwrite, retain) CPAxisLabelGroup *axisTitleGroup;
@property (nonatomic, readwrite, copy) CPLineStyle *borderLineStyle;
@property (nonatomic, readwrite, copy) CPFill *fill;

@end
