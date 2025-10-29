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
    settings.iceServers = [];

    emit(user);
    sipHelper.start(settings);
  }
}
