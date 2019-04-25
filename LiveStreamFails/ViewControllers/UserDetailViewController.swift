//
//  UserDetailViewController.swift
//  LiveStreamFails
//
//  Created by Jenson Chen on 2019-04-13.
//  Copyright © 2019 Jenson Chen. All rights reserved.
//

import UIKit
import ESPullToRefresh

let USER_INFO_HEADER:String = "UserInfoHeader"
let FAIL_CELL:String = "UserFailCell"

var USER_INFO_HEADER_HEIGHT:CGFloat = 270 + UIApplication.shared.statusBarFrame.height

class UserDetailViewController: UIViewController {

    var user: String?
    var streamer: Streamer?
    var posts = [Post]()
    
    var userInfoHeader:UserInfoHeader?
    var collectionView:UICollectionView?
    
    lazy var controlView: ZFPlayerControlView = {
        let cv = ZFPlayerControlView()
        return cv
    }()
    
    var player: ZFPlayerController?
    
    init(user:String) {
        super.init(nibName: nil, bundle: nil)
        
        self.user = user
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(UIImage.init(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage.init()
        
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.clear]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUserInfo()
        initSubView()
    }
    
    fileprivate func initSubView() {
        let leftButton = UIBarButtonItem.init(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(close))
        leftButton.tintColor = .white
        navigationItem.leftBarButtonItem = leftButton;
        
        view.backgroundColor = UIColor.lsfBgColor()
        
        let layout = HoverViewFlowLayout.init(navHeight: safeAreaTopHeight)
        collectionView = UICollectionView.init(frame: UIScreen.main.bounds, collectionViewLayout: layout)
        collectionView?.backgroundColor = UIColor.lsfBgColor()
        if #available(iOS 11.0, *) {
            collectionView?.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        collectionView?.alwaysBounceVertical = true
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.register(UserInfoHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: USER_INFO_HEADER)
        collectionView?.register(UserFailCell.self, forCellWithReuseIdentifier: FAIL_CELL)
        self.view.addSubview(collectionView!)
        
        collectionView?.es.addInfiniteScrolling {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.loadPosts(true, finish: {
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }
                        
                        strongSelf.collectionView?.es.stopLoadingMore()
                        strongSelf.collectionView?.reloadSections(IndexSet.init(integer: 1))
                    }
                })
            }
        }
        
        player = {
            let manager = ZFAVPlayerManager()
            player = ZFPlayerController(scrollView: self.collectionView!, playerManager: manager, containerViewTag: 100)
            player?.controlView = self.controlView
            player?.playerDisapperaPercent = 0.8;
            player?.isWWANAutoPlay = true;
            player?.playerDidToEnd = { [weak self] asset in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.player?.stopCurrentPlayingCell()
                }
            }
            return player
        }()
    }
    
    fileprivate func initUserInfo() {
        loadUserData()
        loadPosts(false, finish: {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.collectionView?.reloadSections(IndexSet.init(integer: 1))
            }
        })
    }
    
    private func loadUserData() {
        getStreamerDetail(streamerID: user ?? "", failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
            }, completion: { streamer in
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.streamer = streamer
                    strongSelf.navigationItem.title = strongSelf.streamer?.name ?? ""
                    strongSelf.collectionView?.reloadSections(IndexSet.init(integer: 0))
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
        
        getStreamerPost(page: currentPageIndex, order: .HOT, timeFrame: .ALL, streamer: user ?? "", failureHandler: { [weak self] reason, errorMessage in
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
                    
                    if posts.count == 0 && strongSelf.currentPageIndex > 1 {
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
    
    func navagationBarHeight()->CGFloat {
        return navigationController?.navigationBar.frame.size.height ?? 0;
    }
    
    @objc func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension UserDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 {
            return posts.count
        }
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FAIL_CELL, for: indexPath) as! UserFailCell
        let post = posts[indexPath.row]
        cell.initData(post: post)
        cell.playClickAction = { url, cover in
            DispatchQueue.main.async { [weak self] in
                if let strongSelf = self, let url = url, let videoURL = URL(string: url) {
                    strongSelf.player?.playTheIndexPath(indexPath, assetURL: videoURL, scrollToTop: false)
                    strongSelf.controlView.showTitle("", cover: cover, fullScreenMode: .landscape)
                }
            }
        }
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if indexPath.section == 0 {
            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: USER_INFO_HEADER, for: indexPath) as! UserInfoHeader
                userInfoHeader = header
                if let streamer = streamer {
                    header.initData(streamer: streamer)
                }
                return header
            }
        }
        return UICollectionReusableView.init()
    }
}

extension UserDetailViewController: UICollectionViewDelegateFlowLayout {
    func heightForView(post: Post, width: CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.attributedText = NSMutableAttributedString(string: post.name, attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 14)])
        label.sizeToFit()
        return label.frame.height
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section == 0 ? CGSize.init(width: UIScreen.main.bounds.size.width, height:USER_INFO_HEADER_HEIGHT) : .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.item >= posts.count { return CGSize.zero}
        let textHeight = heightForView(post: posts[indexPath.item], width: view.frame.width - 16)
        return CGSize(width: view.frame.width, height: (view.frame.width * 9.0 / 16.0) + 35.0 + textHeight)
    }
}

extension UserDetailViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidScroll()

        let offsetY = scrollView.contentOffset.y
        if offsetY < 0 {
            userInfoHeader?.overScrollAction(offsetY: offsetY)
        } else {
            userInfoHeader?.scrollToTopAction(offsetY: offsetY)
            updateNavigationTitle(offsetY: offsetY)
        }
    }

    func updateNavigationTitle(offsetY:CGFloat) {
        if USER_INFO_HEADER_HEIGHT - self.navagationBarHeight() * 2 > offsetY {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.clear]
        }

        if USER_INFO_HEADER_HEIGHT - self.navagationBarHeight() * 2 < offsetY && offsetY < USER_INFO_HEADER_HEIGHT - self.navagationBarHeight() {
            let alphaRatio = 1.0 - (USER_INFO_HEADER_HEIGHT - self.navagationBarHeight() - offsetY) / self.navagationBarHeight()
            let color = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: alphaRatio)
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: color]
        }

        if offsetY > USER_INFO_HEADER_HEIGHT - self.navagationBarHeight() {
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidEndDecelerating()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollView.zf_scrollViewDidEndDraggingWillDecelerate(decelerate)
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewDidScrollToTop()
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.zf_scrollViewWillBeginDragging()
    }
}

extension UserDetailViewController {
    override var shouldAutorotate: Bool {
        return self.player?.shouldAutorotate ?? false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if self.player?.isFullScreen ?? false {
            return .lightContent
        }
        return .default
    }
    
    override var prefersStatusBarHidden: Bool {
        return self.player?.isStatusBarHidden ?? false
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
}
