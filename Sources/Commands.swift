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
    var presenter:UIViewController? { get set }
    var window:UIWindow? { get set }
}

public class URLNavigationContext:URLContext{
    public var URL:URLConvertible?
    public var values:[String: AnyObject]?
    public var wrap: Bool = false
    public var presenter:UIViewController?
    public var window:UIWindow?
}

/**
 *  URLNavigableBuilder
 */

protocol URLNavigableBuilder{
    func buildNavigable(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable
}

class URLNavigableBuilderWithClass:URLNavigableBuilder{
    let navigable: URLNavigable.Type
    
    internal init(navigable: URLNavigable.Type){
        self.navigable = navigable
    }
    
    func buildNavigable(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable{
        return self.navigable.init(URL: URL, values: values)!
    }
    
}

class URLNavigableBuilderWithStoryboard:URLNavigableBuilder{
    let storyboard:String
    let view:String
    
    internal init(storyboard:String,view:String){
        self.storyboard = storyboard
        self.view = view
    }
    
    func buildNavigable(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable{
        // here build storiboard
        return UIViewController() as! URLNavigable
    }
}

class URLNavigableBuilderWithBlock:URLNavigableBuilder{
    let builderBlock:() -> URLNavigable
    
    internal init(builderBlock:() -> URLNavigable){
        self.builderBlock = builderBlock
    }
    
    func buildNavigable(URL: URLConvertible, values: [String: AnyObject]) -> URLNavigable{
        return self.builderBlock()
    }
}


/**
 *  URLCommand
 */


public class URLCommandBase:URLCommand{
    
    func execute(context:URLContext){
        fatalError("Subclasses need to implement the `execute(context:URLContext)` method.")
    }
}

public class URLBlockCommand:URLCommandBase{
    
    public typealias URLBlockCommandHandler = (URL: URLConvertible, values: [String: AnyObject]) -> Void
    
    private var blockHandler:URLBlockCommandHandler
    
    internal init(block:URLBlockCommandHandler){
        self.blockHandler = block
    }
    
    override func execute(context:URLContext){
        // should check if exist
        self.blockHandler(URL:context.URL!, values:context.values!)
    }
    
}

public class URLPushCommand:URLCommandBase{
    override func execute(context:URLContext){
        // should check if exist
        let dest:URLNavigable = (self.destinationBuilder?.buildNavigable(context.URL!, values: context.values!))!
        context.presenter?.navigationController?.pushViewController(dest as! UIViewController, animated: true)
    }
}
