//
//  CalendarView.swift
//  CalendarView
//
//  Created by Wito Chandra on 05/04/16.
//  Modified by Bungkhus.
//  Copyright © 2016 Wito Chandra. All rights reserved.
//

import UIKit

public class CalendarView: UIView {
    
    @IBOutlet private var viewBackground: UIView!
    @IBOutlet private var viewTitleContainer: UIView!
    @IBOutlet private var viewDaysOfWeekContainer: UIView!
    @IBOutlet private var viewDivider: UIView!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var labelTitle: UILabel!
    @IBOutlet private var labelSunday: UILabel!
    @IBOutlet private var labelMonday: UILabel!
    @IBOutlet private var labelTuesday: UILabel!
    @IBOutlet private var labelWednesday: UILabel!
    @IBOutlet private var labelThursday: UILabel!
    @IBOutlet private var labelFriday: UILabel!
    @IBOutlet private var labelSaturday: UILabel!
    @IBOutlet private var buttonPrevious: UIButton!
    @IBOutlet private var buttonNext: UIButton!
    
    private var gestureDragDate: UIPanGestureRecognizer!
    
    private var currentFirstDayOfMonth: NSDate
    private var firstDate: NSDate
    private var endDate: NSDate
    private var holidaysDate = [NSDate]()
    private var holidaysName = [String]()
    private var holidaysDatePerMonth = [(NSDate, String)]()
    
    private var lastFrame = CGRectZero
    private var beginIndex: Int?
    private var endIndex: Int?
    private var draggingBeginDate = false
    private var lastConstantOffset = CGPoint(x: 0, y: 0)
    
    private let dateFormatter = NSDateFormatter()
    
    private var minDate: NSDate {
        didSet {
            firstDate = minDate.firstDayOfCurrentMonth().lastSunday()
        }
    }
    
    private var maxDate = NSDate().dateByAddingDay(365) {
        didSet {
            endDate = maxDate.endDayOfCurrentMonth().nextSaturday()
        }
    }
    
    // MARK: - Public Properties
    
    public var beginDate: NSDate? {
        guard let index = beginIndex else {
            return nil
        }
        return firstDate.dateByAddingDay(index)
    }
    
    public var finishDate: NSDate? {
        guard let index = endIndex else {
            return nil
        }
        return firstDate.dateByAddingDay(index)
    }
    
    public var imagePreviousName = "ic_arrow_left_blue.png" {
        didSet {
            buttonPrevious.setImage(UIImage(named: imagePreviousName), forState: .Normal)
        }
    }
    
    public var imageNextName = "ic_arrow_right_blue.png" {
        didSet {
            buttonNext.setImage(UIImage(named: imageNextName), forState: .Normal)
        }
    }
    
    public var localeIdentifier: String = "en_US" {
        didSet {
            dateFormatter.locale = NSLocale(localeIdentifier: localeIdentifier)
            reload()
        }
    }
    
    public var delegate: CalendarViewDelegate?
    
    // MARK: - Constructors
    
    override init(frame: CGRect) {
        minDate = NSDate().normalizeTime()
        maxDate = minDate.dateByAddingDay(365)
        firstDate = minDate.firstDayOfCurrentMonth().lastSunday()
        endDate = maxDate.endDayOfCurrentMonth().dateByAddingDay(7).nextSaturday()
        currentFirstDayOfMonth = minDate.firstDayOfCurrentMonth()
        
        super.init(frame: frame)
        loadViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        minDate = NSDate().normalizeTime()
        maxDate = minDate.dateByAddingDay(365)
        firstDate = minDate.firstDayOfCurrentMonth().lastSunday()
        endDate = maxDate.endDayOfCurrentMonth().dateByAddingDay(7).nextSaturday()
        currentFirstDayOfMonth = minDate.firstDayOfCurrentMonth()
        
        super.init(coder: aDecoder)
        loadViews()
    }
    
