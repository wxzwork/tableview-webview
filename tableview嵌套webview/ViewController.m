//
//  ViewController.m
//  tableview嵌套webview
//
//  Created by WOSHIPM on 16/7/2.
//  Copyright © 2016年 WOSHIPM. All rights reserved.
//

#import "ViewController.h"
 
#import "HZPhotoBrowser.h"
#import "WebViewURLViewController.h"
#import "IMYWebView.h"
@interface ViewController ()<UITableViewDataSource, UITableViewDelegate,IMYWebViewDelegate,HZPhotoBrowserDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, assign)CGFloat webviewHight;//记录webview的高度
@property(nonatomic, copy)NSString *HTMLData;//需要加载的HTML数据
@property(nonatomic, strong)NSMutableArray *imageArray;//HTML中的图片个数
@property(nonatomic, strong)IMYWebView *htmlWebView;

@property(nonatomic, strong)UILabel *titleLabel;
@end
NSInteger tagCount;//全局变量
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.translucent = NO;
    self.title = @"tableviewcell嵌套webview载HTML";
    self.view.backgroundColor = [UIColor whiteColor];
//    获取HTML数据
     [self getHTMLData];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width , self.view.frame.size.height - 64) style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
    _tableView.tableHeaderView = [[UIView alloc] init];
    [self.view addSubview:_tableView];
    _htmlWebView = [[IMYWebView alloc] init];
    _htmlWebView.frame = CGRectMake(0, 0, _tableView.frame.size.width, 1);
   
    _titleLabel.textAlignment = 1;
    _htmlWebView.delegate = self;
    _htmlWebView.scrollView.scrollEnabled = NO;//设置webview不可滚动，让tableview本身滚动即可
    _htmlWebView.scrollView.bounces = NO;
    _htmlWebView.opaque = NO;
    
    //给scrollview添加头视图
    
     _htmlWebView.scrollView.contentInset = UIEdgeInsetsMake(40, 0, 0, 0);
    _titleLabel = [[UILabel alloc] init];
    [_htmlWebView.scrollView addSubview:_titleLabel];
       _titleLabel.frame = CGRectMake(0, -40, _htmlWebView.frame.size.width, 40);
    [_htmlWebView.scrollView addSubview:_titleLabel];
     _titleLabel.text = @"标题";
 
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 4;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row != 3) {
         return 60;
    }else{
        
        return _webviewHight;//cell自适应webview的高度
    }
   
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

    if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            
                }
    if (indexPath.row == 3) {
        
        [cell.contentView addSubview:_htmlWebView];

        //加载HTML数据
        [_htmlWebView loadHTMLString:_HTMLData baseURL:nil];
        
    }else{
        
        cell.textLabel.text = [NSString stringWithFormat:@"第%ld行",(long)indexPath.row];
      
    }
     return cell;
}

-(void)webViewDidFinishLoad:(IMYWebView *)webView{
    [self.htmlWebView evaluateJavaScript:@"document.documentElement.scrollHeight" completionHandler:^(id object, NSError *error) {
        CGFloat height = [object integerValue];
        
        if (error != nil) {
            
        }else{
            _webviewHight = height;
            [_tableView beginUpdates];
            self.htmlWebView.frame = CGRectMake(_htmlWebView.frame.origin.x,_htmlWebView.frame.origin.y, _tableView.frame.size.width, _webviewHight );
            
           
        }
        
         [_tableView endUpdates];
    }];
    
//    插入js代码，对图片进行点击操作
    [webView evaluateJavaScript:@"function assignImageClickAction(){var imgs=document.getElementsByTagName('img');var length=imgs.length;for(var i=0; i < length;i++){img=imgs[i];if(\"ad\" ==img.getAttribute(\"flag\")){var parent = this.parentNode;if(parent.nodeName.toLowerCase() != \"a\")return;}img.onclick=function(){window.location.href='image-preview:'+this.src}}}" completionHandler:^(id object, NSError *error) {
        
    }];
    [webView evaluateJavaScript:@"assignImageClickAction();" completionHandler:^(id object, NSError *error) {
        
    }];

    //获取HTML中的图片
    [self getImgs];
 

}

-(BOOL)webView:(IMYWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    if ([request.URL isEqual:@"about:blank"])
    {
        return true;
    }
    if ([request.URL.scheme isEqualToString: @"image-preview"])
    {
        
        NSString *url = [request.URL.absoluteString substringFromIndex:14];
        
        
        //启动图片浏览器， 跳转到图片浏览页面
        if (_imageArray.count != 0) {
            
            HZPhotoBrowser *browserVc = [[HZPhotoBrowser alloc] init];
            browserVc.imageCount = self.imageArray.count; // 图片总数
            browserVc.currentImageIndex = [_imageArray indexOfObject:url];//当前点击的图片
            browserVc.delegate = self;
            [browserVc show];
            
        }
        return NO;
        
    }
    
    //    用户点击文章详情中的链接
    if ( navigationType == UIWebViewNavigationTypeLinkClicked ) {
        
            WebViewURLViewController *webViewVC = [WebViewURLViewController new];
            webViewVC.URLString = request.URL.absoluteString;
            [self.navigationController pushViewController:webViewVC animated:YES];
        
        
        return NO;
    }
        
        return YES;
}


