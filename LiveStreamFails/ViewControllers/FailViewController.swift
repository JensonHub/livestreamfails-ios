//
//  FailViewController.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-03-28.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import UIKit
import ESPullToRefresh

class FailViewController: UICollectionViewController {
    let cellIDEmpty = "EmptyFailCell"
    let cellID = "FailCell"
    
    lazy var controlView: ZFPlayerControlView = {
        let cv = ZFPlayerControlView()
        return cv
    }()
    
    lazy var player: ZFPlayerController = {
        let manager = ZFAVPlayerManager()
        let player = ZFPlayerController(scrollView: self.collectionView, playerManager: manager, containerViewTag: 100)
        player.controlView = self.controlView
        player.playerDisapperaPercent = 0.8;
        player.isWWANAutoPlay = true;
        player.playerDidToEnd = { asset in
            player.stopCurrentPlayingCell()
        }
        
        return player
    }()
    
    var posts = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    fileprivate func setup() {
        view.backgroundColor = UIColor.lsfBgColor()
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(FailCell.self, forCellWithReuseIdentifier: cellID)
        collectionView.es.addInfiniteScrolling {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.loadPosts(true, finish: {
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }
                        
                        strongSelf.collectionView.es.stopLoadingMore()
                        strongSelf.collectionView.reloadData()
                    }
                })
            }
        }
        
        navigationItem.title = "Fail"
        
        loadPosts(false, finish: {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.collectionView.reloadData()
            }
        })
    }
    
    private var currentPageIndex = 0
    private var isFetching = false
    private func loadPosts(_ isLoadMore: Bool = false, finish: (() -> Void)? = nil) {
        if isFetching {
            return
        }
        isFetching = true
        
        if isLoadMore {
            currentPageIndex += 1
        } else {
            currentPageIndex = 0
        }
        
        getPost(page: currentPageIndex, mode: .STANDARD, order: .HOT, timeFrame: .ALL, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.currentPageIndex -= 1
                }
            }, completion: { posts in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if posts.count == 0 {
                        strongSelf.currentPageIndex -= 1
                    }
                    
                    if strongSelf.currentPageIndex <= 0 {
                        strongSelf.currentPageIndex = 0
                        strongSelf.posts.removeAll()
                    }
                    
                    strongSelf.posts += posts
                    strongSelf.isFetching = false
                    
                    finish?()
                }
        })
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! FailCell
        let post = posts[indexPath.row]
        
        cell.initData(post: post)
        cell.playClickAction = { url, cover  in
            DispatchQueue.main.async { [weak self] in
                if let strongSelf = self, let url = url, let videoURL = URL(string: url) {
                    strongSelf.player.playTheIndexPath(indexPath, assetURL: videoURL, scrollToTop: false)
                    strongSelf.controlView.showTitle("", cover: cover, fullScreenMode: .landscape)
                }
            }
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12.0
    }
}

extension FailViewController: UICollectionViewDelegateFlowLayout {
    func heightForView(post: Post, width: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.attributedText = NSMutableAttributedString(string: post.name, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        label.sizeToFit()
        return label.frame.height
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item >= posts.count { return CGSize.zero}
        let textHeight = heightForView(post: posts[indexPath.item], width: view.frame.width - 16)
        return CGSize(width: view.frame.width, height: (view.frame.width * 9.0 / 16.0) + 59.0 + textHeight) // 59.0 = 40.0 + 18.0 + 1.0
    }
}

extension FailViewController {
    
    override var shouldAutorotate: Bool {
        return self.player.shouldAutorotate
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if self.player.isFullScreen {
            return .lightContent
        }
        return .default
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.player.isStatusBarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidEndDecelerating()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollView.zf_scrollViewDidEndDraggingWillDecelerate(decelerate)
    }
    
    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidScrollToTop()
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidScroll()
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewWillBeginDragging()
    }
}
