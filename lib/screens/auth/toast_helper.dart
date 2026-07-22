import 'package:fluttertoast/fluttertoast.dart';

void showNoInternetToast() {
  Fluttertoast.showToast(
    msg: "No internet connection. Please check your network and try again.",
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: null,
    textColor: null,
    fontSize: 14.0,
  );
}