#pragma mark - photobrowser代理方法
- (UIImage *)photoBrowser:(HZPhotoBrowser *)browser placeholderImageForIndex:(NSInteger)index
{
    //图片浏览时，未加载出图片的占位图
    return [UIImage imageNamed:@"gg_pic@2x"];
    
}

- (NSURL *)photoBrowser:(HZPhotoBrowser *)browser highQualityImageURLForIndex:(NSInteger)index
{
    NSString *urlStr = [self.imageArray[index] stringByReplacingOccurrencesOfString:@"thumbnail" withString:@"bmiddle"];
    return [NSURL URLWithString:urlStr];
}
#pragma mark -- 获取文章中的图片个数
- (NSArray *)getImgs
{
   
    NSMutableArray *arrImgURL = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self nodeCountOfTag:@"img"]; i++) {
        NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('img')[%d].src", i];
        [_htmlWebView evaluateJavaScript:jsString completionHandler:^(NSString *str, NSError *error) {
            
            if (error ==nil) {
                [arrImgURL addObject:str];
            }
            
            
            
        }];
    }
    _imageArray = [NSMutableArray arrayWithArray:arrImgURL];
    
    
    return arrImgURL;
}

// 获取某个标签的结点个数
- (NSInteger)nodeCountOfTag:(NSString *)tag
{
    
    NSString *jsString = [NSString stringWithFormat:@"document.getElementsByTagName('%@').length", tag];
 
   int count =  [[_htmlWebView stringByEvaluatingJavaScriptFromString:jsString] intValue];
    
    return count;
}



