//
//  HudBarProgressView.swift
//  YFProgressHud
//
//  Created by sky on 2022/9/30.
//

import UIKit

open class HudBarProgressView: UIView {
    
    public var progress: Float = 0 {
        didSet {
            if oldValue != progress {
                setNeedsDisplay()
            }
        }
    }
    
    public var lineColor: UIColor = .white
    
    public var progressColor: UIColor = .white {
        didSet {
            if oldValue != progressColor && !oldValue.isEqual(progressColor) {
                setNeedsDisplay()
            }
        }
    }
    
    public var progressRemainingColor: UIColor = .clear {
        didSet {
            if oldValue != progressRemainingColor && !oldValue.isEqual(progressRemainingColor) {
                setNeedsDisplay()
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 120.0, height: 20.0))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
    }

    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 120, height: 10)
    }
    
    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let borderLineWidth: CGFloat = 2
        
        context?.setLineWidth(borderLineWidth)
        let strokeColor = lineColor
        context?.setStrokeColor(strokeColor.cgColor)
        context?.setFillColor(progressRemainingColor.cgColor)
        
        // Draw background and Border
        let height = rect.size.height
        let width = rect.size.width
        var radius = height / 2 - borderLineWidth
        
        context?.move(to: CGPoint(x: borderLineWidth, y: height / 2))
        
        context?.addArc(tangent1End: CGPoint(x: borderLineWidth, y: borderLineWidth), tangent2End: CGPoint(x: radius + borderLineWidth, y: borderLineWidth), radius: radius)
        context?.addArc(tangent1End: CGPoint(x: width - borderLineWidth, y: borderLineWidth), tangent2End: CGPoint(x: width - borderLineWidth, y: height / 2), radius: radius)
        context?.addArc(tangent1End: CGPoint(x: width - borderLineWidth, y: height - borderLineWidth), tangent2End: CGPoint(x: width - radius - borderLineWidth, y: height - borderLineWidth), radius: radius)
        context?.addArc(tangent1End: CGPoint(x: borderLineWidth, y: height - borderLineWidth), tangent2End: CGPoint(x: borderLineWidth, y: height / 2), radius: radius)
        
        context?.drawPath(using: .stroke)
        
    
        // Progress in the middle area
        let fillColor = progressColor
        context?.setFillColor(fillColor.cgColor)
        radius = radius - borderLineWidth
        let amount = CGFloat(progress) * width
        let borderWidth = borderLineWidth * 2

        if amount >= radius + borderWidth, amount <= width - radius - borderWidth {
            context?.move(to: CGPoint(x: borderWidth, y: height / 2))
            context?.addArc(tangent1End: CGPoint(x: borderWidth, y: borderWidth), tangent2End: CGPoint(x: radius + borderWidth, y: borderWidth), radius: radius)
            context?.addLine(to: CGPoint(x: amount, y: borderWidth))
            context?.addLine(to: CGPoint(x: amount, y: radius + borderWidth))

            context?.move(to: CGPoint(x: borderWidth, y: height / 2))
            context?.addArc(tangent1End: CGPoint(x: borderWidth, y: height - borderWidth), tangent2End: CGPoint(x: radius + borderWidth, y: height - borderWidth), radius: radius)
            context?.addLine(to: CGPoint(x: amount, y: height - borderWidth))
            context?.addLine(to: CGPoint(x: amount, y: radius + borderWidth))

            context?.fillPath()

        } else if amount > radius + borderWidth {

            let x = amount - (width - radius - borderWidth)

            context?.move(to: CGPoint(x: borderWidth, y: height / 2))
            context?.addArc(tangent1End: CGPoint(x: borderWidth, y: borderWidth), tangent2End: CGPoint(x: radius + borderWidth, y: borderWidth), radius: radius)
            context?.addLine(to: CGPoint(x: width - radius - borderWidth, y: borderWidth))

            var angle = -acos(x / radius)
            if angle.isNaN { angle = 0 }
            context?.addArc(center: CGPoint(x: width - radius - borderWidth, y: height / 2), radius: radius, startAngle: CGFloat(Double.pi), endAngle: angle, clockwise: false)
            context?.addLine(to: CGPoint(x: amount, y: height / 2))

            context?.move(to: CGPoint(x: borderWidth, y: height / 2))
            context?.addArc(tangent1End: CGPoint(x: borderWidth, y: height - borderWidth), tangent2End: CGPoint(x: radius + borderWidth, y: height - borderWidth), radius: radius)
            context?.addLine(to: CGPoint(x: width - radius - borderWidth, y: height - borderWidth))

            angle = acos(x / radius)
            if angle.isNaN { angle = 0 }
            context?.addArc(center: CGPoint(x: width - radius - borderWidth, y: height / 2), radius: radius, startAngle: -CGFloat(Double.pi), endAngle: angle, clockwise: true)
            context?.addLine(to: CGPoint(x: amount, y: height / 2))

            context?.fillPath()

        } else if amount < radius + borderWidth, amount > 0 {
            context?.move(to: CGPoint(x: borderWidth, y: height / 2))
            context?.addArc(tangent1End: CGPoint(x: borderWidth, y: borderWidth), tangent2End: CGPoint(x: radius + borderWidth, y: borderWidth), radius: radius)
            context?.addLine(to: CGPoint(x: radius + borderWidth, y: height / 2))

            context?.move(to: CGPoint(x: borderWidth, y: height / 2))
            context?.addArc(tangent1End: CGPoint(x: borderWidth, y: height - borderWidth), tangent2End: CGPoint(x: radius + borderWidth, y: height - borderWidth), radius: radius)
            context?.addLine(to: CGPoint(x: radius + borderWidth, y: height / 2))

            context?.fillPath()
        }
    }
}

extension HudBarProgressView: YFProgressConfigration {
    public func config(progress: Float) {
        self.progress = progress
    }
}
