//
//  UserFailCell.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-04-13.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import UIKit

class UserFailCell: UICollectionViewCell {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .boldSystemFont(ofSize: 15)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .boldSystemFont(ofSize: 10)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
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
    
    var postDetail: PostDetail?
    
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
        
        infoLabel.text = ""
        titleLabel.text = ""
    }
    
    func initSubViews() {
        backgroundColor = .white        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.top).offset(8)
            make.left.equalTo(self.snp.left).offset(8)
            make.right.equalTo(self.snp.right).offset(-8)
        }
        
        addSubview(infoLabel)
        infoLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(self.snp.left).offset(8)
            make.right.equalTo(self.snp.right).offset(-8)
        }
        
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.equalTo(infoLabel.snp.bottom).offset(6)
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
        
        infoLabel.text = post.game + " . " + post.point + " . " + post.date
        titleLabel.text = post.name
        
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
