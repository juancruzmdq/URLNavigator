//
//  URLCommand.swift
//  URLNavigator
//
//  Created by Juan Cruz Ghigliani on 21/4/16.
//  Copyright © 2016 Suyeol Jeon. All rights reserved.
//

////////////////////////////////////////////////////////////////////////////////
// MARK: Imports
import Foundation

////////////////////////////////////////////////////////////////////////////////
// MARK: Types

/**
 *  URLContext
 */

protocol URLContext {
    var URL:URLConvertible? { get set }
    var values:[String: AnyObject]? { get set }
    var wrap:Bool { get set }
    var animated : Bool { get set }
    var presenter:UIViewController? { get set }
    var window:UIWindow? { get set }
}

public class URLNavigationContext:URLContext{
    public var URL:URLConvertible?
    public var values:[String: AnyObject]?
    public var wrap: Bool = false
    public var animated : Bool = true
    public var presenter:UIViewController?
    public var window:UIWindow?
}

/**
 *  URLNavigableBuilder
 */

public protocol URLNavigableBuilder{
    func buildNavigable(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable
}

public class URLNavigableBuilderWithClass:URLNavigableBuilder{
    let navigable: URLNavigable.Type
    
    public init(_ navigable: URLNavigable.Type){
        self.navigable = navigable
    }
    
    public func buildNavigable(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable{
        return self.navigable.init(URL: URL, values: values)!
    }
    
}

public class URLNavigableBuilderWithStoryboard:URLNavigableBuilder{
    let storyboard:String
    let viewIdentifier:String
    
    public init(storyboard:String,viewIdentifier:String){
        self.storyboard = storyboard
        self.viewIdentifier = viewIdentifier
    }
    
    public func buildNavigable(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable{
        let storyboard = UIStoryboard(name: self.storyboard, bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier(self.viewIdentifier)
        return vc as! URLNavigable
    }
}

public class URLNavigableBuilderWithBlock:URLNavigableBuilder{
    let builderBlock:(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable
    
    public init(builderBlock:(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable){
        self.builderBlock = builderBlock
    }

    public func buildNavigable(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable{
        return self.builderBlock(URL:URL, values: values)
    }
}


/**
 *  URLCommand
 */

protocol URLCommand {
    func execute(context:URLContext) -> URLNavigable?
}

public class URLCommandBase:URLCommand{
    func execute(context:URLContext) -> URLNavigable?{
        fatalError("Subclasses need to implement the `execute(context:URLContext)` method.")
    }
}

public class URLNavigationCommand:URLCommandBase{
    var destinationBuilder:URLNavigableBuilder
    public init(_ destinationBuilder:URLNavigableBuilder) {
        self.destinationBuilder = destinationBuilder
    }
}

public class URLBlockCommand:URLCommandBase{
    
    public typealias URLBlockCommandHandler = (URL: URLConvertible, values: [String: AnyObject]) -> Void

    private var blockHandler:URLBlockCommandHandler
    
    public init(_ block:URLBlockCommandHandler){
        self.blockHandler = block
    }
    
    override func execute(context:URLContext) -> URLNavigable?{
        // should check if exist
        self.blockHandler(URL:context.URL!, values:context.values!)
        return nil
    }
    
}

public class URLPushCommand:URLNavigationCommand{

    override func execute(context:URLContext) -> URLNavigable?{
        // should check if exist
        let dest:URLNavigable = (self.destinationBuilder.buildNavigable(context.URL!, values: context.values!))
        (context.presenter as? UINavigationController)!.pushViewController(dest as! UIViewController, animated: context.animated)
        return dest
    }
}

public class URLPresentCommand:URLNavigationCommand{
    
    override func execute(context:URLContext) -> URLNavigable?{
        // should check if exist
        let dest:URLNavigable = (self.destinationBuilder.buildNavigable(context.URL!, values: context.values!))
        context.presenter?.presentViewController(dest as! UIViewController, animated: context.animated, completion: nil)
        return dest
    }
}

public class URLMakeRootCommand:URLNavigationCommand{
    
    override func execute(context:URLContext) -> URLNavigable?{
        // should check if exist
        let buildedController = self.destinationBuilder.buildNavigable(context.URL!, values: context.values!)
        
        var presentController:UIViewController = buildedController as! UIViewController
        
        if context.wrap && !presentController.isKindOfClass(UINavigationController){
            let navigationController = UINavigationController(rootViewController: presentController)
            presentController = navigationController
        }
        
        let snapShot:UIView = context.window!.snapshotViewAfterScreenUpdates(true)
        
        presentController.view.addSubview(snapShot)
        context.window!.rootViewController = presentController;
        UIView.animateWithDuration(context.animated ? 0.6 : 0 ,
                                   delay: 0,
                                   options: UIViewAnimationOptions.CurveEaseInOut,
                                   animations: { () -> Void in
                                    snapShot.layer.opacity = 0;
        }) { (finished) -> Void in
            snapShot.removeFromSuperview()
        }
        
        return buildedController
        
        
    }
}