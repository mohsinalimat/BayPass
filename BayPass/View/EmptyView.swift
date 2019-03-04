//
//  EmptyView.swift
//  BayPass
//
//  Created by Tim Roesner on 3/1/19.
//  Copyright © 2019 Tim Roesner. All rights reserved.
//

import UIKit
import SnapKit

class EmptyView: UIView {

    init(text: String) {
        super.init(frame: CGRect.zero)
        
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textColor = UIColor().lightGrey
        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
