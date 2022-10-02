//
//  HudBackgroundView.swift
//  YFProgressHud
//
//  Created by sky on 2022/9/30.
//

import UIKit

open class HudBackgroundView: UIView {

    public var style: YFProgressHudBackgroundStyle = .blur {
        didSet {
            if oldValue != style {
                updateForBackgroundStyle()
            }
        }
    }
    
    public var blurEffectStyle: UIBlurEffect.Style = .light {
        didSet {
            if oldValue != blurEffectStyle {
                updateForBackgroundStyle()
            }
        }
    }
    
    public var color: UIColor = UIColor(white: 0.8, alpha: 0.6) {
        didSet {
            if oldValue != color && !oldValue.isEqual(color) {
                updateViewsFor(color: color)
            }
        }
    }
    
    private var effectView: UIVisualEffectView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        clipsToBounds = true
        
        if #available(iOS 13, *) {
            blurEffectStyle = .systemThinMaterial
        } else {
            blurEffectStyle = .light
        }
        
        updateForBackgroundStyle()
    }
    
    public override var intrinsicContentSize: CGSize {
        return .zero
    }
}

extension HudBackgroundView {
    private func updateForBackgroundStyle() {
        effectView?.removeFromSuperview()
        effectView = nil
        
        if style == .blur {
            let effect = UIBlurEffect(style: blurEffectStyle)
            let effectView = UIVisualEffectView(effect: effect)
            insertSubview(effectView, at: 0)
            
            effectView.frame = bounds
            effectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            backgroundColor = color
            layer.allowsGroupOpacity = false
            self.effectView = effectView
        } else {
            backgroundColor = color
        }
    }
    
    private func updateViewsFor(color: UIColor) {
        self.backgroundColor = color
    }
}
