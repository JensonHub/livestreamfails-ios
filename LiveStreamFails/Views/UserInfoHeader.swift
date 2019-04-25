//
//  UserInfoHeader.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-04-13.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import UIKit

class UserInfoHeader: UICollectionReusableView {
    
    var streamer: Streamer?
    var containerView:UIView = UIView.init()
    
    let avatarRadius:CGFloat = 80
    lazy var avatarView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "defaultUser"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.isUserInteractionEnabled = true
        return image
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .boldSystemFont(ofSize: 15)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        initSubViews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nameLabel.text = ""
        avatarView.image = UIImage(named: "defaultUser")
    }
    
    func initSubViews() {
        self.backgroundColor = UIColor.lsfNavgationBarColor()

        containerView.frame = self.bounds
        self.addSubview(containerView)
        
        avatarView.layer.cornerRadius = avatarRadius
        containerView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.top.equalTo(self).offset(15 + 44 + statusBarHeight)
            make.centerX.equalTo(self)
            make.width.height.equalTo(avatarRadius * 2)
        }
        
        let paddingLayer = CALayer.init()
        paddingLayer.frame = CGRect.init(x: 0, y: 0, width: avatarRadius * 2, height: avatarRadius * 2)
        paddingLayer.borderColor = ColorWhiteAlpha20.cgColor
        paddingLayer.borderWidth = 2
        paddingLayer.cornerRadius = avatarRadius
        avatarView.layer.addSublayer(paddingLayer)
        
        containerView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self.avatarView.snp.bottom).offset(10)
            make.centerX.equalTo(self)
        }
    }
    
    func initData(streamer: Streamer) {
        self.streamer = streamer
        
        nameLabel.text = streamer.name
        if !streamer.avatarURL.isEmpty {
            avatarView.kf.setImage(with: URL(string: streamer.avatarURL))
        }
    }
}

extension UserInfoHeader {

    func overScrollAction(offsetY:CGFloat)  {
        let scaleRatio:CGFloat = abs(offsetY) / infoHeaderHeight
        let overScaleHeight:CGFloat = (infoHeaderHeight * scaleRatio) / 2.0
        self.transform = CGAffineTransform.init(scaleX: scaleRatio + 1.0, y: scaleRatio + 1.0).concatenating(CGAffineTransform.init(translationX: 0, y: -overScaleHeight))
    }
    
    func scrollToTopAction(offsetY:CGFloat) {
        let alphaRatio = offsetY/(infoHeaderHeight - 44.0 - statusBarHeight)
        containerView.alpha = 1.0 - alphaRatio
    }
    
}
