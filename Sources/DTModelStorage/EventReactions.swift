//
//  UIReactions.swift
//  DTModelStorage
//
//  Created by Denys Telezhkin on 29.11.15.
//  Copyright © 2015 Denys Telezhkin. All rights reserved.
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

//swiftlint:disable large_tuple

/// Data holder for reaction
open class EventReaction {
    
    /// 3 arguments reaction block with all arguments type-erased.
    open var reaction : ((Any, Any, Any) -> Any)?
    
    let modelTypeCheckingBlock: ((Any) -> Bool)?
    
    public let supplementaryKind: String?
    
    /// Objective-C method signature
    public let methodSignature: String
    
    /// Creates reaction with `signature`.
    public init<View, ModelType, ReturnType>(viewType: View.Type,
                                            modelType: ModelType.Type,
                                            signature: String,
                                            supplementaryKind: String? = nil,
                                            _ block: @escaping (View, ModelType, IndexPath) -> ReturnType) {
        self.methodSignature = signature
        modelTypeCheckingBlock = nil
        self.supplementaryKind = supplementaryKind
        reaction = { view, model, indexPath in
            guard let model = model as? ModelType,
                let indexPath = indexPath as? IndexPath,
                let view = view as? View
                else {
                    return 0
            }
            return block(view, model, indexPath)
        }
    }
    
    /// Creates reaction with `signature`, `viewType` and `modelType`.
    public init<ModelType, ReturnType>(modelType: ModelType.Type, signature: String, supplementaryKind: String? = nil,
                                       _ block: @escaping (ModelType, IndexPath) -> ReturnType) {
        self.methodSignature = signature
        modelTypeCheckingBlock = { $0 is ModelType }
        self.supplementaryKind = supplementaryKind
        reaction = { model, indexPath, _ in
            guard let model = model as? ModelType,
                let indexPath = indexPath as? IndexPath else {
                    return 0
            }
            return block(model, indexPath)
        }
    }
    
    public init<ReturnType>(signature: String, _ block: @escaping () -> ReturnType) {
        self.methodSignature = signature
        supplementaryKind = nil
        modelTypeCheckingBlock = { _ in true }
        reaction = { _, _, _ in
            block()
        }
    }
    
    public init<Argument, ReturnType>(argument: Argument.Type, signature: String, _ block: @escaping (Argument) -> ReturnType) {
        self.methodSignature = signature
        modelTypeCheckingBlock = { _ in true }
        supplementaryKind = nil
        reaction = { argument, _, _ in
            guard let argument = argument as? Argument else {
                return 0
            }
            return block(argument)
        }
    }
    
    public init<ArgumentOne, ArgumentTwo, ReturnType>(argumentOne: ArgumentOne.Type,
                                                      argumentTwo: ArgumentTwo.Type,
                                                      signature: String,
                                                      _ block: @escaping (ArgumentOne, ArgumentTwo) -> ReturnType) {
        self.methodSignature = signature
        modelTypeCheckingBlock = { _ in true }
        supplementaryKind = nil
        reaction = { arg1, arg2, _ in
            guard let arg1 = arg1 as? ArgumentOne, let arg2 = arg2 as? ArgumentTwo else {
                return 0
            }
            return block(arg1, arg2)
        }
    }
    
    /// Performs reaction with `arguments`.
    open func performWithArguments(_ arguments: (Any, Any, Any)) -> Any {
        return reaction?(arguments.0, arguments.1, arguments.2) ?? 0
    }
}

/// Subclass of `EventReaction`, tuned to work with 4 arguments.
open class FourArgumentsEventReaction: EventReaction {
    
    /// Type-erased reaction with 4 arguments
    open var reaction4Arguments : ((Any, Any, Any, Any) -> Any)?
   
    @available(*, unavailable)
    public override init<ModelType, ReturnType>(modelType: ModelType.Type, signature: String, supplementaryKind: String? = nil, _ block: @escaping (ModelType, IndexPath) -> ReturnType) {
        super.init(modelType: modelType, signature: signature, block)
    }
    
    @available(*, unavailable)
    public override init<View, Argument, ReturnType>(viewType: View.Type, modelType: Argument.Type, signature: String, supplementaryKind: String? = nil, _ block: @escaping (View, Argument, IndexPath) -> ReturnType) {
        super.init(viewType: viewType, modelType: modelType, signature: signature, block)
    }
    
