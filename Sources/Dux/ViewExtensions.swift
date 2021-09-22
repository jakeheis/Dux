//
//  ViewExtensions.swift
//  Dux
//
//  Created by Jake Heiser on 9/22/21.
//

import SwiftUI

extension View {
    public func dux<Tags: DuxTags>(isActive: Bool, tags: Tags.Type, delegate: DuxDelegate? = nil) -> some View {
        GuidableView(isActive: isActive, tags: tags, delegate: delegate) {
            self
        }
    }

    public func duxTag<T: DuxTags>(_ tag: T) -> some View {
        anchorPreference(key: DuxTagPreferenceKey.self, value: .bounds, transform: { anchor in
            return [tag.key(): DuxTagInfo(tag: tag.key(), anchor: anchor, callout: tag.createCallout())]
        })
    }
    
    public func duxExtensionTag<T: DuxTags>(_ tag: T, edge: Edge, size: CGFloat = 100) -> some View {
        let width: CGFloat? = (edge == .leading || edge == .trailing) ? size : nil
        let height: CGFloat? = (edge == .top || edge == .bottom) ? size : nil
        
        let alignment: Alignment
        switch edge {
        case .top: alignment = .top
        case .leading: alignment = .leading
        case .trailing: alignment = .trailing
        case .bottom: alignment = .bottom
        }
        
        let overlayView = Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(width: width, height: height)
            .duxTag(tag)
            .padding(Edge.Set(edge), -size)
        return overlay(overlayView, alignment: alignment)
    }
    
    public func stopDux(_ dux: Dux, onLink navigationLink: Bool) -> some View {
        onChange(of: navigationLink, perform: { shown in
            if shown {
                dux.stop()
            }
        })
    }
    
    public func stopDux<V: Hashable>(_ dux: Dux, onTag navigationTag: V, selection: V) -> some View {
        onChange(of: selection, perform: { value in
            if navigationTag == value {
                dux.stop()
            }
        })
    }
}

