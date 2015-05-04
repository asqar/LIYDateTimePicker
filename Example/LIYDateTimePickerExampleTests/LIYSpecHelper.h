#import <Foundation/Foundation.h>

@class LIYMockEventStore;
@class LIYDateTimePickerViewController;

@interface LIYSpecHelper : NSObject

+ (void)rotateDeviceToOrientation:(UIInterfaceOrientation)orientation;
+ (void)tickRunLoop;
+ (void)tickRunLoopForSeconds:(NSTimeInterval)seconds;
+ (LIYMockEventStore *)mockEventStore;
+ (LIYMockEventStore *)mockEventStoreWithAllDayEventAt:(NSDate *)date;
+ (NSString *)dayOfMonthFromDate:(NSDate *)date;
+ (LIYDateTimePickerViewController *)visiblePickerViewController;
+ (LIYDateTimePickerViewController *)pickerViewControllerWithAllDayEventAtDate:(NSDate *)date;

@end