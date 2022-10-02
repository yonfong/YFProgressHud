//
//  HudRoundedButton.swift
//  YFProgressHud
//
//  Created by sky on 2022/9/30.
//

import UIKit

open class HudRoundedButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    private func setupViews() {
        layer.borderWidth = 1
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = ceil(bounds.height / 2.0)
    }
    
    public override var intrinsicContentSize: CGSize {
        if allControlEvents == UIControl.Event(rawValue: 0) || title(for: .normal)?.count == 0 {
            return .zero
        } else {
            var targetSize = super.intrinsicContentSize
            targetSize.width = targetSize.width + 20
            return targetSize
        }
    }
    
    public override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        
        isHighlighted = isHighlighted
        layer.borderColor = color?.cgColor
    }
    
    public override var isHighlighted: Bool {
        get {
            return super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            let selectedColor = titleColor(for: .selected)
            
            backgroundColor = isHighlighted ? selectedColor?.withAlphaComponent(0.1) : .clear
        }
    }
}
