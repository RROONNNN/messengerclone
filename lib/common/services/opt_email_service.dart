import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/cupertino.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:messenger_clone/common/services/auth_service.dart';
import 'package:messenger_clone/common/services/network_utils.dart';

import 'app_write_config.dart';

class OTPEmailService {
  const OTPEmailService._();

  static const String _databaseId = AppwriteConfig.databaseId;
  static const String _userCollectionSMTPSERVER = AppwriteConfig.smtpServerCollectionId;
  static const int _maxAttempts = 5;
  static const Duration _otpExpiry = Duration(minutes: 5);

  static Future<void> sendOTPEmail(String email, String otp) async {
    return NetworkUtils.withNetworkCheck(() async {
      final expiry = DateTime.now().add(_otpExpiry);
      debugPrint("otp: $otp");
      final smtpServer = gmail('nguyen902993@gmail.com', 'lqpn cxdp tlti blhv');
      await AuthService.databases.createDocument(
        databaseId: _databaseId,
        collectionId: _userCollectionSMTPSERVER,
        documentId: ID.unique(),
        data: {
          'email': email,
          'otp': otp,
          'expiry': expiry.toIso8601String(),
          'attempts': 0,
        },
      );

      final message =
          Message()
            ..from = Address('nguyen902993@gmail.com', 'Messenger Clone')
            ..recipients.add(email)
            ..subject = 'Mã OTP xác thực'
            ..text =
                'Messenger Clone đã cho bạn mã OTP: $otp (hiệu lực 5 phút). \nCảm ơn bạn đã sử dụng dịch vụ của chúng tôi.';

      try {
        final sendOTP = await send(message, smtpServer);
        debugPrint("Message Sent : $sendOTP");
      } on MailerException catch (e) {
        debugPrint('Gửi OTP thất bại: $e');
      }
    });
  }

  static Future<bool> verifyOTP(String email, String userInput) async {
    return NetworkUtils.withNetworkCheck(() async {
      final response = await AuthService.databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _userCollectionSMTPSERVER,
        queries: [
          Query.equal('email', email),
          Query.orderDesc('expiry'),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return false;
      final doc = response.documents.first;
      final data = doc.data;

      if ((data['attempts'] ?? 0) >= _maxAttempts) {
        await _deleteOTP(doc.$id);
        throw Exception('Vượt quá số lần thử');
      }

      if (DateTime.parse(data['expiry']).isBefore(DateTime.now())) {
        await _deleteOTP(doc.$id);
        return false;
      }

      if (data['otp'] != userInput) {
        await _increaseAttemptCount(doc.$id, data['attempts'] ?? 0);
        return false;
      }

      await _deleteOTP(doc.$id);
      return true;
    });
  }

  static Future<void> _increaseAttemptCount(
    String documentId,
    int currentAttempts,
  ) async {
    await AuthService.databases.updateDocument(
      databaseId: _databaseId,
      collectionId: _userCollectionSMTPSERVER,
      documentId: documentId,
      data: {'attempts': currentAttempts + 1},
    );
  }

  static Future<void> _deleteOTP(String documentId) async {
    await AuthService.databases.deleteDocument(
      databaseId: _databaseId,
      collectionId: _userCollectionSMTPSERVER,
      documentId: documentId,
    );
  }

  static Future<num> getRemainingAttempts(String email) async {
    return NetworkUtils.withNetworkCheck(() async {
      try {
        final response = await AuthService.databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _userCollectionSMTPSERVER,
          queries: [
            Query.equal('email', email),
            Query.orderDesc('expiry'),
            Query.limit(1),
          ],
        );

        if (response.documents.isEmpty) return _maxAttempts;

        final data = response.documents.first.data;
        final usedAttempts = data['attempts'] ?? 0;
        return _maxAttempts - usedAttempts;
      } catch (e) {
        debugPrint('Lỗi khi lấy số lần thử: $e');
        return _maxAttempts;
      }
    });
  }

  static String generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}
