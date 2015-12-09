//
// author pass
//

import UIKit
import MapKit
import CoreLocation

class MapController: UIViewController,NSURLSessionDelegate,NSURLSessionDataDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UISearchBarDelegate {
    
    private var myButton: UIButton!
    private var finishButton: UIButton!
    private var settingButton: UIButton!
    var locationManager: CLLocationManager!
    var userLocation: CLLocationCoordinate2D!
    var destLocation: CLLocationCoordinate2D!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var destSearchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        mapView.delegate = self
        destSearchBar.delegate = self
        
        // 位置情報取得の許可状況を確認
        let status = CLLocationManager.authorizationStatus()
        
        // 許可が必要な場合は確認ダイアログを表示
        if(status == CLAuthorizationStatus.NotDetermined) {
            print("didChangeAuthorizationStatus:\(status)");
            self.locationManager.requestAlwaysAuthorization()
        }
        //位置情報の精度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //位置情報取得間隔(m)
        locationManager.distanceFilter = 100
        
        settingbutton()
        
        
        
    }
    // 検索ボタンを押したときにキーボードを隠して検索実行
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        startbutton()
        
        // キーボードを隠す
        destSearchBar.resignFirstResponder()
        // セット済みのピンを削除
        self.mapView.removeAnnotations(self.mapView.annotations)
        // 描画済みの経路を削除
        self.mapView.removeOverlays(self.mapView.overlays)
        
        mapView.setUserTrackingMode(MKUserTrackingMode.FollowWithHeading, animated: false)
        // 目的地の文字列から座標検索
        var geocoder = CLGeocoder()
        geocoder.geocodeAddressString(destSearchBar.text!, completionHandler: {(placemarks: [CLPlacemark]?, error: NSError?) -> Void in
            
            var placemark: CLPlacemark!
            for placemark in placemarks! {
                print("Name: \(placemark.name)")
                print("Country: \(placemark.country)")
                print("ISOcountryCode: \(placemark.ISOcountryCode)")
                print("administrativeArea: \(placemark.administrativeArea)")
                print("subAdministrativeArea: \(placemark.subAdministrativeArea)")
                print("Locality: \(placemark.locality)")
                print("PostalCode: \(placemark.postalCode)")
                print("areaOfInterest: \(placemark.areasOfInterest)")
                print("Ocean: \(placemark.ocean)")
                
                self.destLocation = CLLocationCoordinate2DMake(placemark.location!.coordinate.latitude, placemark.location!.coordinate.longitude)
                self.mapView.addAnnotation(MKPlacemark(placemark: placemark))
                self.locationManager.startUpdatingLocation()
            }
        })
    }
    
    // 位置情報取得に成功したときに呼び出されるデリゲート.
    func locationManager(manager: CLLocationManager,didUpdateLocations locations: [CLLocation]){
        
        userLocation = CLLocationCoordinate2DMake(manager.location!.coordinate.latitude, manager.location!.coordinate.longitude)
        
        let userLocAnnotation: MKPointAnnotation = MKPointAnnotation()
        userLocAnnotation.coordinate = userLocation
        //userLocAnnotation.title = "現在地"
        //mapView.addAnnotation(userLocAnnotation)
        // 現在地から目的地家の経路を検索
        getRoute()
    }
    
    // 位置情報取得に失敗した時に呼び出されるデリゲート.
    func locationManager(manager: CLLocationManager,didFailWithError error: NSError){
        print("locationManager error", terminator: "")
    }
    
    func getRoute()
    {
        // メートルで距離を計算
        let startLocation = CLLocation(latitude: userLocation.latitude,longitude: userLocation.longitude)
        let goalLocation = CLLocation(latitude: destLocation.latitude,longitude: destLocation.longitude)
        let distance = startLocation.distanceFromLocation(goalLocation)
        
        // 現在地と目的地のMKPlacemarkを生成
        var fromPlacemark = MKPlacemark(coordinate:userLocation, addressDictionary:nil)
        var toPlacemark   = MKPlacemark(coordinate:destLocation, addressDictionary:nil)
        
        // MKPlacemark から MKMapItem を生成
        var fromItem = MKMapItem(placemark:fromPlacemark)
        var toItem   = MKMapItem(placemark:toPlacemark)
        
        // MKMapItem をセットして MKDirectionsRequest を生成
        let request = MKDirectionsRequest()
        
        request.source = fromItem
        request.destination = toItem
        request.requestsAlternateRoutes = false // 単独の経路を検索
        request.transportType = MKDirectionsTransportType.Any
        
        let directions = MKDirections(request:request)
        directions.calculateDirectionsWithCompletionHandler({
            (response, error) -> Void in
            
            response?.routes.count
            if (error != nil || response!.routes.isEmpty) {
                return
            }
            var route: MKRoute = response!.routes[0] as MKRoute
            // 経路を描画
            self.mapView.addOverlay(route.polyline)
            // 現在地と目的地を含む表示範囲を設定する
            self.showUserAndDestinationOnMap()
            
        })
        if(distance < 100){
            //配送完了ボタン設置
            self.finishbutton()
        }
    }
    
    // 地図の表示範囲を計算
    func showUserAndDestinationOnMap()
    {
        // 現在地と目的地を含む矩形を計算
        let maxLat:Double = fmax(userLocation.latitude,  destLocation.latitude)
        let maxLon:Double = fmax(userLocation.longitude, destLocation.longitude)
        let minLat:Double = fmin(userLocation.latitude,  destLocation.latitude)
        let minLon:Double = fmin(userLocation.longitude, destLocation.longitude)
        
        // 地図表示するときの緯度、経度の幅を計算
        let mapMargin:Double = 1.5;  // 経路が入る幅(1.0)＋余白(0.5)
        let leastCoordSpan:Double = 0.005;    // 拡大表示したときの最大値
        let span_x:Double = fmax(leastCoordSpan, fabs(maxLat - minLat) * mapMargin);
        let span_y:Double = fmax(leastCoordSpan, fabs(maxLon - minLon) * mapMargin);
        
        let span:MKCoordinateSpan = MKCoordinateSpanMake(span_x, span_y);
        
        // 現在地を目的地の中心を計算
        let center:CLLocationCoordinate2D = CLLocationCoordinate2DMake((maxLat + minLat) / 2, (maxLon + minLon) / 2);
        let region:MKCoordinateRegion = MKCoordinateRegionMake(center, span);
        
        mapView.setRegion(mapView.regionThatFits(region), animated:true);
    }
    
    // 経路を描画するときの色や線の太さを指定
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blueColor()
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        return MKPolylineRenderer();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        settingButton.setTitle("設定", forState: UIControlState.Normal)
        settingButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
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
    func startbutton() {
        // Buttonを生成する.
        myButton = UIButton()
        
        // サイズを設定する.
        myButton.frame = CGRectMake(0,0,130,40)
        
        // 背景色を設定する.
        myButton.backgroundColor = UIColor.redColor()
        
        // 枠を丸くする.
        myButton.layer.masksToBounds = false
        
        // タイトルを設定する(通常時).
        myButton.setTitle("配達開始", forState: UIControlState.Normal)
        myButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
        // コーナーの半径を設定する.
        myButton.layer.cornerRadius = 10.0
        
        // ボタンの位置を指定する.
        myButton.layer.position = CGPoint(x: self.view.frame.width/2, y:500)
        
        // タグを設定する.
        myButton.tag = 1
        
        // イベントを追加する.
        myButton.addTarget(self, action: "onClickMyButton:", forControlEvents: .TouchUpInside)
        
        // ボタンをViewに追加する.
        self.view.addSubview(myButton)
    }
    func finishbutton() {
        // Buttonを生成する.
        finishButton = UIButton()
        
        // サイズを設定する.
        finishButton.frame = CGRectMake(0,0,130,40)
        
        // 背景色を設定する.
        finishButton.backgroundColor = UIColor.greenColor()
            
        // 枠を丸くする.
        finishButton.layer.masksToBounds = false
        
        // タイトルを設定する(通常時).
        finishButton.setTitle("配達完了", forState: UIControlState.Normal)
        finishButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
        // コーナーの半径を設定する.
        finishButton.layer.cornerRadius = 10.0
        
        // ボタンの位置を指定する.
        finishButton.layer.position = CGPoint(x: self.view.frame.width/2, y:500)
        
        // タグを設定する.
        finishButton.tag = 1
        
        // イベントを追加する.
        finishButton.addTarget(self, action: "onClickFinishButton:", forControlEvents: .TouchUpInside)
        
        // ボタンをViewに追加する.
        self.view.addSubview(finishButton)
        self.myButton.hidden = true
        
    }
    
    
    internal func onClickSettingButton(sender: UIButton){
        // 遷移するViewを定義する.
        let mySecondViewController: UIViewController = SettingController()
        
        // アニメーションを設定する.
        mySecondViewController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        // Viewの移動する.
        self.presentViewController(mySecondViewController, animated: true, completion: nil)
    }
    internal func onClickMyButton(sender: UIButton){
        //HTTP通信　座標を送信
        let startLocation = CLLocation(latitude: userLocation.latitude,longitude: userLocation.longitude)
        let goalLocation = CLLocation(latitude: destLocation.latitude,longitude: destLocation.longitude)
        // 通信先のURLを生成.
        let myConfig:NSURLSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("backgroundTask")
        // Sessionを生成.
        var mySession:NSURLSession = NSURLSession(configuration: myConfig, delegate: self, delegateQueue: nil)
        var myUrl:NSURL = NSURL(string:"http://apli.webcrow.jp/api.php")!
        // リクエストを生成.
        var myRequest:NSMutableURLRequest  = NSMutableURLRequest(URL: myUrl)
        myRequest.HTTPMethod = "POST"
        // 送信するデータを生成・リクエストにセット.
        let str:NSString = "data=\(startLocation))"
        let myData:NSData = str.dataUsingEncoding(NSUTF8StringEncoding)!
        myRequest.HTTPBody = myData
        
        // タスクの生成.
        let myTask:NSURLSessionDataTask = mySession.dataTaskWithRequest(myRequest)
        
        // タスクの実行.
        myTask.resume()
        self.myButton.hidden = true
        
        // 送信処理を始める.
        NSURLConnection.sendAsynchronousRequest(myRequest, queue: NSOperationQueue.mainQueue(), completionHandler: self.getHttp)
        
    }
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        
        // 帰ってきたデータを文字列に変換.
        var myData:NSString = NSString(data: data, encoding: NSUTF8StringEncoding)!
        
        // バックグラウンドだとUIの処理が出来ないので、メインスレッドでUIの処理を行わせる.
        dispatch_async(dispatch_get_main_queue(), {
            print(myData as String)
        })
        
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        
        // バックグラウンドからフォアグラウンドの復帰時に呼び出されるデリゲート.
    }
    internal func onClickFinishButton(sender: UIButton){
        //HTTP通信　座標を送信
        let startLocation = CLLocation(latitude: userLocation.latitude,longitude: userLocation.longitude)
        let goalLocation = CLLocation(latitude: destLocation.latitude,longitude: destLocation.longitude)
        // 通信先のURLを生成.
        let myConfig:NSURLSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("backgroundTask")
        // Sessionを生成.
        var mySession:NSURLSession = NSURLSession(configuration: myConfig, delegate: self, delegateQueue: nil)
        var myUrl:NSURL = NSURL(string:"http://apli.webcrow.jp/api.php")!
        // リクエストを生成.
        var myRequest:NSMutableURLRequest  = NSMutableURLRequest(URL: myUrl)
        myRequest.HTTPMethod = "POST"
        // 送信するデータを生成・リクエストにセット.
        let str:NSString = "data=\(goalLocation)"
        //?start_flag=\(finishButton.tag)"
        let myData:NSData = str.dataUsingEncoding(NSUTF8StringEncoding)!
        myRequest.HTTPBody = myData
        
        // タスクの生成.
        let myTask:NSURLSessionDataTask = mySession.dataTaskWithRequest(myRequest)
        
        // タスクの実行.
        myTask.resume()

        //ボタン非表示
        self.finishButton.hidden = true
      
        //alertView表示
        alertView(self)
    }
    func getHttp(res:NSURLResponse?,data:NSData?,error:NSError?){
        
        // 帰ってきたデータを文字列に変換.
        if(data != nil){
            var myData:NSString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
            print(myData)
        }
    }
    
    @IBAction func alertView(sender : AnyObject){
        let alert = UIAlertView()
        alert.title = "配達お疲れ様です"
        alert.message = "次の配送もよろしくお願いします"
        alert.addButtonWithTitle("OK")
        alert.show()
    }
    
    
}

