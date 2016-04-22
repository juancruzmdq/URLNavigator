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

public protocol URLContext {
    var URL:URLConvertible { get set }
    var values:[String: AnyObject] { get set }
    var wrap:Bool { get set }
    var animated : Bool { get set }
    var presenter:UIViewController? { get set }
    var window:UIWindow? { get set }
}

public class URLContextNavigation:URLContext{
    public var URL:URLConvertible
    public var values:[String: AnyObject]
    public var wrap: Bool = false
    public var animated : Bool = true
    public var presenter:UIViewController?
    public var window:UIWindow?
    
    public init(URL:URLConvertible, values:[String: AnyObject]){
        self.URL = URL
        self.values = values
    }
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

public protocol URLCommand {
    func execute(context:URLContext) -> URLNavigable?
}

public class URLCommandBase:URLCommand{
    public func execute(context:URLContext) -> URLNavigable?{
        fatalError("Subclasses need to implement the `execute(context:URLContext)` method.")
    }
}

public class URLCommandNavigation:URLCommandBase{
    var destinationBuilder:URLNavigableBuilder
    public init(_ destinationBuilder:URLNavigableBuilder) {
        self.destinationBuilder = destinationBuilder
    }
}

public class URLCommandBlock:URLCommandBase{
    
    public typealias URLBlockCommandHandler = (URL: URLConvertible, values: [String: AnyObject]) -> Void

    private var blockHandler:URLBlockCommandHandler
    
    public init(_ block:URLBlockCommandHandler){
        self.blockHandler = block
    }
    
    override public func execute(context:URLContext) -> URLNavigable?{
        self.blockHandler(URL:context.URL, values:context.values)
        return nil
    }
    
}

public class URLCommandNavigationPush:URLCommandNavigation{

    override public func execute(context:URLContext) -> URLNavigable?{
        // should check if exist
        var navigationController:UINavigationController?
        
        // Try tu use the navigator in the context
        if context.presenter != nil && context.presenter is UINavigationController {
            navigationController = context.presenter as? UINavigationController
        }
        
        // if there are no navigator in the context, try to deduce it
        if navigationController == nil{
            navigationController = UIViewController.topMostViewController()?.navigationController
        }
        
        if navigationController != nil {
            // Build destination ViewController
            let dest:URLNavigable = (self.destinationBuilder.buildNavigable(context.URL, values: context.values))
            
            // Try to push it
            navigationController?.pushViewController(dest as! UIViewController, animated: context.animated)
            
            return dest
        }
        
        return nil
    }
}

public class URLCommandNavigationPresent:URLCommandNavigation{
    
    override public func execute(context:URLContext) -> URLNavigable?{
        // should check if exist
        var controller:UIViewController?
        
        // Try tu use the navigator in the context
        if context.presenter != nil {
            controller = context.presenter
        }
        
        // if there are no navigator in the context, try to deduce it
        if controller == nil{
            controller = UIViewController.topMostViewController()
        }
        
        if controller != nil {
            // Build destination ViewController
            guard let buildedController:URLNavigable? = self.destinationBuilder.buildNavigable(context.URL, values: context.values) else{
                return nil
            }
            
            // Try to Present it
            controller?.presentViewController(buildedController as! UIViewController, animated: context.animated, completion: nil)
            
            return buildedController
        }
        
        return nil
    }
}

public class URLCommandNavigationMakeRoot:URLCommandNavigation{
    
    override public func execute(context:URLContext) -> URLNavigable?{
        // build destination conroller
        guard let buildedController:URLNavigable? = self.destinationBuilder.buildNavigable(context.URL, values: context.values) else{
            return nil
        }
        
        // By default present the builded controller
        var presentController:UIViewController = buildedController as! UIViewController
        
        // If need to wrap it, create and present the navigation bar
        if context.wrap && !presentController.isKindOfClass(UINavigationController){
            let navigationController = UINavigationController(rootViewController: presentController)
            presentController = navigationController
        }
        
        // create snapshot to make animated transition
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