    @available(*, unavailable)
    open override func performWithArguments(_ arguments: (Any, Any, Any)) -> Any {
        fatalError("This method should not be called. Please call 4 argument version of this method")
    }
    
    @available(*, unavailable)
    public override init<Argument, ReturnType>(argument: Argument.Type, signature: String, _ block: @escaping (Argument) -> ReturnType) {
        fatalError("This initializer should not be called. Please Use EventReaction class instead")
    }
    
    @available(*, unavailable)
    public override init<ArgumentOne, ArgumentTwo, ReturnType>(argumentOne: ArgumentOne.Type,
                                                      argumentTwo: ArgumentTwo.Type,
                                                      signature: String,
                                                      _ block: @escaping (ArgumentOne, ArgumentTwo) -> ReturnType)
    {
        fatalError("This initializer should not be called. Please Use EventReaction class instead")
    }
    
    public init<View, ModelType, Argument, ReturnType>(_ viewType: View.Type,
                                                         modelType: ModelType.Type,
                                                         argument: Argument.Type,
                                                         signature: String,
                                                         _ block: @escaping (Argument, View, ModelType, IndexPath) -> ReturnType) {
        super.init(viewType: viewType, modelType: modelType, signature: signature) { _, _, _ in
            fatalError("This closure should not be called by FourArgumentsEventReaction")
        }
        reaction4Arguments = { argument, view, model, indexPath in
            guard let model = model as? ModelType,
                let indexPath = indexPath as? IndexPath,
                let argument = argument as? Argument,
                let view = view as? View else { return 0 }
            return block(argument, view, model, indexPath)
        }
    }
    
    /// Performs reaction with `arguments`.
    open func performWithArguments(_ arguments: (Any, Any, Any, Any)) -> Any {
        return reaction4Arguments?(arguments.0, arguments.1, arguments.2, arguments.3) ?? 0
    }
}

/// Subclass of `EventReaction`, tuned to work with 5 arguments.
open class FiveArgumentsEventReaction: EventReaction {
    
    /// Type-erased reaction with 5 arguments
    open var reaction5Arguments : ((Any, Any, Any, Any, Any) -> Any)?
    
    @available(*, unavailable)
    public override init<ModelType, ReturnType>(modelType: ModelType.Type, signature: String, supplementaryKind: String? = nil, _ block: @escaping (ModelType, IndexPath) -> ReturnType) {
        super.init(modelType: modelType, signature: signature, block)
    }
    
    @available(*, unavailable)
    public override init<View, Argument, ReturnType>(viewType: View.Type, modelType: Argument.Type, signature: String, supplementaryKind: String? = nil, _ block: @escaping (View, Argument, IndexPath) -> ReturnType) {
        super.init(viewType: viewType, modelType: modelType, signature: signature, block)
    }
    
    @available(*, unavailable)
    open override func performWithArguments(_ arguments: (Any, Any, Any)) -> Any {
        fatalError("This method should not be called. Please call 4 argument version of this method")
    }
    
    @available(*, unavailable)
    public override init<Argument, ReturnType>(argument: Argument.Type, signature: String, _ block: @escaping (Argument) -> ReturnType) {
        fatalError("This initializer should not be called. Please Use EventReaction class instead")
    }
    
    @available(*, unavailable)
    public override init<ArgumentOne, ArgumentTwo, ReturnType>(argumentOne: ArgumentOne.Type,
                                                      argumentTwo: ArgumentTwo.Type,
                                                      signature: String,
                                                      _ block: @escaping (ArgumentOne, ArgumentTwo) -> ReturnType)
    {
        fatalError("This initializer should not be called. Please Use EventReaction class instead")
    }
    
    public init<View, ModelType, ArgumentOne, ArgumentTwo, ReturnType>(_ viewType: View.Type,
                                                                       modelType: ModelType.Type,
                                                                       argumentOne: ArgumentOne.Type,
                                                                       argumentTwo: ArgumentTwo.Type,
                                                                       signature: String, _ block: @escaping (ArgumentOne, ArgumentTwo, View, ModelType, IndexPath) -> ReturnType) {
        super.init(viewType: viewType, modelType: modelType, signature: signature) { _, _, _ in
            fatalError("This closure should not be called by FiveArgumentsEventReaction")
        }
        reaction5Arguments = { argumentOne, argumentTwo, view, model, indexPath in
            guard let model = model as? ModelType,
                let indexPath = indexPath as? IndexPath,
                let argument1 = argumentOne as? ArgumentOne,
                let argument2 = argumentTwo as? ArgumentTwo,
                let view = view as? View else { return 0 }
            return block(argument1, argument2, view, model, indexPath)
        }
    }
    
