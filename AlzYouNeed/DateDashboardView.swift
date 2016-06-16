//
//  DateDashboardView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/16/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class DateDashboardView: UIView {

    // MARK: - Properties
    
    var view: UIView!
    
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var fullDateLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    // MARK: - Setup
    
    func xibSetup() {
        view = loadViewFromNib()
        
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType)
        let nib = UINib(nibName: "DateDashboardView", bundle: bundle)
        let view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        return view
    }
    
    func configureView(date: NSDate) {
        
        // Format time strings for all labels
        let dayFormatter = NSDateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayString = dayFormatter.stringFromDate(date)
        print(dayString)
        
        let fullDateFormatter = NSDateFormatter()
        fullDateFormatter.dateFormat = "MMMM d, yyyy"
        let fullDateString = fullDateFormatter.stringFromDate(date)
        print(fullDateString)
        
        let timeFormatter = NSDateFormatter()
        timeFormatter.dateFormat = "H:mm a"
        let timeString = timeFormatter.stringFromDate(date)
        print(timeString)

        dayLabel.text = dayString
        fullDateLabel.text = fullDateString
        timeLabel.text = timeString
    }

}
