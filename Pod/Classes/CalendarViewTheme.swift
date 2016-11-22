//
//  CalendarViewTheme.swift
//  CalendarView
//
//  Created by Wito Chandra on 06/04/16.
//  Modified by Bungkhus.
//  Copyright © 2016 Wito Chandra. All rights reserved.
//

import UIKit

public class CalendarViewTheme: NSObject {
    
    public static let instance = CalendarViewTheme()
    
    public var bgColorForMonthContainer = UIColor.whiteColor()
    public var bgColorForDaysOfWeekContainer = UIColor.whiteColor()
    public var bgColorForCurrentMonth = UIColor.whiteColor()
    public var bgColorForOtherMonth = UIColor.darkGrayColor()
    public var colorForDivider = UIColor.lightGrayColor()
    public var colorForSelectedDate = UIColor.blackColor()
    public var colorForDatesRange = UIColor(white: 0, alpha: 0.1)
    public var textColorForTitle = UIColor.blackColor()
    public var textColorForDayOfWeek = UIColor.blackColor()
    public var textColorForHoliday = UIColor.redColor()
    public var textColorForHolidayDisabled = UIColor(red:1.00, green:0.60, blue:0.60, alpha:1.0)
    public var textColorForNormalDay = UIColor.blackColor()
    public var textColorForDisabledDay = UIColor.lightGrayColor()
    public var textColorForSelectedDay = UIColor.whiteColor()
}
