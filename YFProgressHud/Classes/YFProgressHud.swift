//
//  YBProgressHudView.swift
//  YFProgressHud
//
//  Created by sky on 2022/10/1.
//

import UIKit

public protocol YFProgressHUDDelegate: AnyObject {
    func hudWasHidden(hud: YFProgressHud)
}

extension YFProgressHUDDelegate {
    func hudWasHidden(hud: YFProgressHud) {
        debugPrint(hud)
    }
}

public protocol YFProgressConfigration {
    func config(progress: Float)
}

public let KProgressMaxOffset: CGFloat = 1000000.0
public let KDefaultPadding: CGFloat = 4
public let KDefaultLabelFontSize: CGFloat = 16
public let KDefaultDetailsLabelFontSize: CGFloat = 12

open class YFProgressHud: UIView {
    
    public weak var delegate: YFProgressHUDDelegate?
    
    public var completionBlock: (() -> Void)?
    
    public var graceTime = 0.0
    public var minShowTime = 0.0
    public var removeFromSuperViewOnHide = false
    
    public var mode: YFProgressHudMode = .indeterminate {
        didSet {
            if oldValue != mode {
                self.updateIndicators()
            }
        }
    }
    
    public var contentColor: UIColor = UIColor(white: 0, alpha: 0.7) {
        didSet {
            if oldValue != contentColor && !oldValue.isEqual(contentColor) {
                updateViews(for: contentColor)
            }
        }
    }
    
    public var animationType = YFProgressHudAnimation.fade
    