    /// Performs reaction with `arguments`.
    open func performWithArguments(_ arguments: (Any, Any, Any, Any, Any)) -> Any {
        return reaction5Arguments?(arguments.0, arguments.1, arguments.2, arguments.3, arguments.4) ?? 0
    }
}

public extension EventReaction {
    /// Searches for reaction using specified parameters.
    static func unmappedReaction(from reactions: [EventReaction],
                         signature: String,
                         forModel model: Any,
                         supplementaryKind: String? = nil) -> EventReaction? {
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return nil }
        return reactions.first { reaction in
            reaction.methodSignature == signature &&
                (reaction.modelTypeCheckingBlock?(unwrappedModel) ?? false) &&
                reaction.supplementaryKind == supplementaryKind
        }
    }
    
    static func performUnmappedReaction(from reactions: [EventReaction],
                                        _ signature: String) -> Any? {
        unmappedReaction(from: reactions, signature: signature, forModel: Void())?.performWithArguments((0, 0, 0))
    }
    
    static func performUnmappedReaction<T>(from reactions: [EventReaction], _ signature: String, argument: T) -> Any? {
        unmappedReaction(from: reactions, signature: signature, forModel: argument)?.performWithArguments((argument, 0, 0))
    }
    
    static func performUnmappedReaction<T, U>(from reactions: [EventReaction], _ signature: String, argumentOne: T, argumentTwo: U, supplementaryKind: String? = nil) -> Any? {
        unmappedReaction(from: reactions, signature: signature, forModel: argumentOne, supplementaryKind: supplementaryKind)?.performWithArguments((argumentOne, argumentTwo, 0))
    }
    
    /// Searches for reaction using specified parameters.
    static func reaction(from mappings: [ViewModelMappingProtocol],
                         signature: String,
                         forModel model: Any,
                         at indexPath: IndexPath,
                         view: UIView?,
                         supplementaryKind: String? = nil) -> EventReaction? {
        guard let unwrappedModel = RuntimeHelper.recursivelyUnwrapAnyValue(model) else { return nil }
        return mappings.first(where: { mapping in
            // Find all compatible mappings
            mapping.modelTypeCheckingBlock(unwrappedModel) &&
            (view?.isKind(of: mapping.viewClass) ?? true) &&
            mapping.condition.isCompatible(with: indexPath, model: unwrappedModel) &&
                mapping.reactions.contains { $0.methodSignature == signature }
        })?.reactions.first(where: { $0.methodSignature == signature && $0.supplementaryKind == supplementaryKind })
    }
    
    /// Performs reaction of `type`, `signature`, with `view`, `model` in `location`.
    static func performReaction(from mappings: [ViewModelMappingProtocol], signature: String, view: Any?, model: Any, location: IndexPath, supplementaryKind: String? = nil) -> Any {
        guard let reaction = reaction(from: mappings, signature: signature, forModel: model, at: location, view: view as? UIView, supplementaryKind: supplementaryKind) else {
            return 0
        }
        return reaction.performWithArguments((view ?? 0, model, location))
    }
    
    //swiftlint:disable function_parameter_count
    /// Performs reaction of `type`, `signature`, with `argument`, `view`, `model` in `location`.
    static func perform4ArgumentsReaction(from mappings: [ViewModelMappingProtocol], signature: String, argument: Any, view: Any?, model: Any, location: IndexPath) -> Any {
        guard let reaction = reaction(from: mappings, signature: signature, forModel: model, at: location, view: view as? UIView) as? FourArgumentsEventReaction else { return 0 }
        return reaction.performWithArguments((argument, view ?? 0, model, location))
    }
    
    /// Performs reaction of `type`, `signature`, with `firstArgument`, `secondArgument`, `view`, `model` in `location`.
    static func perform5ArgumentsReaction(from mappings: [ViewModelMappingProtocol], signature: String, firstArgument: Any, secondArgument: Any, view: Any?, model: Any, location: IndexPath) -> Any {
        guard let reaction = reaction(from: mappings, signature: signature, forModel: model, at: location, view: view as? UIView) as? FiveArgumentsEventReaction else { return 0 }
        return reaction.performWithArguments((firstArgument, secondArgument, view ?? 0, model, location))
    }
}
