//
//  VideoCollectionViewCell.swift
//  VideoTrimmer
//
//  Created by Albert Bori on 10/15/18.
//  Copyright © 2018 Albert Bori. All rights reserved.
//

import UIKit

class VideoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var data: CellData!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
