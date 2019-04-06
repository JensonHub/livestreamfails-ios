//
//  FailCell.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-03-28.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher

class FailCell: UICollectionViewCell {
    
    let profileSize: CGFloat = 40.0
    lazy var userProfile: UIImageView = {
        let image = UIImageView(image: UIImage(named: "defaultUser"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = profileSize/2
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "bgView"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.tag = 100
        image.isUserInteractionEnabled = true
        return image
    }()
    
    lazy var playBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "play"), for: .normal)
        button.addTarget(self, action: #selector(FailCell.playBtnClick), for: .touchUpInside)
        return button
    }()
    
    var streamer:Streamer?
    var postDetail:PostDetail?
    
    var playClickAction: ((_ url: String?, _ cover: UIImage?) -> Void)?
    
    @objc func playBtnClick() {
        println("playBtn Click")
        self.playClickAction?(postDetail?.videoURL, imageView.image)
    }
    
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
        
        usernameLabel.text = ""
        userProfile.image = UIImage(named: "defaultUser")
    }
    
    func initSubViews() {
        addSubview(userProfile)
        userProfile.snp.makeConstraints { (make) in
            make.height.width.equalTo(profileSize)
            make.top.equalTo(self.snp.top).offset(4)
            make.left.equalTo(self.snp.left).offset(4)
        }
        
        addSubview(usernameLabel)
        usernameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(userProfile.snp.right).offset(6)
            make.width.equalTo(120)
            make.centerY.equalTo(userProfile.snp.centerY)
        }

        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(userProfile.snp.bottom).offset(6)
            make.width.equalTo(self)
            make.height.equalTo(imageView.snp.width).multipliedBy(9.0 / 16.0)
        }

        imageView.addSubview(playBtn)
        playBtn.snp.makeConstraints { (make) in
            make.center.equalTo(imageView.snp.center)
            make.width.height.equalTo(44)
        }
    }
    
    func initData(post: Post) {
        if !post.thumbnailURL.isEmpty {
            imageView.kf.setImage(with: URL(string: post.thumbnailURL))
        }
        
        getStreamerDetail(streamerID: post.streamer, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
        }, completion: { streamer in
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.streamer = streamer
                
                strongSelf.usernameLabel.text = streamer.name
                if !streamer.avatarURL.isEmpty {
                    strongSelf.userProfile.kf.setImage(with: URL(string: streamer.avatarURL))
                }
            }
        })
        
        getPostDetail(postID: post.postID, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
        }, completion: { postDetail in
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.postDetail = postDetail
            }
        })
    }
}
