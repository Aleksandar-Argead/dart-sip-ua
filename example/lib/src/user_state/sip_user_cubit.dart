import 'package:bloc/bloc.dart';
import 'package:dart_sip_ua_example/src/user_state/sip_user.dart';
import 'package:sip_ua/sip_ua.dart';

class SipUserCubit extends Cubit<SipUser?> {
  final SIPUAHelper sipHelper;
  SipUserCubit({required this.sipHelper}) : super(null);

  void register(SipUser user) {
    UaSettings settings = UaSettings();

    settings.uri = user.sipUri;
    settings.host = 'sip.firsty.app';
    settings.port = '5061';
    settings.transportType = TransportType.TLS;
    settings.dtmfMode = DtmfMode.RFC2833;

    settings.password = user.password;
    settings.userAgent = "Firsty/1.0.0";
    settings.contact_uri = "sip:${user.sipUri}";
    settings.register_expires = 30;

    settings.iceTransportPolicy = IceTransportPolicy.RELAY;
    settings.iceServers = [
      {
        "urls": 'turn:3.66.112.149:13478',
        "username": 'wDTjokwP03Qj3n49',
        "credential": '2O02uI63AnhUhqZx'
      },
      {
        "urls": 'turn:18.153.186.100:13478',
        "username": 'wDTjokwP03Qj3n49',
        "credential": '2O02uI63AnhUhqZx'
      }
    ];

    emit(user);
    sipHelper.start(settings);
  }
}