    // MARK: - Overrides
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if !CGRectEqualToRect(lastFrame, frame) {
            lastFrame = frame
            collectionView?.reloadData()
        }
        collectionView.layoutIfNeeded()
        scrollToMonthOfDate(currentFirstDayOfMonth)
    }
    
    // MARK: - Methods
    
    private func loadViews() {
        let view = CalendarViewUtils.instance.bundle.loadNibNamed("CalendarView", owner: self, options: nil).first as! UIView
        view.frame = bounds
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        addSubview(view)
        
        gestureDragDate = UIPanGestureRecognizer(target: self, action: #selector(CalendarView.handleDragDate(_:)))
        gestureDragDate.delegate = self
        
        collectionView.addGestureRecognizer(gestureDragDate)
        
        collectionView.registerNib(UINib(nibName: "CalendarDayCell", bundle: CalendarViewUtils.instance.bundle), forCellWithReuseIdentifier: "DayCell")
        
        reload()
    }
    
    public func convertIndex(row: Int) -> Int {
        let i = row
        let a = Int(floor(Double(i%42)/6.0))
        let b = Int(((i%6)*7))
        let c = Int(floor(floor(Double(i)/6.0)/7.0)*42)
        let i2 = a+b+c
        return i2
    }
    
    public func diffDay(newRow: Int) -> Int {
        let sectionMonth = Int(floor(Double(newRow)/42.0))
        let a = minDate.firstDayOfCurrentMonth().dateByAddingMonth(sectionMonth).lastSunday()
        let diff_a_firstDate = getDiffDay(firstDate, a)
        let diffDay = (sectionMonth*42) - diff_a_firstDate
        return diffDay
    }
    
    public func scrollToMonthOfDate(date: NSDate) {
        if date.compare(maxDate.firstDayOfCurrentMonth()) != .OrderedDescending && date.compare(firstDate) != .OrderedAscending {
            currentFirstDayOfMonth = date.firstDayOfCurrentMonth()
            let calendar = CalendarViewUtils.instance.calendar
            let diff = calendar.components(.Month, fromDate: firstDate, toDate: currentFirstDayOfMonth, options: [])
            let month = diff.month * 42
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: month, inSection: 0), atScrollPosition: .Left, animated: true)
        }
        holidaysDatePerMonth.removeAll()
        delegate?.calendarView(self, didScrollToMonth: holidaysDatePerMonth)
        collectionView.reloadData()
        updateMonthYearViews()
    }
    
    public func setMinDate(minDate: NSDate, maxDate: NSDate) {
        if minDate.compare(maxDate) != .OrderedAscending {
            fatalError("Min date must be earlier than max date")
        }
        self.minDate = minDate.normalizeTime()
        self.maxDate = maxDate.normalizeTime()
        
        holidaysDatePerMonth.removeAll()
        collectionView.reloadData()
    }
    
    public func setHolidaysDate(date: NSDate) {
        self.holidaysDate.append(date)
        
        holidaysDatePerMonth.removeAll()
        collectionView.reloadData()
    }
    
    public func setHolidaysName(name: String) {
        self.holidaysName.append(name)
        
        holidaysDatePerMonth.removeAll()
        collectionView.reloadData()
    }
    
    public func removeHolidays() {
        self.holidaysDate.removeAll()
        self.holidaysName.removeAll()
        
        holidaysDatePerMonth.removeAll()
        collectionView.reloadData()
    }
    
    public func setBeginDate(beginDate: NSDate?, finishDate: NSDate?) {
        if beginDate == nil {
            beginIndex = nil
            endIndex = nil
            holidaysDatePerMonth.removeAll()
            collectionView.reloadData()
            return
        }
        if let beginDate = beginDate {
            let calendar = CalendarViewUtils.instance.calendar
            let components = calendar.components(.Day, fromDate: firstDate, toDate: beginDate, options: [])
            if beginDate.compare(minDate) != .OrderedAscending {
                beginIndex = components.day
            } else {
                beginIndex = nil
            }
            if let finishDate = finishDate {
                let components = calendar.components(.Day, fromDate: firstDate, toDate: finishDate, options: [])
                if finishDate.compare(maxDate) != .OrderedDescending {
                    endIndex = components.day
                } else {
                    endIndex = nil
                }
            } else {
                endIndex = nil
            }
            holidaysDatePerMonth.removeAll()
            collectionView.reloadData()
        }
    }
    
    public func reload() {
        viewTitleContainer.backgroundColor = CalendarViewTheme.instance.bgColorForMonthContainer
        viewDaysOfWeekContainer.backgroundColor = CalendarViewTheme.instance.bgColorForDaysOfWeekContainer
        viewBackground.backgroundColor = CalendarViewTheme.instance.bgColorForOtherMonth
        labelSunday.textColor = CalendarViewTheme.instance.textColorForHoliday
        labelMonday.textColor = CalendarViewTheme.instance.textColorForDayOfWeek
        labelTuesday.textColor = CalendarViewTheme.instance.textColorForDayOfWeek
        labelWednesday.textColor = CalendarViewTheme.instance.textColorForDayOfWeek
        labelThursday.textColor = CalendarViewTheme.instance.textColorForDayOfWeek
        labelFriday.textColor = CalendarViewTheme.instance.textColorForDayOfWeek
        labelSaturday.textColor = CalendarViewTheme.instance.textColorForDayOfWeek
        viewDivider.backgroundColor = CalendarViewTheme.instance.colorForDivider
        
        labelTitle.textColor = CalendarViewTheme.instance.textColorForTitle
        
        let date = minDate.lastSunday()
        dateFormatter.dateFormat = "EEEEE"
        labelSunday.text = dateFormatter.stringFromDate(date)
        labelMonday.text = dateFormatter.stringFromDate(date.dateByAddingDay(1))
        labelTuesday.text = dateFormatter.stringFromDate(date.dateByAddingDay(2))
        labelWednesday.text = dateFormatter.stringFromDate(date.dateByAddingDay(3))
        labelThursday.text = dateFormatter.stringFromDate(date.dateByAddingDay(4))
        labelFriday.text = dateFormatter.stringFromDate(date.dateByAddingDay(5))
        labelSaturday.text = dateFormatter.stringFromDate(date.dateByAddingDay(6))
        
        updateMonthYearViews()
        
        holidaysDatePerMonth.removeAll()
        collectionView.reloadData()
    }
}

