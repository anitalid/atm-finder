import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import 'main_shell.dart';

class OtpScreen extends StatefulWidget {
  final String nomorHp;
  const OtpScreen({super.key, required this.nomorHp});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _len = 6; // Firebase mengirim 6 digit
  final _auth = AuthService();
  final List<TextEditingController> _c = List.generate(_len, (_) => TextEditingController());
  final List<FocusNode> _f = List.generate(_len, (_) => FocusNode());
  bool _sending = false, _verifying = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() { super.initState(); _send(); }

  @override
  void dispose() { _timer?.cancel(); for (final x in _c) x.dispose(); for (final x in _f) x.dispose(); super.dispose(); }

  void _startTimer() { _timer?.cancel(); _seconds = 45; _timer = Timer.periodic(const Duration(seconds: 1), (t) { setState(() => _seconds--); if (_seconds <= 0) t.cancel(); }); }

  Future<void> _send() async {
    setState(() => _sending = true);
    await _auth.sendOtp(widget.nomorHp,
      onCodeSent: () { if (mounted) { setState(() => _sending = false); _startTimer(); _snack('OTP terkirim ke ${widget.nomorHp}'); } },
      onFailed: (m) { if (mounted) { setState(() => _sending = false); _snack(m); } });
  }

  Future<void> _verifikasi() async {
    final code = _c.map((e) => e.text).join();
    if (code.length != _len) { _snack('Masukkan ${_len} digit kode.'); return; }
    setState(() => _verifying = true);
    try {
      await _auth.verifyOtp(code);
      if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainShell()), (_) => false);
    } catch (e) { _snack(AuthService.errorMessage(e)); }
    finally { if (mounted) setState(() => _verifying = false); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String get _timerText => '00:${_seconds.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Verifikasi Akun')),
      body: Padding(padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 20),
          const Text('Masukkan kode OTP yang telah dikirim ke', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
          const SizedBox(height: 6),
          Text(AuthService.toE164(widget.nomorHp), textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(_len, (i) =>
            SizedBox(width: 46, height: 54, child: TextFormField(
              controller: _c[i], focusNode: _f[i], textAlign: TextAlign.center,
              keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(1)],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.zero),
              onChanged: (v) { if (v.isNotEmpty && i < _len - 1) _f[i + 1].requestFocus(); },
            )))),
          const SizedBox(height: 20),
          Center(child: _seconds > 0
            ? Text('Kirim ulang kode dalam $_timerText', style: const TextStyle(fontSize: 12, color: AppColors.textGrey))
            : TextButton(onPressed: _sending ? null : _send, child: const Text('Kirim ulang kode', style: TextStyle(fontSize: 12)))),
          const Spacer(),
          _sending ? const Center(child: CircularProgressIndicator()) : PrimaryButton(label: 'Verifikasi', loading: _verifying, onPressed: _verifikasi),
          const SizedBox(height: 16),
        ])));
  }
}