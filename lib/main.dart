import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:yq_flutter/about/about_page.dart';
import 'package:yq_flutter/mine/mine_tab.dart';
import 'package:yq_flutter/mycoupon/my_coupon_page.dart';
import 'package:yq_flutter/plugin/my_flutter_plugin.dart';
import 'package:yq_flutter/request/Api.dart';
import 'package:yq_flutter/setting/setting_page.dart';
import 'package:yq_flutter/utils/Toast.dart';
import 'package:yq_flutter/utils/constant.dart';
import 'package:yq_flutter/utils/logger.dart';
import 'package:yq_flutter/utils/string_utils.dart';

void main() {
  MyFlutterPlugin.getEnv().then((env){
    Api.ENV = env;
    runApp(new MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
//      showPerformanceOverlay: !ProductUtil.isProdEnv(),
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: _widgetForRoute(window.defaultRouteName),
    );
  }
}

Widget _widgetForRoute(String route) {
  Log.log(">>>>>>>>>> route ： " + route);
  String uri = StringUtil.getSchemeRouteName(route);
  String paramsJson = StringUtil.getSchemeRouteParams(route);
  switch (uri) {
    case ROUTE_ABOUT_US:
      return AboutWidget(params: paramsJson);
    case ROUTE_MINE:
      return MineTabWidget();
    case ROUTE_SETTING:
      return SettingPage();
    case ROUTE_COUPON_LIST:
      return MyCouponWidget();
    default:
      return MineTabWidget();
      Toast.toast("您访问的页面不存在");
      SystemNavigator.pop();
  }
}
