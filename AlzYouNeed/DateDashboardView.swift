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
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "DateDashboardView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
    
    func configureView(_ date: Date) {
        
        // Format time strings for all labels
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayString = dayFormatter.string(from: date)
//        print(dayString)
        
        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "MMMM d, yyyy"
        let fullDateString = fullDateFormatter.string(from: date)
//        print(fullDateString)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: date)
//        print(timeString)

        dayLabel.text = dayString
        fullDateLabel.text = fullDateString
        timeLabel.text = timeString
    }

}
