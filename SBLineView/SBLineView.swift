//
//  SBLineChartView.swift
//  SBViews Demo
//
//  Created by Stefan Britton on 2016-09-25.
//  Copyright © 2016 Appstefan. All rights reserved.
//

import UIKit

public protocol SBLineViewDelegate {
    func lineView(_ lineView: SBLineView, didSelect value: Double, at index: Int)
    func lineViewTouchesEnded(_ lineView: SBLineView)
}

public protocol SBLineViewDataSource {
    func numberOfPointsIn(_ lineView: SBLineView) -> Int
    func lineView(_ lineView: SBLineView, valueAt index: Int) -> Double
}

@IBDesignable
public class SBLineView: UIView {
    // MARK: - Line
    @IBInspectable public var lineStrokeColor: UIColor = .black { didSet { setNeedsDisplay() } }
    @IBInspectable public var lineStrokeWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }
    
    // MARK: - Point
    @IBInspectable var pointSize: CGFloat = 0 { didSet { setNeedsDisplay() } }
    @IBInspectable var pointFillColor: UIColor = .white { didSet { setNeedsDisplay() } }
    @IBInspectable var pointStrokeColor: UIColor = .black { didSet { setNeedsDisplay() } }
    @IBInspectable var pointStrokeWidth: CGFloat = 1 { didSet { setNeedsDisplay() } }

    // MARK: - Curve
    @IBInspectable var curveLines: Bool = true { didSet { setNeedsDisplay() } }
    var curveControlOffset: CGFloat = 20

    // MARK: - Touch Line
    let touchLine = CAShapeLayer()
    @IBInspectable var curvedTouchLine: Bool = false
    @IBInspectable var touchLineStrokeColor: UIColor = .blue
    @IBInspectable var touchLineWidth: CGFloat = 1
    @IBInspectable var touchLineShowAcrossTop: Bool = false
    let touchLineTopLeft = CAShapeLayer()
    let touchLineTopRight = CAShapeLayer()

    // MARK: - Value Line
    let valueLine = CAShapeLayer()
    @IBInspectable var valueLineStrokeColor: UIColor = UIColor.lightGray
    @IBInspectable var valueLineWidth: CGFloat = 1 / UIScreen.main.scale

    // MARK: - Touch Point
    let touchPoint = CAShapeLayer()
    @IBInspectable var touchPointSize: CGFloat = 8
    @IBInspectable var touchPointStrokeColor: UIColor = .blue
    @IBInspectable var touchPointStrokeWidth: CGFloat = 1
    @IBInspectable var touchPointFillColor: UIColor = .clear
    
    // MARK - Insets
    @IBInspectable var leftInset: CGFloat = 1 { didSet { setNeedsDisplay() } }
    @IBInspectable var rightInset: CGFloat = 1 { didSet { setNeedsDisplay() } }
    @IBInspectable var topInset: CGFloat = 1 { didSet { setNeedsDisplay() } }
    @IBInspectable var bottomInset: CGFloat = 1 { didSet { setNeedsDisplay() } }
    
    // MARK - Data
    public var data: [Double] = [0, 2, 1, 3, 5, 4, 8, 6.5, 7.8, 9.2, 9.0, 5.5, 10]
    public var maxData = Double(CGFloat.leastNormalMagnitude)
    public var minData = Double(CGFloat.greatestFiniteMagnitude)
    
    public var delegate: SBLineViewDelegate?
    public var dataSource: SBLineViewDataSource?

    // MARK - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadView()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    // MARK: - Loading
    
    func loadView() {
        clipsToBounds = false
        layer.masksToBounds = false
    }
    
    public func loadRandomData() {
        data = [Double]()
        for _ in 0...25 {
            data.append(Double(arc4random_uniform(55)))
        }
        setNeedsDisplay()
    }
    
    private func loadFromDataSource() {
        var newData = [Double]()
        let numberOfPoints = (dataSource?.numberOfPointsIn(self))!
        for index in 0..<numberOfPoints {
            let dataPoint = dataSource?.lineView(self, valueAt: index)
            newData.append(dataPoint!)
        }
        data = newData
    }
    
    open func reloadData() {
        if dataSource != nil {
            loadFromDataSource()
        }
        setNeedsDisplay()
    }
    
    // MARK: - Drawing
    
    override open func draw(_ rect: CGRect) {
        //  Get min / max
        maxData = Double(CGFloat.leastNormalMagnitude)
        minData = Double(CGFloat.greatestFiniteMagnitude)
        for point in data {
            maxData = (point > maxData ? point : maxData)
            minData = (point < minData ? point : minData)
        }
        //  Draw Line
        curveControlOffset = ((frame.width - leftInset - rightInset - pointSize) / CGFloat(data.count - 1)) / 2
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(lineStrokeColor.cgColor)
        context.setLineWidth(lineStrokeWidth)
        var startPoint = CGPoint.zero
        if let firstPoint = data.first {
            startPoint = CGPoint(x: xCoordinate(for: 0), y: yCoordinate(for: firstPoint))
        }
        context.move(to: startPoint)
        var lastPoint: CGPoint?
        for (index, value) in data.enumerated() {
            let point = CGPoint(x: xCoordinate(for: index), y: yCoordinate(for: value))
            if let last = lastPoint {
                if curveLines {
                    let control1 = CGPoint(x: last.x + curveControlOffset, y: last.y)
                    let control2 = CGPoint(x: point.x - curveControlOffset, y: point.y)
                    context.addCurve(to: point, control1: control1, control2: control2)
                } else {
                    context.addLine(to: point)
                }
                
            }
            lastPoint = point
        }
        context.strokePath()
        
        //  Draw Points
        context.setFillColor(pointFillColor.cgColor)
        context.setStrokeColor(pointStrokeColor.cgColor)
        context.setLineWidth(pointStrokeWidth)
        for (index, value) in data.enumerated() {
            let point = CGPoint(x: xCoordinate(for: index), y: yCoordinate(for: value))
            context.fillEllipse(in: CGRect(origin: CGPoint(x: point.x - pointSize/2, y: point.y - pointSize/2), size: CGSize(width: pointSize, height: pointSize)))
            context.strokeEllipse(in: CGRect(origin: CGPoint(x: point.x - pointSize/2, y: point.y - pointSize/2), size: CGSize(width: pointSize, height: pointSize)))
        }
        context.strokePath()
    }
    
    // MARK: - Line Maths
    
    func stepWidth() -> CGFloat {
        return  (frame.width - leftInset - rightInset - pointSize) / CGFloat(data.count - 1)
    }
    
    func yCoordinate(for value: Double) -> CGFloat {
        let drawHeight = frame.height - topInset - bottomInset - pointSize
        let range = (maxData - minData)
        let rangeRelativeValue = (value - minData)
        let yCoordinate = drawHeight - (((CGFloat(rangeRelativeValue) * drawHeight) / CGFloat(range)) - topInset - (pointSize/2))
        return yCoordinate
    }
    
    func xCoordinate(for index: Int) -> CGFloat {
        return (CGFloat(index) * stepWidth()) + leftInset + (pointSize/2)
    }
    
    func index(for location: CGPoint) -> Int {
        return min(data.count-1, max(0, Int(round((location.x-leftInset-(pointSize/2)) / stepWidth()))))
    }
    
    //  MARK: - Touches
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let location = touches.first?.location(in: self) {
            touchLine.lineWidth = touchLineWidth
            touchLine.strokeColor = touchLineStrokeColor.cgColor
            touchLine.lineCap = kCALineCapSquare
            touchLine.fillColor = UIColor.clear.cgColor
            touchLine.path = verticalPath(for: location)
            layer.addSublayer(touchLine)
            
            valueLine.lineWidth = valueLineWidth
            valueLine.strokeColor = valueLineStrokeColor.cgColor
            valueLine.lineCap = kCALineCapSquare
            valueLine.lineDashPattern = [5, 5]
            valueLine.path = horizontalPath(for: location)
            layer.addSublayer(valueLine)
            
            touchPoint.lineWidth = touchPointStrokeWidth
            touchPoint.fillColor = touchPointFillColor.cgColor
            touchPoint.strokeColor = touchPointStrokeColor.cgColor
            touchPoint.path = pointPath(for: location)
            layer.addSublayer(touchPoint)
            
            if touchLineShowAcrossTop {
                let leftPath = UIBezierPath()
                leftPath.move(to: CGPoint(x: location.x, y: 0))
                leftPath.addLine(to: CGPoint(x: location.x-10, y: 0))
                
                touchLineTopLeft.lineWidth = touchLineWidth
                touchLineTopLeft.strokeColor = touchLineStrokeColor.cgColor
                touchLineTopLeft.lineCap = kCALineCapSquare
                touchLineTopLeft.path = leftPath.cgPath
                layer.addSublayer(touchLineTopLeft)
                
                let rightPath = UIBezierPath()
                rightPath.move(to: CGPoint(x: location.x+1, y: 0))
                rightPath.addLine(to: CGPoint(x: location.x+10, y: 0))
                
                touchLineTopRight.lineWidth = touchLineWidth
                touchLineTopRight.strokeColor = touchLineStrokeColor.cgColor
                touchLineTopRight.lineCap = kCALineCapSquare
                touchLineTopRight.path = rightPath.cgPath
                layer.addSublayer(touchLineTopRight)
                
                let nextRightPath = UIBezierPath()
                nextRightPath.move(to: CGPoint(x: location.x, y: 0))
                nextRightPath.addLine(to: CGPoint(x: bounds.width-rightInset, y: 0))
                
                let nextLeftPath = UIBezierPath()
                nextLeftPath.move(to: CGPoint(x: location.x+1, y: 0))
                nextLeftPath.addLine(to: CGPoint(x: leftInset, y: 0))
                
                let leftDuration: Double = 0.55 * Double((bounds.width - (location.x+1)) / bounds.width)
                let rightDuration: Double = 0.55 * Double(location.x / bounds.width)
                animate(layer: touchLineTopLeft, to: nextLeftPath.cgPath, duration: leftDuration)
                animate(layer: touchLineTopRight, to: nextRightPath.cgPath, duration: rightDuration)

            }
            
            let index = self.index(for: location)
            if let delegate = self.delegate {
                delegate.lineView(self, didSelect: data[index], at: index)
            }
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let location = touches.first?.location(in: self) {
//            touchLine.path = verticalPath(for: location)
//            touchLine.path = curvedVerticalPath(for: location)
            animateBounce(layer: touchLine, to:  (curvedTouchLine ? curvedVerticalPath(for: location) : verticalPath(for: location)))
            animate(layer: valueLine, to: horizontalPath(for: location))
            animate(layer: touchPoint, to: pointPath(for: location))
            let index = self.index(for: location)
            if let delegate = self.delegate {
                delegate.lineView(self, didSelect: data[index], at: index)
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchLine.removeFromSuperlayer()
        touchPoint.removeFromSuperlayer()
        valueLine.removeFromSuperlayer()
        if touchLineShowAcrossTop {
            touchLineTopRight.removeFromSuperlayer()
            touchLineTopLeft.removeFromSuperlayer()
        }
        if let delegate = self.delegate {
            delegate.lineViewTouchesEnded(self)
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchLine.removeFromSuperlayer()
        touchPoint.removeFromSuperlayer()
        valueLine.removeFromSuperlayer()
        if touchLineShowAcrossTop {
            touchLineTopRight.removeFromSuperlayer()
            touchLineTopLeft.removeFromSuperlayer()
        }
        if let delegate = self.delegate {
            delegate.lineViewTouchesEnded(self)
        }
    }

    // MARK: - Animations
    
    func animate(layer: CAShapeLayer, to path: CGPath, duration: CFTimeInterval) {
        if layer.path != path {
            let basicAnimation = CABasicAnimation(keyPath: "path")
            basicAnimation.duration = duration
            basicAnimation.fromValue = layer.path
            basicAnimation.toValue = path
            basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            layer.add(basicAnimation, forKey: "change path")
            layer.path = path
        }
    }
    
    func animate(layer: CAShapeLayer, to path: CGPath) {
        if layer.path != path {
            let basicAnimation = CABasicAnimation(keyPath: "path")
            basicAnimation.duration = 0.15
            basicAnimation.fromValue = layer.path
            basicAnimation.toValue = path
            basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            layer.add(basicAnimation, forKey: "change path")
            layer.path = path
        }
    }
    
    func animateBounce(layer: CAShapeLayer, to path: CGPath) {
        if layer.path != path {
            let basicAnimation = CABasicAnimation(keyPath: "path")
            basicAnimation.duration = 0.15
            basicAnimation.fromValue = layer.path
            basicAnimation.toValue = path
            basicAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            layer.add(basicAnimation, forKey: "change path")
            layer.path = path
        }
    }
    
    // MARK: - Paths
    
    func curvedVerticalPath(for location: CGPoint) -> CGPath {
        let topPoint = CGPoint(x: location.x, y: 0)
        let midPoint = CGPoint(x: xCoordinate(for: index(for: location)), y: yCoordinate(for: data[index(for: location)]))
        let bottomPoint = CGPoint(x: location.x, y: frame.height)
        
        let midControl1 = CGPoint(x: midPoint.x, y: topPoint.y + 30)
        let midControl2 = CGPoint(x: midPoint.x, y: midPoint.y - 30)

        let bottomControl1 = CGPoint(x: midPoint.x, y: midPoint.y + 10)
        let bottomControl2 = CGPoint(x: bottomPoint.x, y: bottomPoint.y - 10)
        
        let path = UIBezierPath()
        path.move(to: topPoint)
        path.addCurve(to: midPoint, controlPoint1: midControl1, controlPoint2: midControl2)
        path.addCurve(to: bottomPoint, controlPoint1: bottomControl1, controlPoint2: bottomControl2)
        return path.cgPath
    }
    
    func verticalPath(for location: CGPoint) -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: location.x, y: 0))
        path.addLine(to: CGPoint(x: location.x, y: frame.height))
        return path.cgPath
    }
    
    func horizontalPath(for location: CGPoint) -> CGPath {
        let point = CGPoint(x: xCoordinate(for: index(for: location)), y: yCoordinate(for: data[index(for: location)]))
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: point.y))
        path.addLine(to: CGPoint(x: frame.width, y: point.y))
        return path.cgPath
    }
    
    func pointPath(for location: CGPoint) -> CGPath {
        let point = CGPoint(x: xCoordinate(for: index(for: location)), y: yCoordinate(for: data[index(for: location)]))
        return CGPath(ellipseIn: CGRect(origin: CGPoint(x: point.x - touchPointSize/2, y: point.y - touchPointSize/2), size: CGSize(width: touchPointSize, height: touchPointSize)), transform: nil)
    }
}
