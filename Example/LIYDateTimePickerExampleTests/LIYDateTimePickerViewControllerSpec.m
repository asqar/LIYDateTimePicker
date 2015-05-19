#import "Kiwi.h"
#import "LIYDateTimePickerViewController.h"
#import "NSDate+LIYUtilities.h"
#import "LIYSpecHelper.h"
#import "UIView+LIYSpecAdditions.h"
#import "LIYCalendarService.h"
#import <CupertinoYankee/NSDate+CupertinoYankee.h>

SPEC_BEGIN(LIYDateTimePickerViewControllerSpec)
    describe(@"LIYDateTimePickerViewController", ^{

        beforeEach(^{
            [[LIYCalendarService sharedInstance] reset];
        });

        it(@"allows setting 5 minute scroll interval", ^{
            [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 12:00 PM"];

            LIYDateTimePickerViewController *pickerViewController = [LIYSpecHelper visiblePickerViewController];
            pickerViewController.scrollIntervalMinutes = 5;
            NSDate *nextIncrementDate = [NSDate liy_dateFromString:@"5/3/15, 12:05 PM"];
            [pickerViewController scrollToTime:nextIncrementDate];

            [[pickerViewController.selectedDate should] equal:nextIncrementDate];
        });

        it(@"defaults to 15 minute scroll interval", ^{
            LIYDateTimePickerViewController *pickerViewController = [LIYDateTimePickerViewController new];
            [[theValue(pickerViewController.scrollIntervalMinutes) should] equal:theValue(15)];
        });

        it(@"allows hiding of the relative time picker", ^{
            LIYDateTimePickerViewController *pickerViewController = [LIYSpecHelper visiblePickerViewController];
            pickerViewController.showRelativeTimePicker = NO;
            [[[pickerViewController.view liy_specsFindLabelWithText:@"15m"] should] beNil];
        });

        context(@"at noon", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 12:00 PM"];
                pickerViewController = [LIYSpecHelper visiblePickerViewController];
            });

            it(@"allows scrolling to the beginning of the day", ^{
                NSDate *beginningOfDayDate = [NSDate liy_dateFromString:@"5/3/15, 12:00 AM"];

                [pickerViewController scrollToTime:beginningOfDayDate];
                [[expectFutureValue(pickerViewController.selectedDate) shouldEventually] equal:beginningOfDayDate];
            });

            it(@"allows scrolling to the end of the day", ^{
                NSDate *endOfDayDate = [NSDate liy_dateFromString:@"5/3/15, 11:45 PM"];
                [pickerViewController scrollToTime:endOfDayDate];
                [[expectFutureValue(pickerViewController.selectedDate) shouldEventually] equal:endOfDayDate];
            });

            it(@"allows scrolling to the end of the day when the device is landscape", ^{
                [LIYSpecHelper rotateDeviceToOrientation:UIInterfaceOrientationLandscapeLeft];
                NSDate *endOfDayDate = [NSDate liy_dateFromString:@"5/3/15, 11:45 PM"];
                [pickerViewController scrollToTime:endOfDayDate];
                [[expectFutureValue(pickerViewController.selectedDate) shouldEventually] equal:endOfDayDate];
            });

            it(@"keeps the same date when rotating the device", ^{
                NSDate *endOfDayDate = [NSDate liy_dateFromString:@"5/3/15, 11:45 PM"];
                [pickerViewController scrollToTime:endOfDayDate];
                [LIYSpecHelper tickRunLoop];

                [LIYSpecHelper rotateDeviceToOrientation:UIInterfaceOrientationLandscapeLeft];
                [LIYSpecHelper rotateDeviceToOrientation:UIInterfaceOrientationPortrait];

                [[expectFutureValue(pickerViewController.selectedDate) shouldEventually] equal:endOfDayDate];
            });
        });

        context(@"at 1:05pm", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:05 PM"];
                pickerViewController = [LIYDateTimePickerViewController timePickerForDate:[NSDate date] delegate:nil];
            });

            it(@"sets 1:15pm as the selected date", ^{
                [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/3/15, 1:15 PM"]];
            });

            it(@"displays 1:15pm as the selected time", ^{
                [[[pickerViewController.view liy_specsFindLabelWithText:@"1:15 PM"] shouldNot] beNil];
            });
        });

        context(@"when scrolling to the end of the day", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:05 PM"];
                pickerViewController = [LIYSpecHelper visiblePickerViewController];
                [pickerViewController.collectionView setContentOffset:CGPointMake(0, 10000) animated:NO];
            });

            it(@"doesn't continue advancing the selected date if you keep scrolling at the end of the day", ^{
                [pickerViewController.collectionView setContentOffset:CGPointMake(0, 10001) animated:NO];
                [[pickerViewController.selectedDate should] equal:[NSDate liy_dateFromString:@"5/4/15, 12:00 AM"]];
            });

            it(@"stays on the same day in the day picker", ^{
                [[[pickerViewController.dayPicker.currentDate beginningOfDay] should] equal:[NSDate liy_dateFromString:@"5/3/15, 12:00 AM"]];
            });
        });

        context(@"when switching from a day without an all day event to a day with an all day event and then going to midnight", ^{
            __block LIYDateTimePickerViewController *pickerViewController;
            __block NSDate *tomorrowDate;

            beforeEach(^{
                pickerViewController = [LIYSpecHelper visiblePickerViewController];

                // create picker with all day event for tomorrow
                NSTimeInterval oneDay = 60 * 60 * 24;
                tomorrowDate = [NSDate dateWithTimeIntervalSinceNow:oneDay];
                pickerViewController = [LIYSpecHelper pickerViewControllerWithAllDayEventAtDate:tomorrowDate];

                // go to tomorrow
                pickerViewController.selectedDate = tomorrowDate;
                [pickerViewController reloadEvents];

                [LIYSpecHelper tickRunLoop];

                // scroll to 12am
                [pickerViewController scrollToTime:[tomorrowDate beginningOfDay]];
            });

            it(@"has the correct insets", ^{
                UIEdgeInsets insets = pickerViewController.collectionView.contentInset;
                CGFloat topInsetOnIPhone6 = 121.5; // TODO: make this work on other devices
                [[theValue(insets.top) should] equal:topInsetOnIPhone6 withDelta:0.1];
            });

            it(@"is at midnight", ^{
                [[pickerViewController.selectedDate should] equal:[tomorrowDate beginningOfDay]];
            });
        });

        context(@"when showing an event on the calendar", ^{
            __block LIYDateTimePickerViewController *pickerViewController;

            beforeEach(^{
                [LIYSpecHelper stubCurrentDateAs:@"5/3/15, 1:05 PM"];

                // create picker with event for today
                NSDate *eventStartDate = [NSDate liy_dateFromString:@"5/3/15, 2:00 PM"];
                NSDate *eventEndDate = [NSDate liy_dateFromString:@"5/3/15, 3:00 PM"];
                pickerViewController = [LIYSpecHelper pickerViewControllerWithEventAtDate:eventStartDate endDate:eventEndDate];
                pickerViewController.showEventTimes = YES;

                [LIYSpecHelper tickRunLoop];
            });

            it(@"has the event duration", ^{
                [[[pickerViewController.view liy_specsFindLabelWithText:@"2 PM - 3 PM (1 hour)"] shouldNot] beNil];
            });
        });

    });
SPEC_END