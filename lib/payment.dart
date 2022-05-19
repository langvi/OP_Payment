import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DemoPaymentPage extends StatefulWidget {
  DemoPaymentPage({Key? key}) : super(key: key);

  @override
  State<DemoPaymentPage> createState() => _DemoPaymentPageState();
}

class _DemoPaymentPageState extends State<DemoPaymentPage> {
  final _controller = TextEditingController(text: '10000');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Demo payment"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTextInput(),
            ElevatedButton(
                onPressed: () async {
                  final url = await PaymentChannel.instance
                      .getUrlPayment(int.parse(_controller.text));
                  // print(url);
                  print("status: $url");
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(title: Text("status: $url"));
                      });
                  // if (url != null) {
                  //   pushTo(
                  //       context,
                  //       ViewOnePay(
                  //         url: url,
                  //       ));
                  // }
                },
                child: Text("Thanh toán"))
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}

class ViewOnePay extends StatefulWidget {
  final String url;
  ViewOnePay({Key? key, required this.url}) : super(key: key);

  @override
  State<ViewOnePay> createState() => _ViewOnePayState();
}

class _ViewOnePayState extends State<ViewOnePay> {
  String urlOnePay = '';
  WebViewController? _webViewController;

  @override
  void initState() {
    urlOnePay = widget.url;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("One pay"),
      ),
      body: WebView(
        initialUrl: urlOnePay,
        javascriptMode: JavascriptMode.unrestricted,
        onPageStarted: (url) {
          if (isGotoAppBank(url)) {
            _webViewController?.goBack();
          }
        },
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onPageFinished: (url) async {
          print(url);
          if (isGotoAppBank(url)) {
            final data = await PaymentChannel.instance.goToBankApp(url);
          } else if (isResponseUrl(url)) {
            String body = url.split('?').last;
            List<String> elements = body.split('&');
            String status = '';
            for (var element in elements) {
              if (element.contains('vpc_TxnResponseCode')) {
                status = element.split('=').last;
                break;
              }
            }
            if (status == '0') {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Thanh toan thanh cong"),
                    );
                  });
            }
            // setState(() {});
            // urlOnePay = url;
          }
        },
      ),
    );
  }

  bool isGotoAppBank(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return false;
    } else {
      return true;
    }
  }

  bool isResponseUrl(String url) {
    return url.startsWith('merchantappscheme:');
  }
}

class PaymentChannel {
  static final instance = PaymentChannel._private();
  PaymentChannel._private();
  static final String channel = 'tuanchaubooking/onepay_gateway';
  static final String createUrl = 'create_url';
  static final String openAppBank = 'open_app_bank';
  static final String one_pay_payment = "one_pay_payment";
  static final platform = MethodChannel(channel);
  Future<String?> getUrlPayment(num amount) async {
    try {
      final url =
          await platform.invokeMethod(createUrl, {'amount': amount.toString()});
      return url.toString();
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<String?> goToBankApp(String url) async {
    try {
      final result = await platform.invokeMethod(openAppBank, {"url": url});
      return result.toString();
    } catch (e) {
      print(e);
      return null;
    }
  }
}

void pushTo(BuildContext context, Widget widget,
    {void Function()? callBack}) async {
  await Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => widget,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = Offset(1.0, 0.0);
      var end = Offset.zero;
      var tween = Tween(begin: begin, end: end);
      var curve = Curves.ease;
      var curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: curve,
      );

      return SlideTransition(
        position: tween.animate(curvedAnimation),
        child: child,
      );
    },
  ));
  if (callBack != null) callBack();
}
