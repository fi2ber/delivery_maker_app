import 'package:delivery_maker_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/ios_theme.dart';

/// OTP Verification screen for customer registration
/// Used to verify phone number before creating customer
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerified;
  final VoidCallback onResend;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
    required this.onResend,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );
  
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 60;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      
      setState(() {
        _resendTimer--;
      });
      
      if (_resendTimer <= 0) {
        setState(() {
          _canResend = true;
        });
        return false;
      }
      return true;
    });
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  bool get _isComplete {
    return _otpCode.length == 6 && _otpCode.split('').every((c) => c.isNotEmpty);
  }

  Future<void> _verifyOtp() async {
    if (!_isComplete) return;

    setState(() => _isLoading = true);
    IOSTheme.mediumImpact();

    try {
      // Call API to verify OTP
      // final response = await _apiService.post('/auth/verify-otp', {
      //   'phone': widget.phoneNumber,
      //   'code': _otpCode,
      // });

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      
      IOSTheme.success();
      widget.onVerified();
    } catch (e) {
      if (!mounted) return;
      
      IOSTheme.error();
      _showError('Неверный код. Попробуйте еще раз.');
      _clearCode();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() => _isResending = true);

    try {
      // await _apiService.post('/auth/send-otp', {
      //   'phone': widget.phoneNumber,
      // });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      
      _showSuccess('Код отправлен повторно');
      _startResendTimer();
      _clearCode();
      _focusNodes[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      _showError('Не удалось отправить код');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: IOSTheme.systemRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: IOSTheme.systemGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered
        _focusNodes[index].unfocus();
        if (_isComplete) {
          _verifyOtp();
        }
      }
    }
  }

  void _onKeyPress(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // Move to previous field
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].selection = TextSelection.collapsed(
            offset: _controllers[index - 1].text.length,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: IOSTheme.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: IOSTheme.labelPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.verified_user_outlined,
                size: 64,
                color: IOSTheme.systemBlue,
              ),
              const SizedBox(height: 24),
              Text(
                'Подтвердите номер',
                style: IOSTheme.title1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Введите 6-значный код, отправленный на',
                style: IOSTheme.bodyMedium.copyWith(
                  color: IOSTheme.labelSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                style: IOSTheme.headline.copyWith(
                  color: IOSTheme.systemBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // OTP Input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  return Padding(
                    padding: EdgeInsets.only(right: index < 5 ? 8 : 0),
                    child: SizedBox(
                      width: 48,
                      height: 56,
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (event) => _onKeyPress(index, event),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: IOSTheme.title2.copyWith(
                            letterSpacing: 0,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: IOSTheme.bgSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: IOSTheme.systemBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onDigitChanged(index, value),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Verify Button
              IOSButton(
                text: 'Подтвердить',
                isLoading: _isLoading,
                onPressed: _isComplete ? _verifyOtp : null,
              ),
              const SizedBox(height: 24),

              // Resend
              Center(
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _canResend ? _resendCode : null,
                        child: Text(
                          _canResend
                              ? 'Отправить код повторно'
                              : 'Отправить повторно через $_resendTimer сек',
                          style: TextStyle(
                            color: _canResend ? IOSTheme.systemBlue : IOSTheme.labelTertiary,
                          ),
                        ),
                      ),
              ),

              const Spacer(),

              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: IOSTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: IOSTheme.labelSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Если код не пришел, проверьте правильность номера телефона или свяжитесь с поддержкой',
                        style: IOSTheme.footnote.copyWith(
                          color: IOSTheme.labelSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable iOS-style button
class IOSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;

  const IOSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? IOSTheme.bgSecondary : IOSTheme.systemBlue,
          foregroundColor: isSecondary ? IOSTheme.systemBlue : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IOSTheme.radiusLg),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
