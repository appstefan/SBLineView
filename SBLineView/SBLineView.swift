//
//  SBLineChartView.swift
//  SBViews Demo
//
//  Created by Stefan Britton on 2016-09-25.
//  Copyright © 2016 Appstefan. All rights reserved.
//

import Foundation

public protocol SBLineViewDelegate {
    func lineView(_ lineView: SBLineView, didSelect value: Double, at index: Int)
    func lineViewTouchesEnded(_ lineView: SBLineView)
}

public protocol SBLineViewDataSource {
    func numberOfPointsIn(_ lineView: SBLineView) -> Int
    func lineView(_ lineView: SBLineView, valueFor index: Int) -> Double
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
    @IBInspectable var touchLineStrokeColor: UIColor = UIColor(red: 6/255.0, green: 104/255.0, blue: 179/255.0, alpha: 1.0)
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
    @IBInspectable var touchPointStrokeColor: UIColor = UIColor(red: 6/255.0, green: 104/255.0, blue: 179/255.0, alpha: 1.0)
    @IBInspectable var touchPointStrokeWidth: CGFloat = 1
    @IBInspectable var touchPointFillColor: UIColor = .clear
    
    // MARK - Insets
    @IBInspectable var leftInset: CGFloat = 0 { didSet { setNeedsDisplay() } }
    @IBInspectable var rightInset: CGFloat = 0 { didSet { setNeedsDisplay() } }
    @IBInspectable var topInset: CGFloat = 4 { didSet { setNeedsDisplay() } }
    @IBInspectable var bottomInset: CGFloat = 4 { didSet { setNeedsDisplay() } }
    
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
            let dataPoint = dataSource?.lineView(self, valueFor: index)
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
            startPoint = CGPoint(x: xCoordinate(0), y: yCoordinate(firstPoint))
        }
    
        context.move(to: startPoint)
        var lastPoint: CGPoint?
        for (index, value) in data.enumerated() {
            let point = CGPoint(x: xCoordinate(index), y: yCoordinate(value))
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
            let point = CGPoint(x: xCoordinate(index), y: yCoordinate(value))
            context.fillEllipse(in: CGRect(origin: CGPoint(x: point.x - pointSize/2, y: point.y - pointSize/2), size: CGSize(width: pointSize, height: pointSize)))
            context.strokeEllipse(in: CGRect(origin: CGPoint(x: point.x - pointSize/2, y: point.y - pointSize/2), size: CGSize(width: pointSize, height: pointSize)))
        }
        context.strokePath()
    }
    
    // MARK: - Line Maths
    
    func stepWidth() -> CGFloat {
        return  (frame.width - leftInset - rightInset - pointSize) / CGFloat(data.count - 1)
    }
    
    func yCoordinate(_ value: Double) -> CGFloat {
        let drawHeight = frame.height - topInset - bottomInset - pointSize
        let range = (maxData - minData)
        let rangeRelativeValue = (value - minData)
        let yCoordinate = drawHeight - (((CGFloat(rangeRelativeValue) * drawHeight) / CGFloat(range)) - topInset - (pointSize/2))
        return yCoordinate
    }
    
    func xCoordinate(_ index: Int) -> CGFloat {
        return (CGFloat(index) * stepWidth()) + leftInset + (pointSize/2)
    }
    
    func index(_ location: CGPoint) -> Int {
        return min(max(0, data.count-1), max(0, Int(round((location.x-leftInset-(pointSize/2)) / stepWidth()))))
    }
    
    //  MARK: - Touches
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let location = touches.first?.location(in: self) {
            touchLine.lineWidth = touchLineWidth
            touchLine.strokeColor = touchLineStrokeColor.cgColor
            touchLine.lineCap = kCALineCapSquare
            touchLine.fillColor = UIColor.clear.cgColor
            touchLine.path = verticalPath(location)
            layer.addSublayer(touchLine)
            
            valueLine.lineWidth = valueLineWidth
            valueLine.strokeColor = valueLineStrokeColor.cgColor
            valueLine.lineCap = kCALineCapSquare
            valueLine.lineDashPattern = [5, 5]
            valueLine.path = horizontalPath(location)
            layer.addSublayer(valueLine)
            
            touchPoint.lineWidth = touchPointStrokeWidth
            touchPoint.fillColor = touchPointFillColor.cgColor
            touchPoint.strokeColor = touchPointStrokeColor.cgColor
            touchPoint.path = pointPath(location)
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
                animate(touchLineTopLeft, to: nextLeftPath.cgPath, duration: leftDuration)
                animate(touchLineTopRight, to: nextRightPath.cgPath, duration: rightDuration)

            }
            
            let index = self.index(location)
            if let delegate = self.delegate, index < data.count {
                delegate.lineView(self, didSelect: data[index], at: index)
            }
        }
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if let location = touches.first?.location(in: self) {
            animateBounce(touchLine, to: verticalPath(location))
            animate(valueLine, to: horizontalPath(location))
            animate(touchPoint, to: pointPath(location))
            let index = self.index(location)
            if let delegate = self.delegate, index < data.count  {
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
    
    func animate(_ layer: CAShapeLayer, to path: CGPath, duration: CFTimeInterval) {
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
    
    func animate(_ layer: CAShapeLayer, to path: CGPath) {
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
    
    func animateBounce(_ layer: CAShapeLayer, to path: CGPath) {
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
    
    func verticalPath(_ location: CGPoint) -> CGPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: location.x, y: 0))
        // path.addLine(to: CGPoint(x: location.x, y: location.y - (touchPointSize/2)))
        // path.move(to: CGPoint(x: location.x, y: location.y + (touchPointSize/2)))
        path.addLine(to: CGPoint(x: location.x, y: frame.height))
        return path.cgPath
    }
    
    func horizontalPath(_ location: CGPoint) -> CGPath {
        let index = self.index(location)
        var point: CGPoint = .zero
        if index < data.count {
            point = CGPoint(x: xCoordinate(index), y: yCoordinate(data[index]))
        }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: point.y))
        path.addLine(to: CGPoint(x: frame.width, y: point.y))
        return path.cgPath
    }
    
    func pointPath(_ location: CGPoint) -> CGPath {
        let index = self.index(location)
        var point: CGPoint = .zero
        if index < data.count {
            point = CGPoint(x: xCoordinate(index), y: yCoordinate(data[index]))
        }
        return CGPath(ellipseIn: CGRect(origin: CGPoint(x: point.x - touchPointSize/2, y: point.y - touchPointSize/2), size: CGSize(width: touchPointSize, height: touchPointSize)), transform: nil)
    }
}