    public var offset: CGPoint = .zero {
        didSet {
            if !oldValue.equalTo(offset) {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var margin = 20.0 {
        didSet {
            if oldValue != margin {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var bezelVerticalMargin: CGFloat? { didSet { setNeedsUpdateConstraints() } }

    public var bezelHorizontalMargin: CGFloat? { didSet { setNeedsUpdateConstraints() } }
    
    public var minSize: CGSize = CGSize.zero {
        didSet {
            if !oldValue.equalTo(minSize) {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var square = false {
        didSet {
            if oldValue != square {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var motionEffectsEnabled: Bool = false {
        didSet {
            if oldValue != motionEffectsEnabled {
                updateBezelMotionEffects()
            }
        }
    }
    
    public var progress:Float = 0.0 {
        didSet {
            if oldValue != progress {
                (indicator as? YFProgressConfigration)?.config(progress: progress)
            }
        }
    }
    
    public var progressObject: Progress? {
        didSet {
            if oldValue != progressObject {
                setProgressDisplayLink(enabled: true)
            }
        }
    }
    
    private(set) public lazy var backgroundView: HudBackgroundView = {
        let view = HudBackgroundView(frame: bounds)
        view.style = .solidColor
        view.backgroundColor = .clear
        view.alpha = 0
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        return view
    }()
    
    private(set) public lazy var bezelView: HudBackgroundView = {
        let view = HudBackgroundView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.alpha = 0
        return view
    }()

    public var customView: UIView? {
        didSet {
            if oldValue != customView && mode == .customView {
                customView?.translatesAutoresizingMaskIntoConstraints = false
                self.updateIndicators()
            }
        }
    }
    
    private(set) public var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: KDefaultLabelFontSize, weight: .medium)
        label.isOpaque = false
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private(set) public lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: KDefaultDetailsLabelFontSize, weight: .medium)
        label.isOpaque = false
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private(set) public lazy var actionButton: UIButton = {
        let button = HudRoundedButton(type: .custom)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: KDefaultDetailsLabelFontSize, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Internal Properties
    
    var useAnimation: Bool = true
    var hasFinished: Bool = false
    var showStarted: Date?
    var indicator: UIView? {
        didSet {
            indicator?.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    lazy var topSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    lazy var bottomSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    var graceTimer: Timer?
    var minShowTimer: Timer?
    var hideDelayTimer: Timer?
    
    var bezelMotionEffects: UIMotionEffectGroup?
    
    var progressObjectDisplayLink: CADisplayLink? {
        didSet {
            if oldValue != progressObjectDisplayLink {
                oldValue?.invalidate()
                progressObjectDisplayLink?.add(to: .main, forMode: .common)
            }
        }
    }

    
    // MARK: - Lifecycle
    convenience init(view:UIView) {
        self.init(frame: view.bounds)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    deinit {
        self.unregisterFromNotifications()
    }

    open override func didMoveToSuperview() {
        self.updateForCurrentOrientationAnimaged(false)
    }
    
    private func initialize() {
        if #available(iOS 13, *) {
            contentColor = .label.withAlphaComponent(0.7)
        } else {
            contentColor = UIColor(white: 0, alpha: 0.7)
        }
        
        isOpaque = false
        backgroundColor = UIColor.clear
        alpha = 0.0
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layer.allowsGroupOpacity = false
        
        configureViews()
        updateIndicators()
        registerForNotifications()
    }
    
    // MARK: - Configuration UI
    fileprivate func configureViews() {
        addSubview(backgroundView)
        addSubview(bezelView)
        
        titleLabel.textColor = contentColor
        detailsLabel.textColor = contentColor
        actionButton.setTitleColor(contentColor, for: .normal)
        
        bezelView.addSubview(topSpacer)
        bezelView.addSubview(titleLabel)
        bezelView.addSubview(detailsLabel)
        bezelView.addSubview(actionButton)
        bezelView.addSubview(bottomSpacer)
    }
    
    func updateIndicators() {
        var indicator = self.indicator
        indicator?.removeFromSuperview()

        switch mode {
        case .indeterminate:
            let indicatorView = UIActivityIndicatorView(style: .whiteLarge)
            indicatorView.startAnimating()
            bezelView.addSubview(indicatorView)
            indicator = indicatorView
            
        case .determinateHorizontalBar:
            let progressView = HudBarProgressView()
            bezelView.addSubview(progressView)
            indicator = progressView
            
        case .determinate, .annularDeterminate:
            let progressView = HudRoundProgressView()
            bezelView.addSubview(progressView)
            indicator = progressView
            
            if mode == .annularDeterminate,
                let progressView = indicator as? HudRoundProgressView {
                progressView.annular = true
            }
            
        case .customView:
            guard let customView = customView else { return }
            indicator = customView
            bezelView.addSubview(customView)
            
        case .text:
            indicator = nil
        }

        (indicator as? YFProgressConfigration)?.config(progress: progress)
        
        self.indicator = indicator
        updateViews(for: contentColor)
        setNeedsUpdateConstraints()
    }
    
    fileprivate func updateViews(for color: UIColor) {
        
        titleLabel.textColor = color
        detailsLabel.textColor = color
        actionButton.setTitleColor(color, for: .normal)
        
        guard let indicator = indicator else { return }
        
        if let indicatorView = indicator as? UIActivityIndicatorView {
            indicatorView.color = color
            
        } else if let indicatorView = indicator as? HudRoundProgressView {
            indicatorView.progressTintColor = color
            indicatorView.backgroundTintColor = color.withAlphaComponent(0.1)
            
        } else if let indicatorView = indicator as? HudBarProgressView {
            indicatorView.progressColor = color
            indicatorView.lineColor = color
        } else {
            indicator.tintColor = color
        }
    }
    
    fileprivate func updateBezelMotionEffects() {
        if motionEffectsEnabled && bezelMotionEffects == nil {
            let effectOffset = 10.0
            
            let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = effectOffset
            effectX.minimumRelativeValue = -effectOffset
            
            let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            effectY.maximumRelativeValue = effectOffset
            effectY.minimumRelativeValue = -effectOffset
            
            let effectGroup = UIMotionEffectGroup()
            effectGroup.motionEffects = [effectX, effectY]
            
            bezelView.addMotionEffect(effectGroup)
            bezelMotionEffects = effectGroup
        } else if bezelMotionEffects != nil {
            bezelView.removeMotionEffect(bezelMotionEffects!)
            bezelMotionEffects = nil
        }
    }
    
    // MARK: - Layout
    
    public override func updateConstraints() {
        
        self.removeConstraints(constraints)
        bezelView.removeConstraints(bezelView.constraints)
        topSpacer.removeConstraints(topSpacer.constraints)
        bottomSpacer.removeConstraints(bottomSpacer.constraints)
        
        var bezelViewConstraints = [
            bezelView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: offset.x),
            bezelView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: offset.y),
            bezelView.widthAnchor.constraint(greaterThanOrEqualToConstant: minSize.width),
            bezelView.heightAnchor.constraint(greaterThanOrEqualToConstant: minSize.height),
            bezelView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: margin),
            bezelView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -margin)
        ]
        if let horizontalMargin = bezelHorizontalMargin {
            let leadingConstraint = bezelView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: horizontalMargin)
            let trailingConstraint = bezelView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -horizontalMargin)
            bezelViewConstraints.append(leadingConstraint)
            bezelViewConstraints.append(trailingConstraint)
        } else {
            let leadingConstraint = bezelView.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: margin)
            let trailingConstraint = bezelView.trailingAnchor.constraint(lessThanOrEqualTo: self.trailingAnchor, constant: -margin)
            bezelViewConstraints.append(leadingConstraint)
            bezelViewConstraints.append(trailingConstraint)
        }
        
        if square {
            let squareConstraint = NSLayoutConstraint(item: bezelView, attribute: .width, relatedBy: .equal, toItem: bezelView, attribute: .height, multiplier: 1, constant: 0)
            squareConstraint.priority = UILayoutPriority(997)
            bezelViewConstraints.append(squareConstraint)
        }
        NSLayoutConstraint.activate(bezelViewConstraints)
        
        var topSpacerConstraints = [
            topSpacer.topAnchor.constraint(equalTo: bezelView.topAnchor),
            topSpacer.leadingAnchor.constraint(equalTo: bezelView.leadingAnchor),
            topSpacer.trailingAnchor.constraint(equalTo: bezelView.trailingAnchor)
        ]
        if let verticalMargin = bezelVerticalMargin {
            let heightConstraint = topSpacer.heightAnchor.constraint(equalToConstant: verticalMargin)
            topSpacerConstraints.append(heightConstraint)
        } else {
            let heightConstraint = topSpacer.heightAnchor.constraint(equalToConstant: margin)
            topSpacerConstraints.append(heightConstraint)
        }
        NSLayoutConstraint.activate(topSpacerConstraints)

        let bottomSpacerConstraints = [
            bottomSpacer.bottomAnchor.constraint(equalTo: bezelView.bottomAnchor),
            bottomSpacer.leadingAnchor.constraint(equalTo: bezelView.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: bezelView.trailingAnchor),
            bottomSpacer.heightAnchor.constraint(equalTo: topSpacer.heightAnchor)
        ]
        NSLayoutConstraint.activate(bottomSpacerConstraints)
        
        var subviews = [UIView]()
        if let indicator = indicator, !indicator.isHidden {
            subviews.append(indicator)
        }
        
        if !(titleLabel.text?.isEmpty ?? true), !titleLabel.isHidden {
            subviews.append(titleLabel)
        }

        if !(detailsLabel.text?.isEmpty ?? true), !detailsLabel.isHidden {
            subviews.append(detailsLabel)
        }

        if !(actionButton.title(for: .normal)?.isEmpty ?? true), !actionButton.isHidden {
            subviews.append(actionButton)
        }

        subviews.enumerated().forEach { (index, view) in
            var constraints = [
                view.centerXAnchor.constraint(equalTo: bezelView.centerXAnchor),
                view.leadingAnchor.constraint(greaterThanOrEqualTo: bezelView.leadingAnchor, constant: margin),
                view.trailingAnchor.constraint(lessThanOrEqualTo: bezelView.trailingAnchor, constant: -margin),
            ]
            
            if view == customView {
                let widthConstraint = view.widthAnchor.constraint(equalToConstant: view.bounds.width)
                constraints.append(widthConstraint)
            }
            
            if index == 0 {
                let topConstraint = view.topAnchor.constraint(equalTo: topSpacer.bottomAnchor)
                constraints.append(topConstraint)
                if subviews.count == 1 {
                    let bottomConstraint = view.bottomAnchor.constraint(equalTo: bottomSpacer.topAnchor)
                    constraints.append(bottomConstraint)
                }
            } else if index == subviews.count - 1 {
                let topConstraint = view.topAnchor.constraint(equalTo: subviews[index - 1].bottomAnchor, constant: KDefaultPadding)
                constraints.append(topConstraint)
                let bottomConstraint = view.bottomAnchor.constraint(equalTo: bottomSpacer.topAnchor)
                constraints.append(bottomConstraint)
            } else {
                let topConstraint = view.topAnchor.constraint(equalTo: subviews[index - 1].bottomAnchor, constant: KDefaultPadding)
                constraints.append(topConstraint)
            }
            
            NSLayoutConstraint.activate(constraints)
        }
        
        super.updateConstraints()
    }
    
    public override func layoutSubviews() {
        if !self.needsUpdateConstraints() {
            updateConstraints()
        }
        super.layoutSubviews()
    }
    
    // MARK: - Notificaiton
    fileprivate func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationDidChange), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    fileprivate func unregisterFromNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
     @objc func statusBarOrientationDidChange(_ notification: Notification) {
         if superview != nil {
             self.updateForCurrentOrientationAnimaged(true)
         }
    }
    
    fileprivate func updateForCurrentOrientationAnimaged(_ animated: Bool) {
        // Stay in sync with the superview in any case
        if let superView = self.superview {
            self.bounds = superView.bounds
            self.setNeedsDisplay()
        }
    }
}

extension YFProgressHud {
    //MARK: - Show & Hide
    public func show(animated: Bool) {
        assert(Thread.isMainThread, "Hud needs to be accessed on the main thread.")
        
        minShowTimer?.invalidate()
        useAnimation = animated
        hasFinished = false
        if graceTime > 0.0 {
            let timer = Timer(timeInterval: graceTime, target: self, selector: #selector(handleGraceTimer(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .common)
            graceTimer = timer
        } else {  // ... otherwise show the HUD imediately
            self.showUsingAnimation(useAnimation)
        }
    }
    
    public func hide(animated: Bool) {
        assert(Thread.isMainThread, "Hud needs to be accessed on the main thread.")
        graceTimer?.invalidate()
        useAnimation = animated
        hasFinished = true
        // If the minShow time is set, calculate how long the hud was shown,
        // and pospone the hiding operation if necessary
        if let showStarted = showStarted, minShowTime > 0.0 {
            let interval = Date().timeIntervalSince(showStarted)
            
            guard interval < minShowTime else { return }
            
            let timer = Timer(timeInterval: minShowTime - interval, target: self, selector:#selector(handleMinShowTimer(_:)) , userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .common)
            minShowTimer = timer
        } else {    // ... otherwise hide the HUD immediately
            self.hideUsingAnimation(useAnimation)
        }
    }
    
    public func hide(animated: Bool, afterDelay delay: TimeInterval) {
        hideDelayTimer?.invalidate()
        
        let timer = Timer(timeInterval: delay, target: self, selector:#selector(handleHideTimer(_:)) , userInfo: animated, repeats: false)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        hideDelayTimer = timer
    }
        
    // MARK: - Timer callbacks
    @objc fileprivate func handleGraceTimer(_ timer: Timer) {
        if !hasFinished {
            self.showUsingAnimation(useAnimation)
        }
    }
    
    @objc fileprivate func handleMinShowTimer(_ timer: Timer) {
        self.hideUsingAnimation(useAnimation)
    }
    
    @objc fileprivate func handleHideTimer(_ timer: Timer) {
        let animation = timer.userInfo as? Bool ?? false
        hide(animated: animation)
    }
    
    // MARK: -  Internal show & hide operations
    fileprivate func showUsingAnimation(_ animated: Bool) {
        // Cancel any previous animations
        bezelView.layer.removeAllAnimations()
        backgroundView.layer.removeAllAnimations()
        
        // Cancel any scheduled hideAnimated:afterDelay: calls
        hideDelayTimer?.invalidate()
        
        showStarted = Date()
        alpha = 1.0
        
        // Needed in case we hide and re-show with the same NSProgress object attached.
        setProgressDisplayLink(enabled: true)
        
        // Set up motion effects only at this point to avoid needlessly
        // creating the effect if it was disabled after initialization.
        updateBezelMotionEffects()
        
        //Fade in
        if animated {
            animate(inAnimating: true, with: animationType)
        } else {
            bezelView.alpha = 1.0
            backgroundView.alpha = 1.0
        }
    }
    
    fileprivate func hideUsingAnimation(_ animated: Bool) {
        // Cancel any scheduled hideAnimated:afterDelay: calls.
        // This needs to happen here instead of in done,
        // to avoid races if another hideAnimated:afterDelay:
        // call comes in while the HUD is animating out.
        hideDelayTimer?.invalidate()
        
        // Fade out
        if animated && showStarted != nil {
            showStarted = nil
            animate(inAnimating: false, with: animationType) {[weak self] (finished) in
                self?.progressDone()
            }
        } else {
            showStarted = nil
            bezelView.alpha = 0.0
            backgroundView.alpha = 1.0
            progressDone()
        }
    }
    
    private func animate(inAnimating: Bool, with type: YFProgressHudAnimation, completion:((Bool) -> Void)? = nil) {
        var targetAnimation = type
        if type == .zoom {
            targetAnimation = inAnimating ? .zoomIn : .zoomOut
        }
        
        let small = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        if inAnimating && bezelView.alpha == 0 && targetAnimation == .zoomIn {
            bezelView.transform = small
        } else if inAnimating && bezelView.alpha == 0 && targetAnimation == .zoomOut {
            bezelView.transform = large
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .beginFromCurrentState, animations: {[weak self] in
            if inAnimating {
                self?.bezelView.transform = .identity
            } else if !inAnimating && targetAnimation == .zoomIn {
                self?.bezelView.transform = large
            } else if !inAnimating && targetAnimation == .zoomOut {
                self?.bezelView.transform = small
            }
            let alpha = inAnimating ? 1.0 : 0.0
            self?.bezelView.alpha = alpha
            self?.backgroundView.alpha = alpha
        }, completion: completion)
    }
    
    fileprivate func progressDone() {
        setProgressDisplayLink(enabled: false)

        if hasFinished {
            alpha = 0.0
            if removeFromSuperViewOnHide {
                removeFromSuperview()
            }
        }
        
        completionBlock?()
        delegate?.hudWasHidden(hud: self)
    }
}

extension YFProgressHud {
    // MARK: progress
    private func setProgressDisplayLink(enabled: Bool) {
        guard
            enabled,
            progressObject != nil,
            progressObjectDisplayLink == nil else {
            progressObjectDisplayLink?.invalidate()
            progressObjectDisplayLink = nil
            return
        }
        
        progressObjectDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgressFromProgressObject))
    }
    
    @objc private func updateProgressFromProgressObject() {
        progress = Float(progressObject?.fractionCompleted ?? 0)
    }
}


extension YFProgressHud {
    @discardableResult
    public class func showAdded(to view: UIView, animated: Bool) -> YFProgressHud {
        let hud: YFProgressHud = YFProgressHud(view: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud
    }
    
    @discardableResult
    public class func hide(for view: UIView, animated: Bool) -> Bool {
        guard let hud = self.hud(for: view) else {
            return false
        }
        
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: animated)
        
        return true
    }
    
    @discardableResult
    public class func hud(for view: UIView) -> YFProgressHud? {
        let subviewsEnum = view.subviews.reversed()
        
        let hud = subviewsEnum.first { (subView) -> Bool in
            guard
                let item = subView as? YFProgressHud,
                !item.hasFinished else { return false }
            return true
        }
        
        return hud as? YFProgressHud
    }
}

