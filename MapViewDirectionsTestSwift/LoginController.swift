import UIKit

class LoginController: UIViewController, NSURLConnectionDelegate {
    
    var alertController = UIAlertController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        makeAlertViewController()
    }
    
    override func viewDidAppear(animated: Bool) {
        showLoginAlert()
    }
    
    /* ログイン用のアラートビューを作成 */
    func makeAlertViewController(){
        alertController = UIAlertController(title: "Login", message: "", preferredStyle: .Alert)
        
        // ログインボタンが押された時のアクション
        let otherAction = UIAlertAction(title: "Login", style: .Default) {
            action in
            
            let textFields:Array<UITextField>? =  self.alertController.textFields as Array<UITextField>?
            if textFields != nil {
                
                var userArray = [String]()
                
                for textField:UITextField in textFields! {
                    print(textField.text)
                    userArray.append(textField.text!)
                }
                NSLog("ログインします。")

                self.login(userArray[0], password: userArray[1])
            }
        }
        alertController.addAction(otherAction)
        
        
        alertController.addTextFieldWithConfigurationHandler({(text:UITextField) -> Void in
            text.placeholder = "UserName"
        })
        
        alertController.addTextFieldWithConfigurationHandler({(text:UITextField) -> Void in
            text.placeholder = "Password"
            text.secureTextEntry = true
        })
    }
    
    /* ログイン用アラートを表示 */
    func showLoginAlert(){
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    /* ログイン認証処理 */
    func login(userName:NSString?, password:NSString?){
        
        print("userName:\(userName)。。password:\(password)")
        if userName == nil || password == nil {
            return self.showLoginAlert()
        }
        
        let str = "userName=\(userName!)&password=\(password!)"
        let strData = str.dataUsingEncoding(NSUTF8StringEncoding)
        
        // TODO URLの本番、devを分岐(application.conf)
        let url = NSURL(string: "http://127.0.0.1:9000/login")
        let request = NSMutableURLRequest(URL: url!)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = strData
        
        let connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: false)!
        
        // NSURLConnectionを使ってアクセス
        NSURLConnection.sendAsynchronousRequest(request,
            queue: NSOperationQueue.mainQueue(),
            completionHandler: self.fetchResponse)
        
    }
    
    /* レスポンスの処理 */
    func fetchResponse(res: NSURLResponse?, data: NSData?, error: NSError?) {
        
        // ステータスコード取得
        let status = (res as! NSHTTPURLResponse).statusCode
        
        // ステータス200:成功 それ以外:失敗
        if status != 200{
            print("ログイン失敗")
            self.showLoginAlert()
        }else{
            print("ログイン成功")
            
        }
    }
    func loginButton(){
        // 遷移するViewを定義する.
        let loginViewController: UIViewController = MapController()
        
        // アニメーションを設定する.
        loginViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        // Viewの移動する.
        self.presentViewController(loginViewController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}