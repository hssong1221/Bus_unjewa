import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

// --------------------------------------------------
// 네이버 지도 SDK 초기화와 인증 실패 전달
// SDK 의 onAuthFailed 는 앱 전역 콜백 하나뿐이라 정류장 화면이 직접 받을 수 없다.
// main 에서 init 한 번, 인증에 실패하면(오프라인·클라이언트 ID 오류) 화면이 init 을 다시 불러 재시도한다.
// FlutterNaverMap 인스턴스를 하나만 두는 이유: 콜백 핸들러가 처음 init 한 인스턴스에 묶이므로
// 같은 인스턴스로 다시 init 해야 콜백이 계속 이 객체로 온다
// --------------------------------------------------
class NaverMapService extends ChangeNotifier {
  static const clientId = "573iatcw1j";

  final FlutterNaverMap _sdk = FlutterNaverMap();

  String? _authFailure;

  /// 마지막 인증 실패 사유 (로그용). null 이면 실패하지 않았다
  String? get authFailure => _authFailure;
  bool get authFailed => _authFailure != null;

  Future<void> init() async {
    if (_authFailure != null) {
      _authFailure = null;
      notifyListeners();
    }
    try {
      await _sdk.init(clientId: clientId, onAuthFailed: _onAuthFailed);
    } catch (e) {
      _fail('초기화 실패: $e');
    }
  }

  void _onAuthFailed(NAuthFailedException ex) => _fail(switch (ex) {
        NQuotaExceededException(:final message) => '사용량 초과 (message: $message)',
        NUnauthorizedClientException() ||
        NClientUnspecifiedException() ||
        NAnotherAuthFailedException() =>
          '인증 실패: $ex',
      });

  void _fail(String reason) {
    debugPrint('네이버 지도 $reason');
    _authFailure = reason;
    notifyListeners();
  }
}
