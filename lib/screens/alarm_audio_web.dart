import 'dart:js_interop';

@JS('eval')
external void _jsEval(String code);

void initAudioContext() {
  // Pre-warm AudioContext on first user gesture to satisfy browser autoplay policy.
  try {
    _jsEval('''
      if (!window._alarmAudioCtx) {
        var AC = window.AudioContext || window.webkitAudioContext;
        window._alarmAudioCtx = new AC();
      }
    ''');
  } catch (_) {}
}

void playAlarmSound() {
  try {
    _jsEval('''
      (function() {
        try {
          var AC = window.AudioContext || window.webkitAudioContext;
          var ctx = window._alarmAudioCtx || new AC();
          window._alarmAudioCtx = ctx;
          function beep() {
            for (var i = 0; i < 4; i++) {
              var osc = ctx.createOscillator();
              var gain = ctx.createGain();
              osc.connect(gain);
              gain.connect(ctx.destination);
              osc.frequency.value = i % 2 === 0 ? 880 : 660;
              gain.gain.value = 0.4;
              osc.start(ctx.currentTime + i * 0.4);
              osc.stop(ctx.currentTime + i * 0.4 + 0.28);
            }
          }
          if (ctx.state === 'suspended') { ctx.resume().then(beep); }
          else { beep(); }
        } catch(e) {}
      })();
    ''');
  } catch (_) {}
}

void stopAlarmSound() {
  // Oscillators are scheduled to auto-stop; nothing to cancel.
}

void requestNotificationPermission() {
  try {
    _jsEval(
        "if (typeof Notification !== 'undefined' && Notification.permission === 'default') { Notification.requestPermission(); }");
  } catch (_) {}
}

void showBrowserNotification(String name, String time) {
  final n = name.replaceAll("'", r"\'");
  final t = time.replaceAll("'", r"\'");
  try {
    _jsEval(
        "if (typeof Notification !== 'undefined' && Notification.permission === 'granted') { new Notification('⏰ $n', { body: '$t', silent: false }); }");
  } catch (_) {}
}
