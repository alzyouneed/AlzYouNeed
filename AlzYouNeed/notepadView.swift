//
//  notepadView.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 3/2/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit

@IBDesignable class notepadView: UIView {
    var view: UIView!

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var changesLabel: UILabel!
    @IBOutlet var notesTextView: UITextView!
    
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
        let nib = UINib(nibName: "notepadView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }
}
