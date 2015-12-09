import UIKit

class SettingController: UIViewController, UIWebViewDelegate  {
    var _webView: UIWebView! //Webビュー
    
    private var settingButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loadAddressURL()
        settingbutton()
        
    }
    func loadAddressURL(){
        
        //Webビューの生成
        _webView = makeWebView(CGRectMake(0, 20,
            self.view.frame.width, self.view.frame.height-20))
        self.view.addSubview(_webView)
        
        //インジケータの表示(2)
        UIApplication.sharedApplication(
            ).networkActivityIndicatorVisible = true
        
        //HTMLの読み込み(3)
        let url: NSURL = NSURL(string: "http://www.yahoo.co.jp")!
        let urlRequest: NSURLRequest = NSURLRequest(URL: url)
        _webView.loadRequest(urlRequest)
        
    }
    //Webビューの生成
    func makeWebView(frame: CGRect) -> UIWebView {
        //Webビューの生成(1)
        let webView = UIWebView()
        webView.frame = frame
        webView.backgroundColor = UIColor.blackColor()
        webView.scalesPageToFit = true //ページをフィットさせるかどうか
        webView.autoresizingMask = [   //ビューサイズの自動調整
            UIViewAutoresizing.FlexibleRightMargin,
            UIViewAutoresizing.FlexibleTopMargin,
            UIViewAutoresizing.FlexibleLeftMargin,
            UIViewAutoresizing.FlexibleBottomMargin,
            UIViewAutoresizing.FlexibleWidth,
            UIViewAutoresizing.FlexibleHeight]
        webView.delegate = self
        return webView
    }
    func webView(webView: UIWebView,
        shouldStartLoadWithRequest: NSURLRequest,
        navigationType: UIWebViewNavigationType) -> Bool {
            //クリック時
            if navigationType == UIWebViewNavigationType.LinkClicked ||
                navigationType == UIWebViewNavigationType.FormSubmitted {
                    //通信中の時は再度URLジャンプさせない(5)
                    if UIApplication.sharedApplication(
                        ).networkActivityIndicatorVisible {
                            return false
                    }
                    
                    //インジケーターの表示(2)
                    UIApplication.sharedApplication(
                        ).networkActivityIndicatorVisible = true
            }
            return true
    }
    
    //HTML読み込み成功時に呼ばれる(4)
    func webViewDidFinishLoad(webView: UIWebView) {
        //インジケーターの非表示(2)
        UIApplication.sharedApplication(
            ).networkActivityIndicatorVisible = false
    }
    
    func settingbutton() {
        // Buttonを生成する.
        settingButton = UIButton()
        
        // サイズを設定する.
        settingButton.frame = CGRectMake(0,0,50,50)
        
        // 背景色を設定する.
        settingButton.backgroundColor = UIColor.grayColor()
        
        // 枠を丸くする.
        settingButton.layer.masksToBounds = false
        
        // タイトルを設定する(通常時).
        settingButton.setTitle("home", forState: UIControlState.Normal)
        settingButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
        // タイトルを設定する(ボタンがハイライトされた時).
        settingButton.setTitle("home(押された時)", forState: UIControlState.Highlighted)
        settingButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Highlighted)
        
        // コーナーの半径を設定する.
        settingButton.layer.cornerRadius = 25.0
        
        // ボタンの位置を指定する.
        settingButton.layer.position = CGPoint(x: self.view.frame.width/2 + 100, y:500)
        
        // タグを設定する.
        settingButton.tag = 1
        
        // イベントを追加する.
        settingButton.addTarget(self, action: "onClickSettingButton:", forControlEvents: .TouchUpInside)
        
        // ボタンをViewに追加する.
        self.view.addSubview(settingButton)
    }
    internal func onClickSettingButton(sender: UIButton){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}