//
//  HudRoundProgressView.swift
//  YFProgressHud
//
//  Created by sky on 2022/9/30.
//

import UIKit

open class HudRoundProgressView: UIView {
    public var progress: Float = 0.0 {
        didSet {
            if oldValue != progress {
                setNeedsDisplay()
            }
        }
    }
    
    public var progressTintColor: UIColor = UIColor(white: 1.0, alpha: 1.0) {
        didSet {
            if oldValue != progressTintColor && !oldValue.isEqual(progressTintColor) {
                setNeedsDisplay()
            }
        }
    }
    
    public var backgroundTintColor: UIColor = UIColor(white: 1.0, alpha: 0.1) {
        didSet {
            if oldValue != backgroundTintColor && !oldValue.isEqual(backgroundTintColor) {
                setNeedsDisplay()
            }
        }
    }
    
    public var annular: Bool = false {
        didSet {
            if oldValue != annular {
                setNeedsDisplay()
            }
        }
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 37.0, height: 37.0))
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
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 37, height: 37)
    }
    
    public override func draw(_ rect: CGRect) {
        
        // Draw background
        let lineWidth: CGFloat = 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let pi = CGFloat(Double.pi)

        if annular {
            let radius: CGFloat = (bounds.size.width - lineWidth) / 2
            let startAngle: CGFloat = -(pi / 2) // 90 degrees
            var endAngle: CGFloat = 2 * pi + startAngle
            
            let processBackgroundPath = UIBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .butt
            processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            backgroundTintColor.set()
            processBackgroundPath.stroke()
            
            // Draw progress
            endAngle = CGFloat(progress) * 2 * pi + startAngle
            
            let processPath = UIBezierPath()
            processPath.lineWidth = lineWidth
            processPath.lineCapStyle = .square
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            progressTintColor.set()
            processPath.stroke()
            
        } else {
            let context = UIGraphicsGetCurrentContext()
            let circleRect = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            
            progressTintColor.setStroke()
            backgroundTintColor.setFill()

            context?.setLineWidth(lineWidth)
            context?.strokeEllipse(in: circleRect)
            
            // Draw progress
            let processPath = UIBezierPath()
            processPath.lineWidth = lineWidth * 2
            processPath.lineCapStyle = .butt

            let radius = bounds.width / 2 - processPath.lineWidth / 2
            let startAngle: CGFloat = -(pi / 2) // 90 degrees
            let endAngle = CGFloat(progress) * 2 * pi + startAngle
            
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

            // Ensure that we don't get color overlapping when _progressTintColor alpha < 1.f.
            context?.setBlendMode(.copy)

            progressTintColor.set()
            processPath.stroke()
        }
    }
}

extension HudRoundProgressView: YFProgressConfigration {
    public func config(progress: Float) {
        self.progress = progress
    }
}