// MARK: - Month View

extension CalendarView {
    
    @IBAction private func buttonPreviousMonthPressed() {
        scrollToPreviousMonth()
    }
    
    @IBAction private func buttonNextMonthPressed() {
        scrollToNextMonth()
    }
    
    private func updateMonthYearViews() {
        dateFormatter.dateFormat = "MMMM yyyy"
        labelTitle.text = dateFormatter.stringFromDate(currentFirstDayOfMonth)
    }
    
    private func scrollToPreviousMonth() {
        let calendar = CalendarViewUtils.instance.calendar
        let diffComponents = NSDateComponents()
        diffComponents.month = -1
        let date = calendar.dateByAddingComponents(diffComponents, toDate: currentFirstDayOfMonth, options: [])
        if let date = date {
            scrollToMonthOfDate(date)
        }
    }
    
    private func scrollToNextMonth() {
        let calendar = CalendarViewUtils.instance.calendar
        let diffComponents = NSDateComponents()
        diffComponents.month = 1
        let date = calendar.dateByAddingComponents(diffComponents, toDate: currentFirstDayOfMonth, options: [])
        if let date = date {
            scrollToMonthOfDate(date)
        }
    }
    
    private func getDiffDay(_ dateFrom: NSDate, _ dateTo: NSDate) -> Int {
        var calendar = CalendarViewUtils.instance.calendar
        let diff = calendar.components(.Day, fromDate: dateFrom, toDate: dateTo, options: [])
        return diff.day
    }
}

// MARK: - UICollectionView

extension CalendarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let calendar = CalendarViewUtils.instance.calendar
        let components = calendar.components(.Month, fromDate: firstDate, toDate: endDate, options: [])
        let diff = getDiffDay(endDate.endDayOfCurrentMonth(), endDate)
        return (components.month-1) * 42
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let rowConverted = convertIndex(indexPath.row)
        let diff = diffDay(rowConverted)
        let newIndexRow = rowConverted - diff
        
        let date = firstDate.dateByAddingDay(newIndexRow)
        let disabled = date.normalizeTime().compare(minDate) == NSComparisonResult.OrderedAscending
        var isHoliday: Bool
        if newIndexRow % 7 == 0 {
            isHoliday = true
        } else {
            isHoliday = false
        }
        
        let state: CalendarDayCellState
        if disabled {
            state = .Disabled
        } else if let beginIndex = beginIndex where beginIndex == newIndexRow {
            state = .Start(hasNext: endIndex != nil)
        } else if let endIndex = endIndex where endIndex == newIndexRow {
            state = .End
        } else if let beginIndex = beginIndex, let endIndex = endIndex where newIndexRow > beginIndex && newIndexRow < endIndex {
            state = .Range
        } else {
            state = .Normal
        }
        let calendar = CalendarViewUtils.instance.calendar
        let components = calendar.components([.Month, .Year], fromDate: date)
        let currentComponents = calendar.components([.Month, .Year], fromDate: currentFirstDayOfMonth)
        let isCurrentMonth = components.month == currentComponents.month && components.year == currentComponents.year
        
        if let found = holidaysDate.indexOf({$0.equalToDate(date)}) {
            isHoliday = true
            if isCurrentMonth {
                let holiday = (date, holidaysName[found])
                holidaysDatePerMonth.append(holiday)
                delegate?.calendarView(self, didScrollToMonth: holidaysDatePerMonth)
            }
        }
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("DayCell", forIndexPath: indexPath) as! CalendarDayCell
        cell.updateWithDate(date, state: state, isCurrentMonth: isCurrentMonth, isHoliday: isHoliday)
        return cell
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 0
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = widthForCellAtIndexPath(indexPath)
        return CGSize(width: width, height: 38)
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! CalendarDayCell
        let date = cell.date
        switch cell.state {
        case .Disabled:
            return
        default:
            break
        }
        
        let rowConverted = convertIndex(indexPath.row)
        let diff = diffDay(rowConverted)
        let newIndexRow = rowConverted - diff
        
        if beginIndex == nil {
            beginIndex = newIndexRow
            delegate?.calendarView(self, didUpdateBeginDate: date)
        } else if let beginIndex = beginIndex where newIndexRow <= beginIndex && endIndex == nil {
            self.beginIndex = newIndexRow
            delegate?.calendarView(self, didUpdateBeginDate: date)
        } else if let beginIndex = beginIndex where newIndexRow > beginIndex && endIndex == nil {
            endIndex = newIndexRow
            delegate?.calendarView(self, didUpdateFinishDate: date)
            let calendar = CalendarViewUtils.instance.calendar
            let components = calendar.components([.Month, .Year], fromDate: date)
            let currentComponents = calendar.components([.Month, .Year], fromDate: currentFirstDayOfMonth)
        } else if beginIndex != nil && endIndex != nil {
            beginIndex = newIndexRow
            endIndex = nil
            delegate?.calendarView(self, didUpdateBeginDate: date)
            delegate?.calendarView(self, didUpdateFinishDate: nil)
        }
        holidaysDatePerMonth.removeAll()
        collectionView.reloadData()
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        lastConstantOffset = scrollView.contentOffset
        holidaysDatePerMonth.removeAll()
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if lastConstantOffset.x < scrollView.contentOffset.x {
            self.scrollToNextMonth()
        }
        else if lastConstantOffset.x > scrollView.contentOffset.x {
            self.scrollToPreviousMonth()
        }
        delegate?.calendarView(self, didScrollToMonth: holidaysDatePerMonth)
    }
    
    private func widthForCellAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
        let width = bounds.width
        var cellWidth = floor(width / 7)
        let newRow = convertIndex(indexPath.row)
        if newRow % 7 == 6 {
            cellWidth = cellWidth + (width - (cellWidth * 7))
        }
        return cellWidth
    }
}