-(void)getHTMLData{
    _HTMLData = @"<!DOCTYPE html><html><head><meta charset=\"utf-8\"><title>人人都是产品经理</title><meta content=\"width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no\" name=\"viewport\" /><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" /><meta http-equiv=\"Pragma\" content=\"no-cache\" /><meta http-equiv=\"Cache-Control\" content=\"no-cache\" /><meta http-equiv=\"Expires\" content=\"0\" /><meta http-equiv=\"Access-Control-Allow-Origin\" content=\"*\" /><meta name=\"format-detection\" content=\"telephone=no\" /><style> body{ padding:0 16px; font-size:18px; margin:0; background-color:#fff;color:#333; font-family: \"Microsoft YaHei\",\"Open Sans\",\"Helvetica Neue\",Helvetica,Arial,sans-serif; font-weight:300; word-break: break-all;}  p{text-align:left;line-height:30px; }   blockquote p{margin-top:16px;}   blockquote{padding:16px;  background-color:#f6f6f6; font-size:16px; display: block; -webkit-margin-before: 1em; -webkit-margin-after: 0em;-webkit-margin-start: 0px;-webkit-margin-end: 0px;}  img{max-width:100%; height:auto;} div{ text-align:center;}  h1{font-size:24px; margin:20px 0 0 0;}  h2{margin-top:16px; font-size:21px; font-weight:bold;}   h3{font-size:19px; border-left:4px #4d8ae7 solid; padding-left:20px;} iframe,img {max-width: 100%; } a{color:#4d8ae7;}</style></head> <body><p><strong>“人类很多行为遵循一些统计规律，在这个意义上人类</strong><strong>93%</strong><strong>的行为是可以预测的”，</strong><strong>via</strong><strong>巴拉巴西《爆发》。</strong></p><p>“腾讯正将开放战略推向移动互联网”，这是小马哥在2012移动开发者大会上传递出来的信息。微信，腾讯目前最成功的移动互联网应用，也是互联网历史上增长最快的新软件，号称中国第四大运营商，它在这个战略中将会扮演什么角色，起到什么作用呢？</p><p>我的看法是如果QQ和Qzone是腾讯pc端的大数据开放平台，那么微信将成为腾讯移动端的大数据开放平台。</p><p><div><img  src=\"http://image.woshipm.com/wp-files/2012/10/1111.jpg\"    / style=\"width:100%px;height:auto;\"></div></p><p>还记得一个月前微信团队宣布微信用户数突破两亿，当时中国智能机用户数2.9亿，也就是微信已经覆盖了近7成用户，业界在惊呼羡慕之余也在关注微信未来发展道路，是打造一个精准营销的媒体平台，还是做一个闭环的电商平台，或者兼而有之？</p><p>时间过去一个月，微信公众账号已经暂停了认证，小戴同学的微信会员卡推广之路也是路漫漫兮汝将上下探索，因此对于微信的商业化探索很多人提出了质疑，小马哥9月份在互联网大会上提到的通过微信普及二维码，布局O2O的目标还能实现么？我也抱着怀疑的态度，微信虽然有开放平台，但是那些接口只是浅层次的开放，无法满足第三方开发者的需要，也就不具有很高的价值，但是这次小马哥已经明确放出风声，将逐步测试开放QQ的关系链，甚至有可能是微信的关系链，这让我非常期待，依靠着庞大的用户数据为基础，用开放的心态做平台，微信的潜力绝对是可以被挖掘的，或者说和新浪微博真正的竞争从现在才开始。</p><p>先说说大数据，这可是自云平台后最热的概念了，随着社会化媒体的兴起，针对互联网用户数据的分析、营销、挖掘产品越来越多，大部分是在为企业服务，或者用来做自身产品推广，比较经典的案例就是美丽说、蘑菇街，而最近走红的“啪啪”更是依靠着新浪微博的用户关系迅速发展用户，每天达到上万的下载量。以上的大数据主要还是来源于pc互联网上。那么在移动互联网的大数据呢？</p><p><div><img  src=\"http://image.woshipm.com/wp-files/2012/10/222.jpg\"    / style=\"width:100%px;height:auto;\"></div></p><p>&nbsp;</p><p>每个人可能拥有不同的终端，从Pad、手机到其他各种移动式终端接入到互联网里，在移动终端上产生的信息越来越多样化，文本也好，图片也好，语音也好，视频也好，多点信息也好，结构也好，非结构也好，使用频率非常之高，虽然pc互联网上目前数据量肯定比现在移动互联网更大，但较之pc互联网，现在的移动互联网，数据本身的价值在于更完整和更生动的去描绘了一个互联网用户的生活轨迹，简单的说在pc互联网上我可以知道你不是一条狗，你可能对什么感兴趣，而到移动互联网时代，我可以知道你每分每秒在干什么，甚至你在上大号，因为你一直online。</p><p>所以说移动互联网上的大数据相比pc互联网的大数据具有以下几个特征：</p><p><strong>1</strong><strong>、数据的核心节点是人而不再是终端、网页或</strong><strong>ID</strong><strong>；</strong></p><p><strong></strong><strong>2</strong><strong>、动作更加实时性；</strong></p><p><strong></strong><strong>3</strong><strong>、行为更加碎片化；</strong></p><p><strong></strong><strong>4</strong><strong>、带有地理位置信息；</strong></p><p><strong></strong><strong>5</strong><strong>、数据更干净准确。</strong></p><p>回过头来看微信，作为腾讯在移动领域的杀手锏应用，两亿多的用户时刻在产生各种各样文本、视频、图片、地理位置等各种非结构信息。就拿我自己来说，忙的时候可能我一天都不会打开新浪微博，但是花在微信上的时间累计起来肯定超过两小时以上，我会用微信跟好友和同事联系，看下几个群里大家在讨论些什么，几个科技博客的公众账号推荐的好文章，再刷刷朋友圈看看大家分享了些什么好东西，如果我正在享受美食美景啥的，也会很乐意将这份美好分享给好友。可以说这些事情基本是目前每个微信用户都在做的，最多是因为圈子或兴趣爱好等不同看到的内容不一样，但是这些信息基本上完整的描述了我一天的行为，同时还带着地理位置（小马哥说的腾讯LBS调用每天7亿次，据我所了解的情况，微信在3.5亿以上）。</p><p>微信从1.0版最初的一个聊天工具到取代运营商短信和语音通信，再到类似path、Qzone的熟人社区，再到现在公众平台的移动营销，财付通的移动支付，还有QQ邮箱、QQ新闻、QQ音乐、美丽说等插件，微信似乎变的越来越重，而与此同时它的用户数据积累也是在快速的增加，数据的丰满度也在快速的提高，也越来越贴近微信最初开发时的想法——一个私人信息数据中心，而且由于微信本身是私密空间的闭环交流，主要交流都是点对点的，也就减少了很多pc互联网上因为水军、机器等产生的垃圾信息干扰，所以微信的大数据是非常有价值的。</p><p><div><img  src=\"http://image.woshipm.com/wp-files/2012/10/333.jpg\"    / style=\"width:100%px;height:auto;\"></div></p><p>&nbsp;</p><p>微信就是为移动互联网而生的，拥有的数据也非常吻合移动互联网大数据的特点，但是凭借腾讯自己现在是没有办法利用好这些数据的，或者微信最多是接着走QQ的老路，卖会员卖各种钻卖广告卖游戏啥的，pc互联网时代腾讯做电商、搜索什么的都失败，到了移动互联网上小马哥希望能够靠着微信有所建树，可是所谓的“二维码+账号体系+LBS+支付+关系链”的O2O闭环体系推动的并不顺利（照搬新浪微博上的企业账号到微信上用户很排斥，商家很受伤，原因就是微博是基于信息关系，微信是基于用户关系的），估计也是前面设想的那些方向进展的不顺利，小马哥想既然自己守着金矿却开采不出来，干脆我把金矿开放了，大家一起来搞，我收点过路费场租费，或者合资办厂啥的。想象一下微信两亿多的用户数，相当于三分之一的中国移动手机用户，整个中国联通手机用户，两个中国电信手机用户，把这些用户数据开放出来将会爆发出多大的能量？创造多大的价值？截止今年6月，腾讯开放平台的分成已经超过10亿元，按照最高分成比例35%来估算起码也是30多个亿营收，目前这些还只是来自于线上的收入，当微信数据加入后将直接开启O2O通道，估计营收翻10倍都不止，如此巨大的金矿怎么去开采，个人觉得可以有以下几个方向：</p><p>1、客户关系管理。</p><p>虽然微信公众平台推出后业界褒贬不一，用户接受程度也不高，但并不影响微信作为小商家的初级CRM来使用，杭州武林路几个卖女装的老板就用微信加了一群老客户，朋友圈里发发新款，微信上进行售前售后服务，如果开发者再能提供点延伸服务，线上支付通道打通，这个闭环就成了。</p><p>2、富媒体应用。</p><p>类似微语音这类变声插件虽然目前还很小众，但是随着用户个性化需求的上升，各种基于图片、文字、声音、视频的应用将会层出不穷。比如为媒体制作一个图文混排模板，可能还带上视频、音频，后台还可以做数据分析等。</p><p>3、关系链管理。</p><p>不可否认微信通讯录已经慢慢等同于我的手机通讯录，里面也不再仅仅是好友和家人，还有同事、客户等社会关系在里面，另外还有微信群、公众账号等，如何管理、分享或者搜索期待开发者的智慧。</p><p>4、线下数据分析和商业决策指导。</p><p>目前为品牌商家做数据分析的大部分还是通过微博等社会化媒体做线上影响力分析或者事件营销等。有了微信用户数据后就不只是提供这些了，甚至你可以去影响商家的经营决策，诸如：A店只卖包子，B店只卖牛奶，现在通过微信数据告诉A店，来买包子的人通常在之前或者之后会去B店买牛奶，而且人数不少，频次很高，那么A店可以也搭卖牛奶，或者干脆收购了B店，这些在以前pc互联网时代是无法想象的。</p><p>5、基于地理位置的线下商家搜索。</p><p>这方面微信已经在悄悄的做了，查找附近的人里现在除了普通用户，还有微信会员卡商家，个人以为这块做得还是比较糙，内容也不够丰富，期待开放后能有更多的商家、更好的体验，这绝对是个NB的O2O入口，我之前写的《Passbook让我欢喜不让我忧》里有提到过微信是浮云，那是因为它那会儿还不够开放，如果这块完全开放给第三方开发者，微信只做用户数、管理标准和支付环节，大量的线下资源将通过各个第三方应用对接进入，那么可以大胆预测微信将成为中国最大的O2O平台，小马哥的O2O梦想也能顺利实现了。</p><p>6、基于用户行为分析的精准推荐。</p><p>腾讯当年是做SP起家的，那么多年来虽然SP日落西山，但是垃圾短信依然天天骚扰着我们的生活，其实那些信息本来是有价值的，只是收到的人并不需要这些信息所以成了垃圾，而现在通过对微信用户行为数据进行分析后，就可以给需要的人发送需要的信息，不再是垃圾，同时这部分也将成为O2O的重要渠道。</p><p>最后想提的是大数据开放平台愿景很好，却也存在用户隐私泄露，用户被骚扰等隐忧，但是我相信小马哥会在这方面如他自己保证的那样，把资源开放给所有的移动开发者的同时，建立很好的管理机制，这是三赢的，对用户有益、对平台有益、对开发者有益。</p><p>尾声：“1972年倪匡写的《规律》一书中，描写了特务机构花了三年时间拍摄了几万张康纳士博士日常生活照片，然后做出日常行为分析曲线图，同时附上土蜂的行为分析曲线图邮寄给他，让博士发现自己的生活规律和土蜂的生活规律完全一样而觉得生命没有意义，继而自杀。”在这个大数据爆发的时代，每个人的行为规律都被记录成数据，都可以找到规律做出分析，巴拉巴西写的书里反复强调的就是人的行为是可以预测的，而来源就是大数据，那么会有这样的事情发生么？</p><p>来源：<a href=\"http://www.alibuybuy.com/posts/77248.html\">http://www.alibuybuy.com/posts/77248.html</a></p></body></html>";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
