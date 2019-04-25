//
//  HoverViewFlowLayout.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-04-23.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import UIKit

class HoverViewFlowLayout: UICollectionViewFlowLayout {
    var navHeight:CGFloat = 0
    
    init(navHeight:CGFloat) {
        super.init()
        self.navHeight = navHeight
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var superArray:[UICollectionViewLayoutAttributes] = super.layoutAttributesForElements(in: rect)!
        
        let copyArray = superArray
        for index in 0..<copyArray.count {
            let attributes = copyArray[index]
            if attributes.representedElementKind == UICollectionView.elementKindSectionHeader || attributes.representedElementKind == UICollectionView.elementKindSectionFooter {
                if let idx = superArray.index(of: attributes) {
                    superArray.remove(at: idx)
                }
            }
        }
        
        if let header = super.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath.init(item: 0, section: 0)) {
            superArray.append(header)
        }
        
        if let footer = super.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, at: IndexPath.init(item: 0, section: 0)) {
            superArray.append(footer)
        }
        
        for attributes in superArray {
            if attributes.indexPath.section == 0 {
                if attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
                    var rect = attributes.frame
                    if (self.collectionView?.contentOffset.y)! + self.navHeight - rect.size.height > rect.origin.y {
                        rect.origin.y = (self.collectionView?.contentOffset.y)! + self.navHeight - rect.size.height
                        attributes.frame = rect
                    }
                    attributes.zIndex = 5
                }

                if attributes.representedElementKind == UICollectionView.elementKindSectionFooter {
                    var rect = attributes.frame
                    if (self.collectionView?.contentOffset.y)! + self.navHeight > rect.origin.y {
                        rect.origin.y = (self.collectionView?.contentOffset.y)! + self.navHeight
                        attributes.frame = rect
                    }
                    attributes.zIndex = 10
                }
            }
        }
        return superArray
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