extension NSDate {
    
    func equalToDate(dateToCompare: NSDate) -> Bool {
        //Declare Variables
        var isEqualTo = false
        
        //Compare Values
        if self.compare(dateToCompare) == NSComparisonResult.OrderedSame {
            isEqualTo = true
        }
        
        //Return Result
        return isEqualTo
    }
}

extension CalendarView: UIGestureRecognizerDelegate {
    
    public override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.locationInView(collectionView)
        if let indexPath = collectionView.indexPathForItemAtPoint(point),
            let beginIndex = beginIndex,
            let endIndex = endIndex
            where convertIndex(indexPath.row) - diffDay(convertIndex(indexPath.row)) == beginIndex || convertIndex(indexPath.row) - diffDay(convertIndex(indexPath.row)) == endIndex
        {
            collectionView.scrollEnabled = false
            draggingBeginDate = convertIndex(indexPath.row) - diffDay(convertIndex(indexPath.row)) == beginIndex
            return true
        }
        return false
    }
    
    public func handleDragDate(gestureRecognizer: UIGestureRecognizer) {
        
        if(gestureRecognizer.state == .Ended)
        {
            collectionView.scrollEnabled = true
        }
        
        let point = gestureRecognizer.locationInView(collectionView)
        if let indexPath = collectionView.indexPathForItemAtPoint(point),
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as? CalendarDayCell,
            let beginIndex = beginIndex,
            let endIndex = endIndex
        {
            switch cell.state {
            case .Disabled:
                return
            default:
                break
            }
            let index = convertIndex(indexPath.row) - diffDay(convertIndex(indexPath.row))
            if draggingBeginDate {
                if index < endIndex {
                    self.beginIndex = index
                } else if index > endIndex {
                    draggingBeginDate = false
                    self.beginIndex = endIndex
                    self.endIndex = index
                }
            } else {
                if index > beginIndex {
                    self.endIndex = index
                } else if index < beginIndex {
                    draggingBeginDate = true
                    self.beginIndex = index
                    self.endIndex = beginIndex
                }
            }
            if self.beginIndex != beginIndex || self.endIndex != endIndex {
                if let index = self.beginIndex where index != beginIndex {
                    delegate?.calendarView(self, didUpdateBeginDate: firstDate.dateByAddingDay(index))
                }
                if let index = self.endIndex where index != endIndex {
                    delegate?.calendarView(self, didUpdateFinishDate: firstDate.dateByAddingDay(index))
                }
                holidaysDatePerMonth.removeAll()
                collectionView.reloadData()
            }
        }
    }
}
