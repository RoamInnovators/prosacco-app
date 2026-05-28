import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import '../screens/statements/statement_models.dart';

/// Minimal HTTP integration for the member portal auth endpoints.
///
/// Backend base URL (hosted):
/// https://prosaccobackend.tracom.co.ke/
class ProsaccoMemberAuthApi {
  /// If the hosted backend is behind a prefix (e.g. `/api`), we fall back
  /// to `/api/member/login` when `/member/login` returns 404.
  static const String baseUrl = 'https://prosaccobackend.tracom.co.ke';
  static const String _deviceIdKey = 'prosacco_native_device_id';

  Future<Map<String, String>> _deviceHeaders() async {
    final sp = await SharedPreferences.getInstance();
    var deviceId = sp.getString(_deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      final random = Random.secure();
      final suffix = List<int>.generate(16, (_) => random.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      deviceId = 'prosacco-${DateTime.now().millisecondsSinceEpoch}-$suffix';
      await sp.setString(_deviceIdKey, deviceId);
    }
    return <String, String>{
      'X-Prosacco-Device-Id': deviceId,
      'X-Prosacco-Device-Platform': Platform.operatingSystem,
      'X-Prosacco-Device-OS': Platform.operatingSystemVersion,
      'X-Prosacco-Device-Brand': Platform.isIOS ? 'Apple' : 'Android',
      'X-Prosacco-Device-Model': Platform.operatingSystem,
    };
  }

  /// Member accounts overview (BOSA / FOSA / shares / FD / special savings).
  /// Used by the Accounts page.
  Future<_MemberAccountsOverviewResponse> fetchMemberAccountsOverview({
    required String token,
  }) async {
    final apiResults = await Future.wait([
      fetchMemberBosa(token: token),
      fetchMemberFosa(token: token),
      fetchMemberShareCapital(token: token),
      fetchMemberFixedDeposits(token: token),
      fetchMemberSpecialSavings(token: token),
    ]);

    return _MemberAccountsOverviewResponse(
      bosa: apiResults[0] as _MemberBosaAccountResponse,
      fosa: apiResults[1] as _MemberFosaAccountResponse,
      shareCapital: apiResults[2] as _MemberShareCapitalAccountResponse,
      fixedDeposits: apiResults[3] as _MemberFixedDepositsResponse,
      specialSavings: apiResults[4] as _MemberSpecialSavingsResponse,
    );
  }

  Future<_MemberBosaAccountResponse> fetchMemberBosa({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/bosa',
      '/api/member/accounts/bosa',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode == 404) continue;

        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load BOSA (${res.statusCode}).';
          throw msg;
        }

        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is! Map) throw 'Unexpected response from server.';

        final account = decoded['account'] as Map<String, dynamic>?;
        final txns = decoded['transactions'] as List?;
        final txnRows = <_MemberAccountTxnRow>[];
        if (txns is List) {
          for (final t in txns) {
            if (t is! Map) continue;
            txnRows.add(
              _MemberAccountTxnRow.fromBosaJson(t as Map<String, dynamic>),
            );
          }
        }

        return _MemberBosaAccountResponse(
          account: account == null ? null : _MemberAccountBosaModel.fromJson(account),
          transactions: txnRows,
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load BOSA.';
  }

  Future<_MemberFosaAccountResponse> fetchMemberFosa({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/fosa',
      '/api/member/accounts/fosa',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode == 404) continue;

        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load FOSA (${res.statusCode}).';
          throw msg;
        }

        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is! Map) throw 'Unexpected response from server.';

        final account = decoded['account'] as Map<String, dynamic>?;
        final txns = decoded['transactions'] as List?;
        final txnRows = <_MemberAccountTxnRow>[];
        if (txns is List) {
          for (final t in txns) {
            if (t is! Map) continue;
            txnRows.add(
              _MemberAccountTxnRow.fromFosaJson(t as Map<String, dynamic>),
            );
          }
        }

        return _MemberFosaAccountResponse(
          account: account == null ? null : _MemberAccountFosaModel.fromJson(account),
          transactions: txnRows,
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load FOSA.';
  }

  Future<_MemberShareCapitalAccountResponse> fetchMemberShareCapital({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/share-capital',
      '/api/member/accounts/share-capital',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode == 404) continue;

        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load shares (${res.statusCode}).';
          throw msg;
        }

        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is! Map) throw 'Unexpected response from server.';

        final account = decoded['account'] as Map<String, dynamic>?;
        final txns = decoded['transactions'] as List?;
        final txnRows = <_MemberShareCapitalTxnRow>[];
        if (txns is List) {
          for (final t in txns) {
            if (t is! Map) continue;
            txnRows.add(
              _MemberShareCapitalTxnRow.fromJson(t as Map<String, dynamic>),
            );
          }
        }

        return _MemberShareCapitalAccountResponse(
          account: account == null ? null : _MemberShareCapitalModel.fromJson(account),
          transactions: txnRows,
          pricePerShareCents: decoded['pricePerShareCents'],
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load shares.';
  }

  Future<_MemberFixedDepositsResponse> fetchMemberFixedDeposits({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/fixed-deposits',
      '/api/member/accounts/fixed-deposits',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode == 404) continue;

        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load fixed deposits (${res.statusCode}).';
          throw msg;
        }

        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is! Map) throw 'Unexpected response from server.';

        final depositsJson = decoded['deposits'] as List?;
        final deposits = <_MemberFixedDepositRow>[];
        if (depositsJson is List) {
          for (final d in depositsJson) {
            if (d is! Map) continue;
            deposits.add(_MemberFixedDepositRow.fromJson(d as Map<String, dynamic>));
          }
        }

        return _MemberFixedDepositsResponse(deposits: deposits);
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load fixed deposits.';
  }

  Future<_MemberSpecialSavingsResponse> fetchMemberSpecialSavings({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/special-savings',
      '/api/member/accounts/special-savings',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode == 404) continue;

        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load special savings (${res.statusCode}).';
          throw msg;
        }

        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is! Map) throw 'Unexpected response from server.';

        final accountsJson = decoded['accounts'] as List?;
        final accounts = <_MemberSpecialSavingsAccountRow>[];
        if (accountsJson is List) {
          for (final a in accountsJson) {
            if (a is! Map) continue;
            accounts.add(
              _MemberSpecialSavingsAccountRow.fromJson(a as Map<String, dynamic>),
            );
          }
        }

        return _MemberSpecialSavingsResponse(accounts: accounts);
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load special savings.';
  }

  /// Returns account options for UI dropdowns (deposit/withdraw/transfer).
  ///
  /// Note: this is optimized to re-use the same underlying account calls as
  /// [fetchMemberAccountsOverview].
  Future<List<_MemberAccountOptionUi>> fetchMemberAccountOptionsForPickers({
    required String token,
  }) async {
    final overview = await fetchMemberAccountsOverview(token: token);
    final options = <_MemberAccountOptionUi>[];

    String maskFromAccountNumber(String prefix, String accountNumber) {
      final s = accountNumber.trim();
      if (s.isEmpty) return prefix;
      final last4 = s.length >= 4 ? s.substring(s.length - 4) : s;
      return '$prefix •••• $last4';
    }

    final bosaAcc = overview.bosa.account;
    if (bosaAcc != null) {
      options.add(
        _MemberAccountOptionUi(
          id: 'bosa',
          name: 'BOSA Savings',
          mask: maskFromAccountNumber('ACC', bosaAcc.accountNumber),
          balanceCents: bosaAcc.balanceCents,
        ),
      );
    }

    final fosaAcc = overview.fosa.account;
    if (fosaAcc != null) {
      options.add(
        _MemberAccountOptionUi(
          id: 'fosa',
          name: 'FOSA Account',
          mask: maskFromAccountNumber('ACC', fosaAcc.accountNumber),
          balanceCents: fosaAcc.balanceCents,
        ),
      );
    }

    final shareAcc = overview.shareCapital.account;
    if (shareAcc != null) {
      options.add(
        _MemberAccountOptionUi(
          id: 'shares',
          name: 'Share Capital',
          mask: 'Member shares',
          balanceCents: shareAcc.totalAmountCents,
        ),
      );
    }

    for (final fd in overview.fixedDeposits.deposits) {
      options.add(
        _MemberAccountOptionUi(
          id: 'fd:${fd.id}',
          name: fd.productName,
          mask: maskFromAccountNumber('FD', fd.accountNumber),
          balanceCents: fd.principalCents,
        ),
      );
    }

    for (final ss in overview.specialSavings.accounts) {
      options.add(
        _MemberAccountOptionUi(
          id: 'ss:${ss.id}',
          name: ss.productName,
          mask: maskFromAccountNumber('SS', ss.accountNumber),
          balanceCents: ss.balanceCents,
        ),
      );
    }

    return options;
  }

  /// Public endpoint (no auth): list of Kenyan banks for withdrawal dropdowns.
  Future<List<String>> fetchPublicBanks() async {
    final tryPaths = <String>[
      '/public/banks',
      '/api/public/banks',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJsonNoAuth(uri);
        if (res.statusCode == 404) continue;

        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load banks (${res.statusCode}).';
          throw msg;
        }

        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
        if (decoded is Map) {
          final banks = decoded['banks'];
          if (banks is List) {
            return banks.map((e) => e.toString()).toList();
          }
        }

        throw 'Unexpected banks response from server.';
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Failed to load banks.';
  }

  Future<MemberUtilityCatalog> fetchUtilityPaymentCatalog({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/utility-payments/catalog',
      '/api/member/utility-payments/catalog',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load bill payment options (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected bill payment options response.';
        return MemberUtilityCatalog.fromJson(decoded.cast<String, dynamic>());
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load bill payment options.';
  }

  Future<MemberUtilityValidation> validateUtilityPayment({
    required String token,
    required String paymentType,
    String? category,
    String? providerCode,
    String? customerReference,
    String? network,
    String? recipientPhone,
    String? productCode,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'paymentType': paymentType,
      'category': category,
      'providerCode': providerCode,
      'customerReference': customerReference,
      'network': network,
      'recipientPhone': recipientPhone,
      'productCode': productCode,
    });
    final tryPaths = <String>[
      '/member/utility-payments/validate',
      '/api/member/utility-payments/validate',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Could not validate details (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected validation response.';
        return MemberUtilityValidation.fromJson(decoded.cast<String, dynamic>());
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Could not validate details.';
  }

  Future<MemberUtilityRequestResult> submitUtilityPayment({
    required String token,
    required String paymentType,
    required int amountCents,
    required String paymentSource,
    String? category,
    String? providerCode,
    String? providerName,
    String? customerReference,
    String? customerName,
    String? recipientPhone,
    String? network,
    String? productCode,
    String? productName,
    String? sourcePhone,
    bool saveRecipient = false,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'paymentType': paymentType,
      'category': category,
      'providerCode': providerCode,
      'providerName': providerName,
      'customerReference': customerReference,
      'customerName': customerName,
      'recipientPhone': recipientPhone,
      'network': network,
      'productCode': productCode,
      'productName': productName,
      'amountCents': amountCents,
      'paymentSource': paymentSource,
      'sourcePhone': sourcePhone,
      'saveRecipient': saveRecipient,
    });
    final tryPaths = <String>[
      '/member/utility-payments/requests',
      '/api/member/utility-payments/requests',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Payment request failed (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected payment response.';
        return MemberUtilityRequestResult.fromJson(decoded.cast<String, dynamic>());
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Payment request failed.';
  }

  Future<String> initiateFosaDepositPaystack({
    required String token,
    required int amountCents,
  }) async {
    return _initiatePaystackDeposit(
      token: token,
      amountCents: amountCents,
      accountType: 'fosa',
    );
  }

  Future<String> initiateBosaDepositPaystack({
    required String token,
    required int amountCents,
  }) async {
    return _initiatePaystackDeposit(
      token: token,
      amountCents: amountCents,
      accountType: 'bosa',
    );
  }

  Future<String> _initiatePaystackDeposit({
    required String token,
    required int amountCents,
    required String accountType,
  }) async {
    final body = jsonEncode(<String, dynamic>{'amountCents': amountCents});
    final tryPaths = <String>[
      '/member/accounts/$accountType/deposit/paystack/initiate',
      '/api/member/accounts/$accountType/deposit/paystack/initiate',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        // initiate endpoints require member auth (requireMemberAuth).
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to initiate Paystack (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected response from server.';

        final url = decoded['authorizationUrl']?.toString();
        if (url == null || url.isEmpty) {
          throw 'Paystack authorizationUrl missing from response.';
        }
        return url;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Failed to initiate Paystack deposit.';
  }

  Future<MemberTransactionResult> withdrawFosa({
    required String token,
    required int amountCents,
    required String channel,
    String? phoneNumber,
    String? bankName,
    String? bankAccountNumber,
    String? securityOtpChallengeId,
    String? securityOtpCode,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'amountCents': amountCents,
      'channel': channel,
      'phoneNumber': phoneNumber,
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
      'securityOtpChallengeId': securityOtpChallengeId,
      'securityOtpCode': securityOtpCode,
    }..removeWhere((_, v) => v == null));

    final tryPaths = <String>[
      '/member/accounts/fosa/withdraw',
      '/api/member/accounts/fosa/withdraw',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 428 && decoded is Map && decoded['requiresOtp'] == true) {
            throw MemberSecurityOtpRequiredException(
              purpose: 'FOSA_WITHDRAWAL',
              amountCents: amountCents,
              message: decoded['error']?.toString() ?? 'OTP is required.',
            );
          }
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Withdrawal failed (${res.statusCode}).';
          throw msg;
        }
        return decoded is Map
            ? MemberTransactionResult.fromJson(decoded)
            : MemberTransactionResult(transactionRef: '');
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Withdrawal failed.';
  }

  Future<MemberTransactionResult> sendToMemberFosa({
    required String token,
    required String recipientMemberId,
    required int amountCents,
    String? securityOtpChallengeId,
    String? securityOtpCode,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'recipientMemberId': recipientMemberId,
      'amountCents': amountCents,
      'securityOtpChallengeId': securityOtpChallengeId,
      'securityOtpCode': securityOtpCode,
    }..removeWhere((_, v) => v == null));

    final tryPaths = <String>[
      '/member/accounts/fosa/send-to-member',
      '/api/member/accounts/fosa/send-to-member',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 428 && decoded is Map && decoded['requiresOtp'] == true) {
            throw MemberSecurityOtpRequiredException(
              purpose: 'FOSA_SEND_TO_MEMBER',
              amountCents: amountCents,
              message: decoded['error']?.toString() ?? 'OTP is required.',
            );
          }
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Transfer failed (${res.statusCode}).';
          throw msg;
        }
        return decoded is Map
            ? MemberTransactionResult.fromJson(decoded)
            : MemberTransactionResult(transactionRef: '');
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Transfer failed.';
  }

  /// Transfers funds from the member's own FOSA to their BOSA.
  ///
  /// Backend: `POST /member/accounts/fosa/transfer-to-bosa`
  Future<MemberTransactionResult> transferFosaToBosa({
    required String token,
    required int amountCents,
    String? securityOtpChallengeId,
    String? securityOtpCode,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'amountCents': amountCents,
      'securityOtpChallengeId': securityOtpChallengeId,
      'securityOtpCode': securityOtpCode,
    }..removeWhere((_, v) => v == null));
    final tryPaths = <String>[
      '/member/accounts/fosa/transfer-to-bosa',
      '/api/member/accounts/fosa/transfer-to-bosa',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 428 && decoded is Map && decoded['requiresOtp'] == true) {
            throw MemberSecurityOtpRequiredException(
              purpose: 'FOSA_TO_BOSA_TRANSFER',
              amountCents: amountCents,
              message: decoded['error']?.toString() ?? 'OTP is required.',
            );
          }
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Transfer failed (${res.statusCode}).';
          throw msg;
        }
        return decoded is Map
            ? MemberTransactionResult.fromJson(decoded)
            : MemberTransactionResult(transactionRef: '');
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Transfer failed.';
  }

  Future<MemberTransactionResult> transferBosaToFosa({
    required String token,
    required int amountCents,
    String? securityOtpChallengeId,
    String? securityOtpCode,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'amountCents': amountCents,
      'securityOtpChallengeId': securityOtpChallengeId,
      'securityOtpCode': securityOtpCode,
    }..removeWhere((_, v) => v == null));
    final tryPaths = <String>[
      '/member/accounts/bosa/transfer-to-fosa',
      '/api/member/accounts/bosa/transfer-to-fosa',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 428 && decoded is Map && decoded['requiresOtp'] == true) {
            throw MemberSecurityOtpRequiredException(
              purpose: 'BOSA_TO_FOSA_TRANSFER',
              amountCents: amountCents,
              message: decoded['error']?.toString() ?? 'OTP is required.',
            );
          }
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Transfer failed (${res.statusCode}).';
          throw msg;
        }
        return decoded is Map
            ? MemberTransactionResult.fromJson(decoded)
            : MemberTransactionResult(transactionRef: '');
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Transfer failed.';
  }

  Future<MemberTransactionOtpChallenge> requestTransactionOtp({
    required String token,
    required String purpose,
    required int amountCents,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'purpose': purpose,
      'amountCents': amountCents,
    });
    final tryPaths = <String>[
      '/member/accounts/security/otp/request',
      '/api/member/accounts/security/otp/request',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Could not send OTP (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected OTP response.';
        return MemberTransactionOtpChallenge(
          challengeId: decoded['challengeId']?.toString() ?? '',
          sentTo: decoded['sentTo']?.toString(),
          channel: decoded['channel']?.toString(),
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Could not send OTP.';
  }

  // ── Share Capital ──────────────────────────────────────────────────────────

  /// Fetches purchase context: price per share, FOSA/BOSA balances, max shares.
  ///
  /// Backend: `GET /member/accounts/share-capital/purchase-context`
  Future<SharePurchaseContext> fetchSharePurchaseContext({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/share-capital/purchase-context',
      '/api/member/accounts/share-capital/purchase-context',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load share purchase context (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected response from server.';
        return SharePurchaseContext.fromJson(decoded as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load share purchase context.';
  }

  /// Buys shares by debiting the member's FOSA account.
  ///
  /// Backend: `POST /member/accounts/share-capital/purchase/from-fosa`
  Future<MemberTransactionResult> buySharesFromFosa({
    required String token,
    required int amountCents,
  }) async {
    final body = jsonEncode(<String, dynamic>{'amountCents': amountCents});
    final tryPaths = <String>[
      '/member/accounts/share-capital/purchase/from-fosa',
      '/api/member/accounts/share-capital/purchase/from-fosa',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Share purchase failed (${res.statusCode}).';
          throw msg;
        }
        return decoded is Map
            ? MemberTransactionResult.fromJson(decoded)
            : MemberTransactionResult(transactionRef: '');
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Share purchase failed.';
  }

  /// Buys shares by debiting the member's BOSA account.
  ///
  /// Backend: `POST /member/accounts/share-capital/purchase/from-bosa`
  Future<MemberTransactionResult> buySharesFromBosa({
    required String token,
    required int amountCents,
  }) async {
    final body = jsonEncode(<String, dynamic>{'amountCents': amountCents});
    final tryPaths = <String>[
      '/member/accounts/share-capital/purchase/from-bosa',
      '/api/member/accounts/share-capital/purchase/from-bosa',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Share purchase failed (${res.statusCode}).';
          throw msg;
        }
        return decoded is Map
            ? MemberTransactionResult.fromJson(decoded)
            : MemberTransactionResult(transactionRef: '');
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Share purchase failed.';
  }

  /// Initiates a Paystack checkout for share purchase.
  ///
  /// Backend: `POST /member/accounts/share-capital/purchase/paystack/initiate`
  Future<String> initiateSharePurchasePaystack({
    required String token,
    required int amountCents,
  }) async {
    final body = jsonEncode(<String, dynamic>{'amountCents': amountCents});
    final tryPaths = <String>[
      '/member/accounts/share-capital/purchase/paystack/initiate',
      '/api/member/accounts/share-capital/purchase/paystack/initiate',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to initiate Paystack (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected response from server.';
        final url = decoded['authorizationUrl']?.toString();
        if (url == null || url.isEmpty) throw 'Paystack authorizationUrl missing.';
        return url;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to initiate Paystack share purchase.';
  }

  /// Verifies a Paystack share purchase by reference.
  ///
  /// Backend: `GET /member/accounts/share-capital/purchase/paystack/verify?reference=...`
  Future<bool> verifySharePurchasePaystack({
    required String token,
    required String reference,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/share-capital/purchase/paystack/verify',
      '/api/member/accounts/share-capital/purchase/paystack/verify',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: <String, String>{'reference': reference},
      );
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Verification failed (${res.statusCode}).';
          throw msg;
        }
        return decoded is Map && decoded['ok'] == true;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Share purchase verification failed.';
  }

  /// Returns statement-capable accounts for the member dropdown.
  ///
  /// Backend: `GET /member/statements/accounts`
  Future<List<StatementAccount>> fetchMemberStatementsAccounts({
    required String token,
  }) async {
    final accounts = await _fetchStatementAccountsList(token: token);
    try {
      final overview = await fetchMemberAccountsOverview(token: token);
      final enriched = accounts.map((account) {
        final type = (account.backendAccountType ?? '').toUpperCase();
        var balance = account.balance;
        switch (type) {
          case 'BOSA':
            balance = (overview.bosa.account?.balanceCents ?? 0) / 100.0;
          case 'FOSA':
            balance = (overview.fosa.account?.balanceCents ?? 0) / 100.0;
          case 'SHARES':
            balance =
                (overview.shareCapital.account?.totalAmountCents ?? 0) / 100.0;
          case 'FD':
            for (final fd in overview.fixedDeposits.deposits) {
              if (fd.id == account.id) {
                balance = fd.principalCents / 100.0;
                break;
              }
            }
          case 'SS':
          case 'SPECIAL_SAVINGS':
            for (final ss in overview.specialSavings.accounts) {
              if (ss.id == account.id) {
                balance = ss.balanceCents / 100.0;
                break;
              }
            }
          default:
            break;
        }
        return StatementAccount(
          id: account.id,
          name: account.name,
          accountMask: account.accountMask,
          balance: balance,
          tagline: account.tagline,
          backendAccountType: account.backendAccountType,
        );
      }).toList();

      final existingIds = enriched.map((a) => a.id).toSet();
      for (final ss in overview.specialSavings.accounts) {
        if (existingIds.contains(ss.id)) continue;
        enriched.add(
          StatementAccount(
            id: ss.id,
            name: ss.productName,
            accountMask: ss.accountNumber,
            balance: ss.balanceCents / 100.0,
            tagline: 'Special Savings',
            backendAccountType: 'SPECIAL_SAVINGS',
          ),
        );
      }

      return enriched;
    } catch (_) {
      return accounts;
    }
  }

  Future<List<StatementAccount>> _fetchStatementAccountsList({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/statements/accounts',
      '/api/member/statements/accounts',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load statement accounts (${res.statusCode}).';
          throw msg;
        }

        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is! Map) throw 'Unexpected response from server.';

        final accountsJson = decoded['accounts'];
        if (accountsJson is! List) throw 'Unexpected statement accounts response.';

        final accounts = <StatementAccount>[];
        for (final a in accountsJson) {
          if (a is! Map) continue;
          final type = a['type']?.toString();
          final label = a['label']?.toString();
          final accountNumber = a['accountNumber']?.toString();
          final id = a['id']?.toString();
          if (type == null || label == null || accountNumber == null || id == null) {
            continue;
          }
          accounts.add(
            StatementAccount(
              id: id,
              name: label,
              accountMask: accountNumber,
              balance: 0,
              tagline: type,
              backendAccountType: type,
            ),
          );
        }

        return accounts;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Failed to load statement accounts.';
  }

  /// Requests a statement to be emailed.
  ///
  /// Backend: `POST /member/statements/email` (stub: currently returns ok).
  Future<void> requestStatementEmail({
    required String token,
    required String accountType,
    required String from,
    required String to,
    required String email,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'accountType': accountType,
      'from': from,
      'to': to,
      'email': email,
    });

    final tryPaths = <String>[
      '/member/statements/email',
      '/api/member/statements/email',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Statement request failed (${res.statusCode}).';
          throw msg;
        }
        // Endpoint currently returns `{ ok: true, message: ... }`
        return;
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Statement request failed.';
  }

  /// Generates a statement for the given account type and date range.
  ///
  /// Backend: `GET /member/statements/generate?accountType=&from=&to=`
  Future<StatementGenerateResult> generateStatement({
    required String token,
    required String accountType,
    required String from,
    required String to,
  }) async {
    final tryPaths = <String>[
      '/member/statements/generate',
      '/api/member/statements/generate',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: <String, String>{
          'accountType': accountType,
          'from': from,
          'to': to,
        },
      );
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to generate statement (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected response from server.';
        return StatementGenerateResult.fromJson(decoded as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to generate statement.';
  }

  Future<Uint8List> downloadStatementPdf({
    required String token,
    required String accountType,
    required String from,
    required String to,
  }) async {
    final tryPaths = <String>[
      '/member/statements/pdf',
      '/api/member/statements/pdf',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: <String, String>{
          'accountType': accountType,
          'from': from,
          'to': to,
        },
      );
      try {
        final res = await _getBytes(uri, token: token);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          throw 'Failed to download statement PDF (${res.statusCode}).';
        }
        return res.bytes;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to download statement PDF.';
  }

  /// Returns the list of years that have statement data.
  ///
  /// Backend: `GET /member/statements/annual/years`
  Future<List<int>> fetchStatementYears({required String token}) async {
    final tryPaths = <String>[
      '/member/statements/annual/years',
      '/api/member/statements/annual/years',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load years (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected response.';
        final years = decoded['years'];
        if (years is List) return years.map((y) => (y as num).toInt()).toList();
        return <int>[];
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load statement years.';
  }

  /// Returns the annual summary for a given year.
  ///
  /// Backend: `GET /member/statements/annual/:year`
  Future<AnnualStatementSummary> fetchAnnualSummary({
    required String token,
    required int year,
  }) async {
    final tryPaths = <String>[
      '/member/statements/annual/$year',
      '/api/member/statements/annual/$year',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load annual summary (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected response.';
        return AnnualStatementSummary.fromJson(decoded as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load annual summary.';
  }

  Future<Map<String, dynamic>> requestLoanReport({
    required String token,
    required String loanAccountId,
  }) async {
    final body = jsonEncode({'loanAccountId': loanAccountId});
    final tryPaths = ['/documents/member/loan-reports/request', '/api/documents/member/loan-reports/request'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Loan report request failed (${res.statusCode}).';
        }
        return (decoded as Map?)?.cast<String, dynamic>() ?? {};
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Loan report request failed.';
  }

  Future<Map<String, dynamic>> loanReportPreview({
    required String token,
    required String documentId,
  }) async {
    final tryPaths = [
      '/documents/member/loan-reports/$documentId/preview',
      '/api/documents/member/loan-reports/$documentId/preview',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Preview failed (${res.statusCode}).';
        }
        return (decoded as Map?)?.cast<String, dynamic>() ?? {};
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Preview failed.';
  }

  Future<Map<String, dynamic>> loanReportDownload({
    required String token,
    required String documentId,
  }) async {
    final tryPaths = [
      '/documents/member/loan-reports/$documentId/download',
      '/api/documents/member/loan-reports/$documentId/download',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Download failed (${res.statusCode}).';
        }
        return (decoded as Map?)?.cast<String, dynamic>() ?? {};
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Download failed.';
  }

  Future<MemberProfileData> fetchMemberProfile({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/me/profile',
      '/api/member/me/profile',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load profile (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected profile response.';
        return MemberProfileData(
          fullName: decoded['fullName']?.toString() ?? '—',
          memberNumber: decoded['memberNumber']?.toString() ?? '—',
          phone: decoded['phone']?.toString() ?? '—',
          email: decoded['email']?.toString() ?? '—',
          nationalId: decoded['nationalId']?.toString() ?? '—',
          branchName: decoded['branchName']?.toString() ?? '—',
          avatarUrl: decoded['avatarUrl']?.toString(),
          gender: decoded['gender']?.toString(),
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load profile.';
  }

  Future<void> patchMemberProfile({
    required String token,
    String? phone,
    String? email,
    required String otpCode,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'phone': phone,
      'email': email,
      'otpCode': otpCode,
    }..removeWhere((_, v) => v == null));

    final tryPaths = <String>[
      '/member/me/profile',
      '/api/member/me/profile',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _patchJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to update profile (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to update profile.';
  }

  Future<void> requestProfileOtp({
    required String token,
    required String purpose,
  }) async {
    final body = jsonEncode(<String, dynamic>{'purpose': purpose});
    final tryPaths = <String>[
      '/member/me/profile/otp',
      '/api/member/me/profile/otp',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to send OTP (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to send OTP.';
  }

  Future<MemberSecurityData> fetchMemberSecurity({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/me/security',
      '/api/member/me/security',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load security (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected security response.';
        return MemberSecurityData(
          mfaEnabled: decoded['mfaEnabled'] == true,
          mfaMethod: decoded['mfaMethod']?.toString(),
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load security.';
  }

  Future<MemberMfaSetupResult> setupMemberMfa({
    required String token,
    required String method,
  }) async {
    final body = jsonEncode(<String, dynamic>{'method': method});
    final tryPaths = <String>[
      '/member/me/mfa/setup',
      '/api/member/me/mfa/setup',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'MFA setup failed (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected MFA setup response.';
        return MemberMfaSetupResult.fromJson(decoded.cast<String, dynamic>());
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'MFA setup failed.';
  }

  Future<void> verifyMemberMfaSetup({
    required String token,
    required String code,
  }) async {
    final body = jsonEncode(<String, dynamic>{'code': code});
    final tryPaths = <String>[
      '/member/me/mfa/verify',
      '/api/member/me/mfa/verify',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Invalid verification code.';
        }
        return;
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'MFA verification failed.';
  }

  Future<void> disableMemberMfa({
    required String token,
    required String password,
  }) async {
    final body = jsonEncode(<String, dynamic>{'password': password});
    final tryPaths = <String>[
      '/member/me/mfa/disable',
      '/api/member/me/mfa/disable',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Could not disable MFA.';
        }
        return;
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Could not disable MFA.';
  }

  Future<void> changeMemberPassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    final tryPaths = <String>[
      '/member/me/change-password',
      '/api/member/me/change-password',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to change password (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to change password.';
  }

  Future<List<MemberDeviceData>> fetchMemberDevices({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/me/devices',
      '/api/member/me/devices',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load devices (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected devices response.';
        final list = decoded['devices'];
        if (list is! List) return const [];
        return list
            .whereType<Map>()
            .map(
              (d) => MemberDeviceData(
                id: d['id']?.toString() ?? '',
                device: d['device']?.toString() ?? '—',
                browser: d['browser']?.toString() ?? '—',
                os: d['os']?.toString() ?? '—',
                ip: d['ip']?.toString() ?? '—',
                current: d['current'] == true,
              ),
            )
            .where((d) => d.id.isNotEmpty)
            .toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load devices.';
  }

  Future<void> revokeMemberDevice({
    required String token,
    required String deviceId,
  }) async {
    final tryPaths = <String>[
      '/member/me/devices/$deviceId',
      '/api/member/me/devices/$deviceId',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _delete(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to revoke device (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to revoke device.';
  }

  Future<List<MemberBeneficiaryData>> fetchMemberBeneficiaries({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/me/beneficiaries',
      '/api/member/me/beneficiaries',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load beneficiaries (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected beneficiaries response.';
        final list = decoded['beneficiaries'];
        if (list is! List) return const [];
        return list
            .whereType<Map>()
            .map(
              (b) => MemberBeneficiaryData(
                id: b['id']?.toString() ?? '',
                name: b['name']?.toString() ?? '—',
                fullName: b['fullName']?.toString() ?? b['name']?.toString() ?? '',
                relationship: b['relationship']?.toString() ?? '—',
                share: b['share']?.toString() ?? '—',
                nationalId: b['nationalId']?.toString() ?? '—',
                phone: b['phone']?.toString() ?? '',
                email: b['email']?.toString() ?? '',
                physicalAddress: b['physicalAddress']?.toString() ?? '',
                dateOfBirth: b['dateOfBirth']?.toString(),
                nominationPercent: int.tryParse(b['nominationPercent']?.toString() ?? ''),
                isSecondary: b['isSecondary'] == true,
              ),
            )
            .where((b) => b.id.isNotEmpty)
            .toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load beneficiaries.';
  }

  Future<void> saveMemberBeneficiary({
    required String token,
    String? id,
    required Map<String, dynamic> payload,
    required String otpCode,
  }) async {
    final body = jsonEncode(<String, dynamic>{...payload, 'otpCode': otpCode});
    final tryPaths = <String>[
      id == null ? '/member/me/beneficiaries' : '/member/me/beneficiaries/$id',
      id == null ? '/api/member/me/beneficiaries' : '/api/member/me/beneficiaries/$id',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = id == null
            ? await _postJson(uri, body, token: token)
            : await _patchJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to save beneficiary (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to save beneficiary.';
  }

  Future<void> deleteMemberBeneficiary({
    required String token,
    required String id,
    required String otpCode,
  }) async {
    final body = jsonEncode(<String, dynamic>{'otpCode': otpCode});
    final tryPaths = <String>[
      '/member/me/beneficiaries/$id',
      '/api/member/me/beneficiaries/$id',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      try {
        final request = await client.deleteUrl(uri);
        request.headers
          ..set(HttpHeaders.acceptHeader, 'application/json')
          ..set(HttpHeaders.contentTypeHeader, 'application/json')
          ..set('Authorization', 'Bearer $token');
        final deviceHeaders = await _deviceHeaders();
        deviceHeaders.forEach(request.headers.set);
        request.add(utf8.encode(body));
        final res = await request.close().timeout(const Duration(seconds: 20));
        final responseText =
            await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));
        final decoded = _tryDecodeJson(responseText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to delete beneficiary (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      } finally {
        client.close(force: true);
      }
    }
    throw lastError ?? 'Failed to delete beneficiary.';
  }

  Future<List<MemberTransferBeneficiaryData>> fetchTransferBeneficiaries({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/beneficiaries',
      '/api/member/accounts/beneficiaries',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load transfer beneficiaries (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected beneficiaries response.';
        final list = decoded['beneficiaries'];
        if (list is! List) return const [];
        return list
            .whereType<Map>()
            .map(MemberTransferBeneficiaryData.fromJson)
            .where((b) => b.id.isNotEmpty)
            .toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load transfer beneficiaries.';
  }

  Future<void> saveTransferBeneficiary({
    required String token,
    String? id,
    required Map<String, dynamic> payload,
  }) async {
    final body = jsonEncode(payload);
    final tryPaths = <String>[
      id == null ? '/member/accounts/beneficiaries' : '/member/accounts/beneficiaries/$id',
      id == null ? '/api/member/accounts/beneficiaries' : '/api/member/accounts/beneficiaries/$id',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = id == null
            ? await _postJson(uri, body, token: token)
            : await _patchJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to save transfer beneficiary (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to save transfer beneficiary.';
  }

  Future<void> deleteTransferBeneficiary({
    required String token,
    required String id,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/beneficiaries/$id',
      '/api/member/accounts/beneficiaries/$id',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _delete(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to delete transfer beneficiary (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to delete transfer beneficiary.';
  }

  Future<MemberFeePreview> fetchFeePreview({
    required String token,
    required String serviceType,
    required int amountCents,
    Map<String, dynamic>? context,
  }) async {
    final body = jsonEncode({
      'serviceType': serviceType,
      'amount': amountCents,
      if (context != null) 'context': context,
    });
    final tryPaths = [
      '/member/fees/calculate/preview',
      '/api/member/fees/calculate/preview',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to preview fee (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected fee preview response.';
        return MemberFeePreview.fromJson(decoded);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to preview fee.';
  }

  Future<MemberReceiptData> fetchMemberReceiptByReference({
    required String token,
    required String reference,
  }) async {
    final encoded = Uri.encodeComponent(reference);
    final tryPaths = [
      '/member/receipts/reference/$encoded',
      '/api/member/receipts/reference/$encoded',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load receipt (${res.statusCode}).';
        }
        if (decoded is! Map || decoded['receipt'] is! Map) {
          throw 'Unexpected receipt response.';
        }
        return MemberReceiptData.fromJson(
          (decoded['receipt'] as Map).cast<String, dynamic>(),
          decoded['saccoName']?.toString() ?? 'ProSacco',
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load receipt.';
  }

  Future<String> fetchMemberReceiptHtmlByReference({
    required String token,
    required String reference,
  }) async {
    final encoded = Uri.encodeComponent(reference);
    final tryPaths = [
      '/member/receipts/reference/$encoded/html',
      '/api/member/receipts/reference/$encoded/html',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          throw 'Failed to load receipt (${res.statusCode}).';
        }
        return res.bodyText;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load receipt.';
  }

  Future<ShareMarketplaceListingsResponse> fetchShareMarketplaceListings({
    required String token,
  }) async {
    final tryPaths = ['/member/shares/marketplace/listings', '/api/member/shares/marketplace/listings'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load marketplace (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected marketplace response.';
        return ShareMarketplaceListingsResponse.fromJson(decoded);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load marketplace.';
  }

  Future<List<ShareMarketplaceListing>> fetchMyShareListings({required String token}) async {
    final tryPaths = ['/member/shares/marketplace/my-listings', '/api/member/shares/marketplace/my-listings'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load my listings (${res.statusCode}).';
        }
        final list = decoded is Map ? decoded['listings'] : null;
        if (list is! List) return const [];
        return list.whereType<Map>().map(ShareMarketplaceListing.fromJson).toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load my listings.';
  }

  Future<List<ShareMarketplaceTrade>> fetchShareMarketplaceTrades({required String token}) async {
    final tryPaths = ['/member/shares/marketplace/my-trades', '/api/member/shares/marketplace/my-trades'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load trades (${res.statusCode}).';
        }
        final list = decoded is Map ? decoded['trades'] : null;
        if (list is! List) return const [];
        return list.whereType<Map>().map(ShareMarketplaceTrade.fromJson).toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load trades.';
  }

  Future<ShareMarketplaceValuation> fetchShareMarketplaceValuation({required String token}) async {
    final tryPaths = ['/member/shares/marketplace/valuation', '/api/member/shares/marketplace/valuation'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load valuation (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected valuation response.';
        return ShareMarketplaceValuation.fromJson(decoded);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load valuation.';
  }

  Future<void> createShareMarketplaceListing({
    required String token,
    required int shares,
    required int pricePerShareCents,
    String? expiresAt,
    String? notes,
  }) async {
    final body = jsonEncode({
      'shares': shares,
      'pricePerShareCents': pricePerShareCents,
      if (expiresAt != null) 'expiresAt': expiresAt,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    final tryPaths = ['/member/shares/marketplace/listings', '/api/member/shares/marketplace/listings'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to create listing (${res.statusCode}).';
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to create listing.';
  }

  Future<void> cancelShareMarketplaceListing({
    required String token,
    required String listingId,
  }) async {
    final tryPaths = [
      '/member/shares/marketplace/listings/$listingId/cancel',
      '/api/member/shares/marketplace/listings/$listingId/cancel',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _patchJson(uri, '{}', token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to cancel listing (${res.statusCode}).';
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to cancel listing.';
  }

  Future<void> buyShareMarketplaceListing({
    required String token,
    required String listingId,
    required int shares,
  }) async {
    final body = jsonEncode({'shares': shares});
    final tryPaths = [
      '/member/shares/marketplace/listings/$listingId/buy',
      '/api/member/shares/marketplace/listings/$listingId/buy',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to buy shares (${res.statusCode}).';
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to buy shares.';
  }

  Future<List<MemberKycDocumentData>> fetchMemberKycDocuments({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/me/kyc',
      '/api/member/me/kyc',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load KYC documents (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected KYC response.';
        final list = decoded['documents'];
        if (list is! List) return const [];
        return list
            .whereType<Map>()
            .map(
              (d) => MemberKycDocumentData(
                id: d['id']?.toString() ?? '',
                type: d['type']?.toString() ?? '—',
                number: d['number']?.toString() ?? '—',
                uploaded: d['uploaded']?.toString() ?? '—',
                expiry: d['expiry']?.toString() ?? '—',
                status: d['status']?.toString() ?? '—',
              ),
            )
            .where((d) => d.id.isNotEmpty)
            .toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load KYC documents.';
  }

  Future<List<MemberRecentTransactionData>> fetchMemberRecentTransactions({
    required String token,
    int limit = 15,
  }) async {
    final safeLimit = limit.clamp(1, 50);
    final tryPaths = <String>[
      '/member/me/recent-transactions?limit=$safeLimit',
      '/api/member/me/recent-transactions?limit=$safeLimit',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load recent transactions (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected recent transactions response.';
        final rows = decoded['transactions'];
        if (rows is! List) return const [];
        return rows
            .whereType<Map>()
            .map(
              (t) => MemberRecentTransactionData(
                date: t['date']?.toString() ?? '',
                description: t['desc']?.toString() ?? 'Transaction',
                amountCents: (t['amountCents'] is num)
                    ? (t['amountCents'] as num).toInt()
                    : int.tryParse(t['amountCents']?.toString() ?? '0') ?? 0,
                type: t['type']?.toString() ?? 'debit',
                account: t['account']?.toString() ?? '—',
              ),
            )
            .toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load recent transactions.';
  }

  Future<int> fetchUnreadNotificationsCount({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/me/notifications/unread-count',
      '/api/member/me/notifications/unread-count',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load unread count (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected unread count response.';
        final c = decoded['count'];
        if (c is num) return c.toInt();
        return int.tryParse(c?.toString() ?? '0') ?? 0;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load unread notifications.';
  }

  Future<List<MemberNotificationData>> fetchMemberNotifications({
    required String token,
    int limit = 50,
  }) async {
    final safeLimit = limit.clamp(1, 100);
    final tryPaths = <String>[
      '/member/me/notifications?limit=$safeLimit',
      '/api/member/me/notifications?limit=$safeLimit',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load notifications (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected notifications response.';
        final rows = decoded['notifications'];
        if (rows is! List) return const [];
        return rows
            .whereType<Map>()
            .map(
              (n) => MemberNotificationData(
                id: n['id']?.toString() ?? '',
                title: n['title']?.toString() ?? 'Notification',
                body: n['body']?.toString() ?? '',
                category: n['category']?.toString() ?? 'general',
                read: n['read'] == true,
                createdAt: n['createdAt']?.toString(),
              ),
            )
            .where((n) => n.id.isNotEmpty)
            .toList();
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load notifications.';
  }

  Future<void> markNotificationAsRead({
    required String token,
    required String notificationId,
  }) async {
    final tryPaths = <String>[
      '/member/me/notifications/$notificationId/read',
      '/api/member/me/notifications/$notificationId/read',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _patchJson(uri, '{}', token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to mark notification as read (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to mark notification as read.';
  }

  Future<void> markAllNotificationsRead({
    required String token,
  }) async {
    final tryPaths = <String>[
      '/member/me/notifications/mark-all-read',
      '/api/member/me/notifications/mark-all-read',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, '{}', token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to mark all as read (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to mark all as read.';
  }

  Future<void> registerPushToken({
    required String token,
    required String pushToken,
    String platform = 'mobile',
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'pushToken': pushToken,
      'platform': platform,
    });
    final tryPaths = <String>[
      '/member/me/push-token',
      '/api/member/me/push-token',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (res.statusCode == 404) continue;
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to register push token (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw lastError;
  }

  Future<_PaystackDepositVerifyResponse> verifyFosaDepositPaystack({
    required String token,
    required String reference,
  }) async {
    return _verifyPaystackDeposit(
      token: token,
      reference: reference,
      accountType: 'fosa',
    );
  }

  Future<_PaystackDepositVerifyResponse> verifyBosaDepositPaystack({
    required String token,
    required String reference,
  }) async {
    return _verifyPaystackDeposit(
      token: token,
      reference: reference,
      accountType: 'bosa',
    );
  }

  Future<_PaystackDepositVerifyResponse> _verifyPaystackDeposit({
    required String token,
    required String reference,
    required String accountType,
  }) async {
    final tryPaths = <String>[
      '/member/accounts/$accountType/deposit/paystack/verify?reference=${Uri.encodeQueryComponent(reference)}',
      '/api/member/accounts/$accountType/deposit/paystack/verify?reference=${Uri.encodeQueryComponent(reference)}',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        final errorMsg =
            (decoded is Map && decoded['error'] != null) ? decoded['error'].toString() : null;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final ok = decoded is Map ? decoded['ok'] : null;
          final message = (decoded is Map && decoded['message'] != null)
              ? decoded['message'].toString()
              : (errorMsg ?? 'Deposit verification failed.');
          return _PaystackDepositVerifyResponse(ok: ok == true, message: message);
        }

        if (decoded is! Map) {
          return const _PaystackDepositVerifyResponse(ok: false, message: 'Unexpected verification response.');
        }

        final ok = decoded['ok'] == true;
        final message = ok
            ? (decoded['message']?.toString() ?? 'Deposit verified.')
            : (decoded['message']?.toString() ??
                (decoded['error']?.toString() ?? 'Deposit verification failed.'));
        return _PaystackDepositVerifyResponse(
          ok: ok,
          message: message,
          transactionRef: decoded['transactionRef']?.toString(),
        );
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Deposit verification failed.';
  }

  Future<_MemberLoginResponse> login({
    required String login,
    required String password,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'login': login,
      'password': password,
    });

    final tryPaths = <String>[
      '/member/login',
      '/api/member/login',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body);
        final statusCode = res.statusCode;
        final responseText = res.bodyText;

        if (statusCode == 404 && path == '/member/login') {
          // Try the alternative prefix path.
          continue;
        }

        final decoded = _tryDecodeJson(responseText);
        if (statusCode < 200 || statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Login failed (${statusCode}).';
          throw msg;
        }

        if (decoded is! Map) {
          throw 'Unexpected response from server.';
        }

        final needsMfa = decoded['needsMfa'] == true;
        final needsDeviceBinding = decoded['needsDeviceBinding'] == true;
        final token = decoded['token'] as String?;
        final challengeId = decoded['challengeId'] as String?;
        final mfaMethod = decoded['mfaMethod'] as String?;
        final memberJson = decoded['member'] as Map?;
        final displayName = memberJson?['displayName'] as String?;

        return _MemberLoginResponse(
          token: token,
          needsMfa: needsMfa,
          needsDeviceBinding: needsDeviceBinding,
          deviceBindingChallengeId: challengeId,
          mfaMethod: mfaMethod,
          displayName: displayName,
        );
      } catch (e) {
        // If we threw a user-facing string (e.g. credential failure), stop
        // and propagate it to avoid overwriting with a later fallback.
        if (e is String) throw e;
        lastError = e;
      }
    }

    throw lastError ?? 'Login failed.';
  }

  Future<MemberTransactionOtpChallenge> requestPasswordReset({
    required String login,
  }) async {
    final body = jsonEncode(<String, dynamic>{'login': login});
    final tryPaths = <String>[
      '/member/forgot-password',
      '/api/member/forgot-password',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body);
        if (res.statusCode == 404 && path == '/member/forgot-password') continue;
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Could not request password reset (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected reset response.';
        return MemberTransactionOtpChallenge(
          challengeId: decoded['challengeId']?.toString() ?? '',
          sentTo: decoded['sentTo']?.toString(),
          channel: decoded['channel']?.toString(),
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Could not request password reset.';
  }

  Future<void> resetPassword({
    required String login,
    required String challengeId,
    required String code,
    required String password,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'login': login,
      'challengeId': challengeId,
      'code': code,
      'password': password,
    });
    final tryPaths = <String>[
      '/member/reset-password',
      '/api/member/reset-password',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body);
        if (res.statusCode == 404 && path == '/member/reset-password') continue;
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Password reset failed (${res.statusCode}).';
        }
        return;
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Password reset failed.';
  }

  Future<void> recordPrivacyConsent({
    required String token,
    required String policyVersion,
    String channel = 'MOBILE_APP',
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'channel': channel,
      'policyType': 'PRIVACY_POLICY',
      'policyVersion': policyVersion,
      'accepted': true,
      'metadata': {'source': 'mobile_app'},
    });
    final tryPaths = <String>[
      '/member/consents',
      '/api/member/consents',
    ];
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      final res = await _postJson(uri, body, token: token);
      if (res.statusCode == 404) continue;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        final decoded = _tryDecodeJson(res.bodyText);
        throw (decoded is Map && decoded['error'] != null)
            ? decoded['error'].toString()
            : 'Could not record privacy consent (${res.statusCode}).';
      }
      return;
    }
    // Older deployed backends may not expose the consent endpoint yet. Do not
    // block login; local consent version is still stored by the caller.
    return;
  }

  Future<void> resendOtp({required String token}) async {
    final body = jsonEncode(<String, dynamic>{'token': token});
    final tryPaths = <String>[
      '/member/resend-otp',
      '/api/member/resend-otp',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body);
        if (res.statusCode == 404 && path == '/member/resend-otp') continue;

        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to resend OTP (${res.statusCode}).';
          throw msg;
        }
        return;
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to resend OTP.';
  }

  Future<_MemberVerifyMfaResponse> verifyDeviceBinding({
    required String token,
    required String challengeId,
    required String code,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'token': token,
      'challengeId': challengeId,
      'code': code,
    });

    final tryPaths = <String>[
      '/member/device-binding/verify',
      '/api/member/device-binding/verify',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body);
        if (res.statusCode == 404 && path == '/member/device-binding/verify') continue;

        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Device verification failed (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected response from server.';

        final authToken = decoded['token'] as String?;
        final memberJson = decoded['member'] as Map?;
        final displayName = memberJson?['displayName'] as String?;
        if (authToken == null || authToken.isEmpty) {
          throw 'Device verification succeeded but token was missing.';
        }

        return _MemberVerifyMfaResponse(
          token: authToken,
          displayName: displayName,
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Device verification failed.';
  }

  Future<_MemberVerifyMfaResponse> verifyMfa({
    required String token,
    required String code,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'token': token,
      'code': code,
    });

    final tryPaths = <String>[
      '/member/verify-mfa',
      '/api/member/verify-mfa',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body);
        if (res.statusCode == 404 && path == '/member/verify-mfa') continue;

        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Verification failed (${res.statusCode}).';
          throw msg;
        }
        if (decoded is! Map) throw 'Unexpected response from server.';

        final authToken = decoded['token'] as String?;
        final memberJson = decoded['member'] as Map?;
        final displayName = memberJson?['displayName'] as String?;
        if (authToken == null || authToken.isEmpty) {
          throw 'Verification succeeded but token was missing.';
        }

        return _MemberVerifyMfaResponse(
          token: authToken,
          displayName: displayName,
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Verification failed.';
  }

  Future<_MemberMeSummaryResponse> fetchMeSummary({required String token}) async {
    final tryPaths = <String>[
      '/member/me/summary',
      '/api/member/me/summary',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode == 404) {
          // Try next prefix path.
          continue;
        }
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load summary (${res.statusCode}).';
          throw msg;
        }
        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is! Map) throw 'Unexpected response from server.';

        return _MemberMeSummaryResponse.fromJson(decoded as Map<String, dynamic>);
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? 'Failed to load member summary.';
  }

  /// Returns the sum of `loanAccount.balanceCents` for loan accounts with
  /// `loanAccount.status === "ACTIVE"`.
  Future<int> fetchActiveLoanBalanceCents({required String token}) async {
    final tryPaths = <String>[
      '/member/loans/applications',
      '/api/member/loans/applications',
    ];

    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        if (res.statusCode < 200 || res.statusCode >= 300) {
          final decoded = _tryDecodeJson(res.bodyText);
          final msg = (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load loan info (${res.statusCode}).';
          throw msg;
        }

        final decoded = _tryDecodeJson(res.bodyText);
        if (decoded is! Map) throw 'Unexpected response from server.';
        final items = decoded['items'];
        if (items is! List) return 0;

        var sum = 0;
        for (final item in items) {
          if (item is! Map) continue;
          final loanAccount = item['loanAccount'];
          if (loanAccount is! Map) continue;
          final status = loanAccount['status'];
          if (status != 'ACTIVE') continue;
          final balance = loanAccount['balanceCents'];
          if (balance is num) sum += balance.toInt();
        }
        return sum;
      } catch (e) {
        lastError = e;
        if (e?.toString().contains('404') == true) continue;
      }
    }

    throw lastError ?? 'Failed to load active loan balance.';
  }

  Future<_HttpResponse> _postJson(
    Uri uri,
    String jsonBody, {
    String? token,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await client.postUrl(uri);
      request.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set('Accept', 'application/json');
      final deviceHeaders = await _deviceHeaders();
      deviceHeaders.forEach(request.headers.set);

      if (token != null && token.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $token');
      }
      request.add(utf8.encode(jsonBody));

      final response = await request.close().timeout(const Duration(seconds: 40));
      final responseText =
          await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 40));

      return _HttpResponse(statusCode: response.statusCode, bodyText: responseText);
    } finally {
      client.close(force: true);
    }
  }

  dynamic _tryDecodeJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Future<_HttpResponse> _getJson(Uri uri, {required String token}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set('Authorization', 'Bearer $token');
      final deviceHeaders = await _deviceHeaders();
      deviceHeaders.forEach(request.headers.set);

      final response = await request.close().timeout(const Duration(seconds: 40));
      final responseText =
          await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 40));
      return _HttpResponse(statusCode: response.statusCode, bodyText: responseText);
    } finally {
      client.close(force: true);
    }
  }

  Future<_HttpBytesResponse> _getBytes(Uri uri, {required String token}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/pdf')
        ..set('Authorization', 'Bearer $token');
      final deviceHeaders = await _deviceHeaders();
      deviceHeaders.forEach(request.headers.set);

      final response = await request.close().timeout(const Duration(seconds: 60));
      final chunks = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 60))) {
        chunks.addAll(chunk);
      }
      final bytes = Uint8List.fromList(chunks);
      return _HttpBytesResponse(statusCode: response.statusCode, bytes: bytes);
    } finally {
      client.close(force: true);
    }
  }

  Future<_HttpResponse> _getJsonNoAuth(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(const Duration(seconds: 20));
      final responseText =
          await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));
      return _HttpResponse(statusCode: response.statusCode, bodyText: responseText);
    } finally {
      client.close(force: true);
    }
  }

  Future<_HttpResponse> _patchJson(
    Uri uri,
    String jsonBody, {
    required String token,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.openUrl('PATCH', uri);
      request.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/json')
        ..set('Accept', 'application/json')
        ..set('Authorization', 'Bearer $token');
      final deviceHeaders = await _deviceHeaders();
      deviceHeaders.forEach(request.headers.set);
      request.add(utf8.encode(jsonBody));

      final response = await request.close().timeout(const Duration(seconds: 20));
      final responseText =
          await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));
      return _HttpResponse(statusCode: response.statusCode, bodyText: responseText);
    } finally {
      client.close(force: true);
    }
  }

  Future<_HttpResponse> _delete(
    Uri uri, {
    required String token,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.deleteUrl(uri);
      request.headers
        ..set(HttpHeaders.acceptHeader, 'application/json')
        ..set('Authorization', 'Bearer $token');
      final deviceHeaders = await _deviceHeaders();
      deviceHeaders.forEach(request.headers.set);

      final response = await request.close().timeout(const Duration(seconds: 20));
      final responseText =
          await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));
      return _HttpResponse(statusCode: response.statusCode, bodyText: responseText);
    } finally {
      client.close(force: true);
    }
  }

  // ── Avatar upload ──────────────────────────────────────────────────────────

  /// POST /member/me/avatar — upload profile picture (multipart, field: avatar).
  Future<String> uploadMemberAvatar({
    required String token,
    required List<int> imageBytes,
    required String filename,
    required String mimeType,
  }) async {
    final tryPaths = ['/member/me/avatar', '/api/member/me/avatar'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      final boundary = '----ProSaccoBoundary${DateTime.now().millisecondsSinceEpoch}';
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      try {
        final request = await client.postUrl(uri);
        request.headers
          ..set('Authorization', 'Bearer $token')
          ..set('Content-Type', 'multipart/form-data; boundary=$boundary');

        final prefix = utf8.encode(
          '--$boundary\r\nContent-Disposition: form-data; name="avatar"; filename="$filename"\r\nContent-Type: $mimeType\r\n\r\n',
        );
        final suffix = utf8.encode('\r\n--$boundary--\r\n');
        request.add(prefix);
        request.add(imageBytes);
        request.add(suffix);

        final response = await request.close().timeout(const Duration(seconds: 30));
        final responseText = await response.transform(utf8.decoder).join();
        final decoded = _tryDecodeJson(responseText);

        if (response.statusCode == 404) continue;
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Upload failed (${response.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected upload response.';
        return decoded['avatarUrl']?.toString() ?? '';
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      } finally {
        client.close(force: true);
      }
    }
    throw lastError ?? 'Avatar upload failed.';
  }

  // ── Loans ──────────────────────────────────────────────────────────────────

  /// GET /member/loans/products — real loan products from the SACCO with
  /// eligibility flags and member max eligible amounts.
  Future<LoanProductsResponse> fetchLoanProducts({required String token}) async {
    final tryPaths = ['/member/loans/products', '/api/member/loans/products'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load loan products (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected loan products response.';
        final items = decoded['products'] as List? ?? [];
        return LoanProductsResponse(
          prereqOk: decoded['prereqOk'] == true,
          prereqMessage: (decoded['prereq'] as Map?)?['message']?.toString(),
          qualifyingSavingsCents: (decoded['qualifyingSavingsCents'] as num?)?.toInt() ?? 0,
          products: items.whereType<Map>().map(LoanProductData.fromJson).toList(),
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load loan products.';
  }

  /// GET /member/loans/applications — member's loan applications list.
  Future<List<LoanApplicationData>> fetchLoanApplications({required String token}) async {
    final tryPaths = ['/member/loans/applications', '/api/member/loans/applications'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load applications (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected applications response.';
        final items = decoded['items'] as List? ?? [];
        return items.whereType<Map>().map(LoanApplicationData.fromJson).toList();
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load loan applications.';
  }

  /// GET /member/loans/amortisation-preview — installment preview before applying.
  Future<AmortisationPreview> fetchAmortisationPreview({
    required String token,
    required String productId,
    required int amountCents,
    required int months,
  }) async {
    final tryPaths = ['/member/loans/amortisation-preview', '/api/member/loans/amortisation-preview'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: {
        'productId': productId,
        'amountCents': amountCents.toString(),
        'months': months.toString(),
      });
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load preview (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected preview response.';
        return AmortisationPreview.fromJson(decoded as Map<String, dynamic>);
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load amortisation preview.';
  }

  /// GET /member/loans/guarantor-search?q= — search members to add as guarantors.
  Future<List<GuarantorSearchResult>> searchGuarantors({
    required String token,
    required String query,
  }) async {
    if (query.trim().length < 2) return [];
    final tryPaths = ['/member/loans/guarantor-search', '/api/member/loans/guarantor-search'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path').replace(queryParameters: {'q': query.trim()});
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Search failed (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected search response.';
        final members = decoded['members'] as List? ?? [];
        return members.whereType<Map>().map((m) => GuarantorSearchResult(
          id: m['id']?.toString() ?? '',
          memberNumber: m['memberNumber']?.toString() ?? '',
          fullName: m['fullName']?.toString() ?? 'Member',
        )).where((r) => r.id.isNotEmpty).toList();
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Guarantor search failed.';
  }

  /// POST /member/loans/applications — submit a loan application.
  Future<Map<String, dynamic>> submitLoanApplication({
    required String token,
    required String loanProductId,
    required int requestedAmountCents,
    required int repaymentMonths,
    required String disbursementMethod,
    Map<String, dynamic>? disbursementDestination,
    String? purpose,
    List<LoanGuarantorInput>? guarantors,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'loanProductId': loanProductId,
      'requestedAmountCents': requestedAmountCents,
      'repaymentMonths': repaymentMonths,
      'disbursementMethod': disbursementMethod,
      if (disbursementDestination != null) 'disbursementDestination': disbursementDestination,
      if (purpose != null) 'purpose': purpose,
      if (guarantors != null && guarantors.isNotEmpty)
        'guarantors': guarantors.map((g) => g.toJson()).toList(),
    });
    final tryPaths = ['/member/loans/applications', '/api/member/loans/applications'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Application failed (${res.statusCode}).';
        }
        return (decoded as Map?)?.cast<String, dynamic>() ?? {};
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Loan application failed.';
  }

  /// GET /member/loans/guarantor/inbox — pending guarantor requests for this member.
  Future<List<GuarantorInboxItem>> fetchGuarantorInbox({required String token}) async {
    final tryPaths = ['/member/loans/guarantor/inbox', '/api/member/loans/guarantor/inbox'];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _getJson(uri, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Failed to load guarantor inbox (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected inbox response.';
        final items = decoded['items'] as List? ?? [];
        return items.whereType<Map>().map(GuarantorInboxItem.fromJson).toList();
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Failed to load guarantor inbox.';
  }

  /// POST /member/loans/guarantor/:id/mfa-challenge — request OTP for consent.
  Future<GuarantorMfaChallenge> requestGuarantorMfaChallenge({
    required String token,
    required String requestId,
  }) async {
    final tryPaths = [
      '/member/loans/guarantor/$requestId/mfa-challenge',
      '/api/member/loans/guarantor/$requestId/mfa-challenge',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, '{}', token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'MFA challenge failed (${res.statusCode}).';
        }
        if (decoded is! Map) throw 'Unexpected MFA challenge response.';
        return GuarantorMfaChallenge(
          method: decoded['method']?.toString() ?? 'SMS',
          challengeId: decoded['challengeId']?.toString(),
        );
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'MFA challenge failed.';
  }

  /// POST /member/loans/guarantor/:id/consent — submit OTP to consent.
  Future<void> submitGuarantorConsent({
    required String token,
    required String requestId,
    required String code,
    String? challengeId,
  }) async {
    final body = jsonEncode(<String, dynamic>{
      'code': code,
      if (challengeId != null) 'challengeId': challengeId,
    });
    final tryPaths = [
      '/member/loans/guarantor/$requestId/consent',
      '/api/member/loans/guarantor/$requestId/consent',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Consent failed (${res.statusCode}).';
        }
        return;
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Consent submission failed.';
  }

  /// POST /member/loans/guarantor/:id/decline — decline a guarantor request.
  Future<void> declineGuarantorRequest({
    required String token,
    required String requestId,
    required String reason,
  }) async {
    final body = jsonEncode(<String, dynamic>{'reason': reason});
    final tryPaths = [
      '/member/loans/guarantor/$requestId/decline',
      '/api/member/loans/guarantor/$requestId/decline',
    ];
    dynamic lastError;
    for (final path in tryPaths) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final res = await _postJson(uri, body, token: token);
        final decoded = _tryDecodeJson(res.bodyText);
        if (res.statusCode == 404) continue;
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw (decoded is Map && decoded['error'] != null)
              ? decoded['error'].toString()
              : 'Decline failed (${res.statusCode}).';
        }
        return;
      } catch (e) {
        if (e is String) throw e;
        lastError = e;
      }
    }
    throw lastError ?? 'Decline failed.';
  }
}

class _MemberLoginResponse {
  _MemberLoginResponse({
    required this.token,
    required this.needsMfa,
    required this.needsDeviceBinding,
    required this.deviceBindingChallengeId,
    required this.mfaMethod,
    required this.displayName,
  });

  final String? token;
  final bool needsMfa;
  final bool needsDeviceBinding;
  final String? deviceBindingChallengeId;
  final String? mfaMethod;
  final String? displayName;
}

class _MemberVerifyMfaResponse {
  _MemberVerifyMfaResponse({required this.token, required this.displayName});

  final String token;
  final String? displayName;
}

class _HttpResponse {
  _HttpResponse({required this.statusCode, required this.bodyText});

  final int statusCode;
  final String bodyText;
}

class _HttpBytesResponse {
  _HttpBytesResponse({required this.statusCode, required this.bytes});

  final int statusCode;
  final Uint8List bytes;
}

class MemberSecurityOtpRequiredException implements Exception {
  MemberSecurityOtpRequiredException({
    required this.purpose,
    required this.amountCents,
    required this.message,
  });

  final String purpose;
  final int amountCents;
  final String message;

  @override
  String toString() => message;
}

class MemberTransactionOtpChallenge {
  MemberTransactionOtpChallenge({
    required this.challengeId,
    this.sentTo,
    this.channel,
  });

  final String challengeId;
  final String? sentTo;
  final String? channel;
}

class MemberUtilityCatalog {
  MemberUtilityCatalog({
    required this.enabled,
    required this.provider,
    required this.providerMode,
    required this.displayName,
    required this.categories,
    required this.billers,
    required this.networks,
    required this.paymentSources,
    required this.mpesaEnabled,
  });

  final bool enabled;
  final String provider;
  final String providerMode;
  final String displayName;
  final List<MemberUtilityCategory> categories;
  final List<MemberUtilityBiller> billers;
  final List<MemberUtilityNetwork> networks;
  final List<String> paymentSources;
  final bool mpesaEnabled;

  factory MemberUtilityCatalog.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
      if (raw is! List) return <T>[];
      return raw.whereType<Map>().map((e) => parse(e.cast<String, dynamic>())).toList();
    }

    return MemberUtilityCatalog(
      enabled: json['enabled'] == true,
      provider: json['provider']?.toString() ?? 'MANUAL',
      providerMode: json['providerMode']?.toString() ?? 'FRAMEWORK_ONLY',
      displayName: json['displayName']?.toString() ?? 'SACCO payment provider',
      categories: parseList(json['categories'], MemberUtilityCategory.fromJson),
      billers: parseList(json['billers'], MemberUtilityBiller.fromJson),
      networks: parseList(json['networks'], MemberUtilityNetwork.fromJson),
      paymentSources: (json['paymentSources'] is List)
          ? (json['paymentSources'] as List).map((e) => e.toString()).toList()
          : const ['FOSA'],
      mpesaEnabled: json['mpesaEnabled'] == true,
    );
  }
}

class MemberUtilityCategory {
  MemberUtilityCategory({
    required this.code,
    required this.label,
    required this.icon,
    required this.providerHint,
    required this.billerCount,
  });

  final String code;
  final String label;
  final String icon;
  final String providerHint;
  final int billerCount;

  factory MemberUtilityCategory.fromJson(Map<String, dynamic> json) {
    return MemberUtilityCategory(
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      providerHint: json['providerHint']?.toString() ?? '',
      billerCount: json['billerCount'] is num ? (json['billerCount'] as num).toInt() : 0,
    );
  }
}

class MemberUtilityBiller {
  MemberUtilityBiller({
    required this.code,
    required this.name,
    required this.category,
    this.logoUrl,
    this.minAmountCents = 0,
  });

  final String code;
  final String name;
  final String category;
  final String? logoUrl;
  final int minAmountCents;

  factory MemberUtilityBiller.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
    return MemberUtilityBiller(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      minAmountCents: toInt(json['minAmountCents']),
    );
  }
}

class MemberUtilityNetwork {
  MemberUtilityNetwork({
    required this.code,
    required this.name,
    this.logoUrl,
    this.bundles = const [],
  });

  final String code;
  final String name;
  final String? logoUrl;
  final List<MemberDataBundle> bundles;

  factory MemberUtilityNetwork.fromJson(Map<String, dynamic> json) {
    final bundlesRaw = json['bundles'];
    return MemberUtilityNetwork(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      bundles: bundlesRaw is List
          ? bundlesRaw.whereType<Map>().map((e) => MemberDataBundle.fromJson(e.cast<String, dynamic>())).toList()
          : const [],
    );
  }
}

class MemberDataBundle {
  MemberDataBundle({
    required this.code,
    required this.name,
    required this.amountCents,
    this.validity,
  });

  final String code;
  final String name;
  final int amountCents;
  final String? validity;

  factory MemberDataBundle.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
    return MemberDataBundle(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      amountCents: toInt(json['amountCents']),
      validity: json['validity']?.toString(),
    );
  }
}

class MemberUtilityValidation {
  MemberUtilityValidation({
    required this.message,
    this.customerName,
  });

  final String message;
  final String? customerName;

  factory MemberUtilityValidation.fromJson(Map<String, dynamic> json) {
    return MemberUtilityValidation(
      message: json['message']?.toString() ?? 'Reference accepted.',
      customerName: json['customerName']?.toString(),
    );
  }
}

class MemberUtilityRequestResult {
  MemberUtilityRequestResult({
    required this.status,
    required this.transactionRef,
    required this.message,
    this.requestId,
  });

  final String status;
  final String transactionRef;
  final String message;
  final String? requestId;

  factory MemberUtilityRequestResult.fromJson(Map<String, dynamic> json) {
    return MemberUtilityRequestResult(
      status: json['status']?.toString() ?? 'PENDING_PROVIDER',
      transactionRef: json['transactionRef']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Payment request recorded.',
      requestId: json['requestId']?.toString(),
    );
  }
}

class MemberProfileData {
  MemberProfileData({
    required this.fullName,
    required this.memberNumber,
    required this.phone,
    required this.email,
    required this.nationalId,
    required this.branchName,
    this.avatarUrl,
    this.gender,
  });

  final String fullName;
  final String memberNumber;
  final String phone;
  final String email;
  final String nationalId;
  final String branchName;
  final String? avatarUrl;
  final String? gender;
}

class MemberSecurityData {
  MemberSecurityData({
    required this.mfaEnabled,
    required this.mfaMethod,
  });

  final bool mfaEnabled;
  final String? mfaMethod;
}

class MemberMfaSetupResult {
  MemberMfaSetupResult({
    required this.method,
    this.secret,
    this.manualEntry,
    this.otpauthUrl,
  });

  final String method;
  final String? secret;
  final String? manualEntry;
  final String? otpauthUrl;

  factory MemberMfaSetupResult.fromJson(Map<String, dynamic> json) {
    return MemberMfaSetupResult(
      method: json['method']?.toString() ?? 'sms',
      secret: json['secret']?.toString(),
      manualEntry: json['manualEntry']?.toString(),
      otpauthUrl: json['otpauthUrl']?.toString(),
    );
  }
}

class MemberDeviceData {
  MemberDeviceData({
    required this.id,
    required this.device,
    required this.browser,
    required this.os,
    required this.ip,
    required this.current,
  });

  final String id;
  final String device;
  final String browser;
  final String os;
  final String ip;
  final bool current;
}

class MemberBeneficiaryData {
  MemberBeneficiaryData({
    required this.id,
    required this.name,
    required this.fullName,
    required this.relationship,
    required this.share,
    required this.nationalId,
    required this.phone,
    required this.email,
    required this.physicalAddress,
    required this.dateOfBirth,
    required this.nominationPercent,
    required this.isSecondary,
  });

  final String id;
  final String name;
  final String fullName;
  final String relationship;
  final String share;
  final String nationalId;
  final String phone;
  final String email;
  final String physicalAddress;
  final String? dateOfBirth;
  final int? nominationPercent;
  final bool isSecondary;
}

class MemberTransferBeneficiaryData {
  MemberTransferBeneficiaryData({
    required this.id,
    required this.type,
    required this.nickname,
    this.recipientMemberNumber,
    this.recipientName,
    this.phone,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.mobileNetwork,
    required this.isFavorite,
  });

  final String id;
  final String type;
  final String nickname;
  final String? recipientMemberNumber;
  final String? recipientName;
  final String? phone;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? mobileNetwork;
  final bool isFavorite;

  factory MemberTransferBeneficiaryData.fromJson(Map json) {
    return MemberTransferBeneficiaryData(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'INTERNAL_MEMBER',
      nickname: json['nickname']?.toString() ?? '',
      recipientMemberNumber: json['recipientMemberNumber']?.toString(),
      recipientName: json['recipientName']?.toString(),
      phone: json['phone']?.toString(),
      bankName: json['bankName']?.toString(),
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      bankAccountName: json['bankAccountName']?.toString(),
      mobileNetwork: json['mobileNetwork']?.toString(),
      isFavorite: json['isFavorite'] == true,
    );
  }
}

int _shareMarketplaceToInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class MemberFeePreview {
  MemberFeePreview({
    required this.feeAmount,
    required this.totalAmount,
    this.scheduleName,
    this.calculationMethod,
  });

  final int feeAmount;
  final int totalAmount;
  final String? scheduleName;
  final String? calculationMethod;

  factory MemberFeePreview.fromJson(Map json) {
    return MemberFeePreview(
      feeAmount: _shareMarketplaceToInt(json['feeAmount']),
      totalAmount: _shareMarketplaceToInt(json['totalAmount']),
      scheduleName: json['scheduleName']?.toString(),
      calculationMethod: json['calculationMethod']?.toString(),
    );
  }
}

class MemberTransactionResult {
  MemberTransactionResult({
    required this.transactionRef,
    this.amountCents,
    this.feeCents,
    this.message,
  });

  final String transactionRef;
  final int? amountCents;
  final int? feeCents;
  final String? message;

  factory MemberTransactionResult.fromJson(Map json) {
    return MemberTransactionResult(
      transactionRef: json['transactionRef']?.toString() ?? '',
      amountCents: json['amountCents'] == null
          ? null
          : _shareMarketplaceToInt(json['amountCents']),
      feeCents: json['feeCents'] == null
          ? null
          : _shareMarketplaceToInt(json['feeCents']),
      message: json['message']?.toString(),
    );
  }
}

class MemberReceiptData {
  MemberReceiptData({
    required this.saccoName,
    required this.receiptType,
    required this.reference,
    required this.accountType,
    required this.amountCents,
    required this.createdAt,
    this.paymentMethod,
    this.payload = const {},
  });

  final String saccoName;
  final String receiptType;
  final String reference;
  final String accountType;
  final int amountCents;
  final String createdAt;
  final String? paymentMethod;
  final Map<String, dynamic> payload;

  factory MemberReceiptData.fromJson(Map<String, dynamic> json, String saccoName) {
    final payload = json['payload'];
    return MemberReceiptData(
      saccoName: saccoName,
      receiptType: json['receiptType']?.toString() ?? 'RECEIPT',
      reference: json['reference']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? '',
      amountCents: _shareMarketplaceToInt(json['amountCents']),
      createdAt: json['createdAt']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString(),
      payload: payload is Map ? payload.cast<String, dynamic>() : const {},
    );
  }
}

class ShareMarketplaceListingsResponse {
  ShareMarketplaceListingsResponse({
    required this.listings,
    required this.memberNumber,
    required this.displayName,
  });

  final List<ShareMarketplaceListing> listings;
  final String memberNumber;
  final String displayName;

  factory ShareMarketplaceListingsResponse.fromJson(Map json) {
    final list = json['listings'];
    final me = json['me'] is Map ? json['me'] as Map : const {};
    return ShareMarketplaceListingsResponse(
      listings: list is List
          ? list.whereType<Map>().map(ShareMarketplaceListing.fromJson).toList()
          : const [],
      memberNumber: me['memberNumber']?.toString() ?? '',
      displayName: me['displayName']?.toString() ?? '',
    );
  }
}

class ShareMarketplaceListing {
  ShareMarketplaceListing({
    required this.id,
    required this.totalSharesOffered,
    required this.remainingShares,
    required this.pricePerShareCents,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.sellerName,
    this.sellerMemberNumber,
  });

  final String id;
  final int totalSharesOffered;
  final int remainingShares;
  final int pricePerShareCents;
  final String status;
  final String createdAt;
  final String? expiresAt;
  final String? sellerName;
  final String? sellerMemberNumber;

  int get totalAmountCents => remainingShares * pricePerShareCents;

  factory ShareMarketplaceListing.fromJson(Map json) {
    final seller = json['seller'] is Map ? json['seller'] as Map : const {};
    return ShareMarketplaceListing(
      id: json['id']?.toString() ?? '',
      totalSharesOffered: _shareMarketplaceToInt(json['totalSharesOffered']),
      remainingShares: _shareMarketplaceToInt(json['remainingShares']),
      pricePerShareCents: _shareMarketplaceToInt(json['pricePerShareCents']),
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString(),
      sellerName: seller['displayName']?.toString(),
      sellerMemberNumber: seller['memberNumber']?.toString(),
    );
  }
}

class ShareMarketplaceTrade {
  ShareMarketplaceTrade({
    required this.id,
    required this.side,
    required this.shares,
    required this.pricePerShareCents,
    required this.totalAmountCents,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String side;
  final int shares;
  final int pricePerShareCents;
  final int totalAmountCents;
  final String status;
  final String createdAt;

  factory ShareMarketplaceTrade.fromJson(Map json) {
    return ShareMarketplaceTrade(
      id: json['id']?.toString() ?? '',
      side: json['side']?.toString() ?? '',
      shares: _shareMarketplaceToInt(json['shares']),
      pricePerShareCents: _shareMarketplaceToInt(json['pricePerShareCents']),
      totalAmountCents: _shareMarketplaceToInt(json['totalAmountCents']),
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class ShareMarketplaceValuation {
  ShareMarketplaceValuation({
    required this.totalShares,
    required this.totalAmountCents,
    required this.pricePerShareCents,
    required this.markToMarketCents,
    required this.reservedShares,
    required this.availableToSellShares,
  });

  final int totalShares;
  final int totalAmountCents;
  final int pricePerShareCents;
  final int markToMarketCents;
  final int reservedShares;
  final int availableToSellShares;

  factory ShareMarketplaceValuation.fromJson(Map json) {
    return ShareMarketplaceValuation(
      totalShares: _shareMarketplaceToInt(json['totalShares']),
      totalAmountCents: _shareMarketplaceToInt(json['totalAmountCents']),
      pricePerShareCents: _shareMarketplaceToInt(json['pricePerShareCents']),
      markToMarketCents: _shareMarketplaceToInt(json['markToMarketCents']),
      reservedShares: _shareMarketplaceToInt(json['reservedShares']),
      availableToSellShares: _shareMarketplaceToInt(json['availableToSellShares']),
    );
  }
}

class MemberKycDocumentData {
  MemberKycDocumentData({
    required this.id,
    required this.type,
    required this.number,
    required this.uploaded,
    required this.expiry,
    required this.status,
  });

  final String id;
  final String type;
  final String number;
  final String uploaded;
  final String expiry;
  final String status;
}

class MemberRecentTransactionData {
  MemberRecentTransactionData({
    required this.date,
    required this.description,
    required this.amountCents,
    required this.type,
    required this.account,
  });

  final String date;
  final String description;
  final int amountCents;
  final String type;
  final String account;
}

class MemberNotificationData {
  MemberNotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String category;
  final bool read;
  final String? createdAt;
}

class _PaystackDepositVerifyResponse {
  const _PaystackDepositVerifyResponse({
    required this.ok,
    required this.message,
    this.transactionRef,
  });

  final bool ok;
  final String message;
  final String? transactionRef;
}

class _MemberMeSummaryResponse {
  _MemberMeSummaryResponse({
    required this.bosaBalanceCents,
    required this.fosaBalanceCents,
    required this.shareCapitalBalanceCents,
    required this.fixedDepositsBalanceCents,
  });

  final int bosaBalanceCents;
  final int fosaBalanceCents;
  final int shareCapitalBalanceCents;
  final int fixedDepositsBalanceCents;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory _MemberMeSummaryResponse.fromJson(Map<String, dynamic> json) {
    final savings = json['savings'] as Map?;
    final fosa = json['fosa'] as Map?;
    final shareCapital = json['shareCapital'] as Map?;
    final fixedDeposits = json['fixedDeposits'] as Map?;

    return _MemberMeSummaryResponse(
      bosaBalanceCents: _toInt(savings?['balanceCents']),
      fosaBalanceCents: _toInt(fosa?['balanceCents']),
      shareCapitalBalanceCents: _toInt(shareCapital?['balanceCents']),
      fixedDepositsBalanceCents: _toInt(fixedDeposits?['balanceCents']),
    );
  }
}

class _MemberAccountsOverviewResponse {
  _MemberAccountsOverviewResponse({
    required this.bosa,
    required this.fosa,
    required this.shareCapital,
    required this.fixedDeposits,
    required this.specialSavings,
  });

  final _MemberBosaAccountResponse bosa;
  final _MemberFosaAccountResponse fosa;
  final _MemberShareCapitalAccountResponse shareCapital;
  final _MemberFixedDepositsResponse fixedDeposits;
  final _MemberSpecialSavingsResponse specialSavings;
}

class _MemberAccountTxnRow {
  _MemberAccountTxnRow({
    required this.date,
    required this.desc,
    required this.creditCents,
    required this.debitCents,
    required this.balanceCents,
    required this.paymentMethod,
    required this.reference,
  });

  final dynamic date; // string from backend, keep dynamic for flexible parsing
  final String desc;
  final int? creditCents;
  final int? debitCents;
  final int balanceCents;
  final String? paymentMethod;
  final String? reference;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static _MemberAccountTxnRow fromBosaJson(Map<String, dynamic> json) {
    final date = json['date'];
    final desc = json['desc']?.toString() ?? '';
    final credit = _toNullableInt(json['credit']);
    final debit = _toNullableInt(json['debit']);
    final balance = _toInt(json['balanceCents'] ?? json['balance']);

    return _MemberAccountTxnRow(
      date: date,
      desc: desc,
      creditCents: credit,
      debitCents: debit,
      balanceCents: balance,
      paymentMethod: json['paymentMethod']?.toString(),
      reference: json['reference']?.toString(),
    );
  }

  static _MemberAccountTxnRow fromFosaJson(Map<String, dynamic> json) {
    final date = json['date'];
    final desc = json['desc']?.toString() ?? '';
    final amount = _toInt(json['amountCents']);
    final balance = _toInt(json['balanceCents']);
    final type = json['type']?.toString() ?? '';
    final incoming = type.toLowerCase() == 'credit';

    return _MemberAccountTxnRow(
      date: date,
      desc: desc,
      creditCents: incoming ? amount : null,
      debitCents: incoming ? null : amount,
      balanceCents: balance,
      paymentMethod: json['paymentMethod']?.toString(),
      reference: json['reference']?.toString(),
    );
  }
}

class _MemberAccountBosaModel {
  _MemberAccountBosaModel({
    required this.accountNumber,
    required this.productName,
    required this.balanceCents,
    required this.lockedForLoanCents,
    required this.interestRatePercent,
  });

  final String accountNumber;
  final String productName;
  final int balanceCents;
  final int lockedForLoanCents;
  final int? interestRatePercent;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory _MemberAccountBosaModel.fromJson(Map<String, dynamic> json) {
    return _MemberAccountBosaModel(
      accountNumber: json['accountNumber']?.toString() ?? '',
      productName: json['productName']?.toString() ?? 'Savings',
      balanceCents: _toInt(json['balanceCents']),
      lockedForLoanCents: _toInt(json['lockedForLoanCents']),
      interestRatePercent: _toNullableInt(json['interestRatePercent']),
    );
  }
}

class _MemberBosaAccountResponse {
  _MemberBosaAccountResponse({
    required this.account,
    required this.transactions,
  });

  final _MemberAccountBosaModel? account;
  final List<_MemberAccountTxnRow> transactions;
}

class _MemberAccountFosaModel {
  _MemberAccountFosaModel({
    required this.accountNumber,
    required this.balanceCents,
    required this.linkedPhoneMasked,
  });

  final String accountNumber;
  final int balanceCents;
  final String? linkedPhoneMasked;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory _MemberAccountFosaModel.fromJson(Map<String, dynamic> json) {
    return _MemberAccountFosaModel(
      accountNumber: json['accountNumber']?.toString() ?? '',
      balanceCents: _toInt(json['balanceCents']),
      linkedPhoneMasked: json['linkedPhoneMasked']?.toString(),
    );
  }
}

class _MemberFosaAccountResponse {
  _MemberFosaAccountResponse({
    required this.account,
    required this.transactions,
  });

  final _MemberAccountFosaModel? account;
  final List<_MemberAccountTxnRow> transactions;
}

class _MemberShareCapitalModel {
  _MemberShareCapitalModel({
    required this.accountNumber,
    required this.totalShares,
    required this.totalAmountCents,
  });

  final String accountNumber;
  final int totalShares;
  final int totalAmountCents;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory _MemberShareCapitalModel.fromJson(Map<String, dynamic> json) {
    return _MemberShareCapitalModel(
      accountNumber: json['accountNumber']?.toString() ?? '',
      totalShares: _toInt(json['totalShares']),
      totalAmountCents: _toInt(json['totalAmountCents']),
    );
  }
}

class _MemberShareCapitalTxnRow {
  _MemberShareCapitalTxnRow({
    required this.date,
    required this.typeLabel,
    required this.shares,
    required this.amountCents,
    required this.totalShares,
  });

  final dynamic date;
  final String typeLabel;
  final int shares;
  final int amountCents;
  final int totalShares;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory _MemberShareCapitalTxnRow.fromJson(Map<String, dynamic> json) {
    return _MemberShareCapitalTxnRow(
      date: json['date'],
      typeLabel: json['type']?.toString() ?? '',
      shares: _toInt(json['shares']),
      amountCents: _toInt(json['amountCents']),
      totalShares: _toInt(json['totalShares']),
    );
  }
}

class _MemberShareCapitalAccountResponse {
  _MemberShareCapitalAccountResponse({
    required this.account,
    required this.transactions,
    required this.pricePerShareCents,
  });

  final _MemberShareCapitalModel? account;
  final List<_MemberShareCapitalTxnRow> transactions;
  final dynamic pricePerShareCents;
}

class _MemberFixedDepositRow {
  _MemberFixedDepositRow({
    required this.id,
    required this.accountNumber,
    required this.productName,
    required this.principalCents,
    required this.interestRatePercent,
    required this.termMonths,
    required this.maturityDate,
    required this.maturityValueCents,
    required this.status,
  });

  final String id;
  final String accountNumber;
  final String productName;
  final int principalCents;
  final int interestRatePercent;
  final int? termMonths;
  final dynamic maturityDate;
  final int maturityValueCents;
  final String status;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory _MemberFixedDepositRow.fromJson(Map<String, dynamic> json) {
    return _MemberFixedDepositRow(
      id: json['id']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      productName: json['productName']?.toString() ?? 'Fixed Deposit',
      principalCents: _toInt(json['principalCents']),
      interestRatePercent: _toInt(json['interestRatePercent']),
      termMonths: _toNullableInt(json['termMonths']),
      maturityDate: json['maturityDate'],
      maturityValueCents: _toInt(json['maturityValueCents']),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class _MemberFixedDepositsResponse {
  _MemberFixedDepositsResponse({required this.deposits});

  final List<_MemberFixedDepositRow> deposits;
}

class _MemberSpecialSavingsAccountRow {
  _MemberSpecialSavingsAccountRow({
    required this.id,
    required this.productName,
    required this.productType,
    required this.balanceCents,
    required this.targetAmountCents,
    required this.label,
    required this.status,
    required this.lockOrMaturityDate,
    required this.accountNumber,
  });

  final String id;
  final String productName;
  final String? productType;
  final int balanceCents;
  final int targetAmountCents;
  final String? label;
  final String status;
  final dynamic lockOrMaturityDate;
  final String accountNumber;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory _MemberSpecialSavingsAccountRow.fromJson(Map<String, dynamic> json) {
    return _MemberSpecialSavingsAccountRow(
      id: json['id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? 'Special Savings',
      productType: json['productType']?.toString(),
      balanceCents: _toInt(json['balanceCents']),
      targetAmountCents: _toInt(json['targetAmountCents']),
      label: json['label']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      lockOrMaturityDate: json['lockOrMaturityDate'],
      accountNumber: json['accountNumber']?.toString() ?? '',
    );
  }
}

class _MemberSpecialSavingsResponse {
  _MemberSpecialSavingsResponse({required this.accounts});

  final List<_MemberSpecialSavingsAccountRow> accounts;
}

class _MemberAccountOptionUi {
  _MemberAccountOptionUi({
    required this.id,
    required this.name,
    required this.mask,
    required this.balanceCents,
  });

  final String id;
  final String name;
  final String mask;
  final int balanceCents;
}


// ── Share Capital Purchase Context ────────────────────────────────────────────

class SharePurchaseBosaInfo {
  SharePurchaseBosaInfo({
    required this.totalBalanceCents,
    required this.availableForPurchaseCents,
  });

  final int totalBalanceCents;
  final int availableForPurchaseCents;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory SharePurchaseBosaInfo.fromJson(Map<String, dynamic> json) {
    return SharePurchaseBosaInfo(
      totalBalanceCents: _toInt(json['totalBalanceCents']),
      availableForPurchaseCents: _toInt(json['availableForPurchaseCents']),
    );
  }
}

class SharePurchaseContext {
  SharePurchaseContext({
    required this.pricePerShareCents,
    required this.totalShares,
    required this.totalAmountCents,
    required this.maxSharesAllowed,
    required this.paystackConfigured,
    this.fosaBalanceCents,
    this.bosa,
  });

  final int pricePerShareCents;
  final int totalShares;
  final int totalAmountCents;
  final int? maxSharesAllowed;
  final bool paystackConfigured;
  final int? fosaBalanceCents;
  final SharePurchaseBosaInfo? bosa;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory SharePurchaseContext.fromJson(Map<String, dynamic> json) {
    return SharePurchaseContext(
      pricePerShareCents: _toInt(json['pricePerShareCents']),
      totalShares: _toInt(json['totalShares']),
      totalAmountCents: _toInt(json['totalAmountCents']),
      maxSharesAllowed: json['maxSharesAllowed'] != null ? _toInt(json['maxSharesAllowed']) : null,
      paystackConfigured: json['paystackConfigured'] == true,
      fosaBalanceCents: json['fosaBalanceCents'] != null ? _toInt(json['fosaBalanceCents']) : null,
      bosa: json['bosa'] is Map
          ? SharePurchaseBosaInfo.fromJson(json['bosa'] as Map<String, dynamic>)
          : null,
    );
  }
}

// ── Statement Generate Result ─────────────────────────────────────────────────

class StatementTxnRow {
  StatementTxnRow({
    required this.date,
    required this.type,
    required this.amountCents,
    this.balanceAfterCents,
    this.reference,
    this.shares,
  });

  final String date;
  final String type;
  final int amountCents;
  final int? balanceAfterCents;
  final String? reference;
  final int? shares; // for SHARES account type

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory StatementTxnRow.fromJson(Map<String, dynamic> json) {
    return StatementTxnRow(
      date: json['date']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amountCents: _toInt(json['amountCents']),
      balanceAfterCents: json['balanceAfterCents'] != null
          ? _toInt(json['balanceAfterCents'])
          : null,
      reference: json['reference']?.toString(),
      shares: json['shares'] != null ? _toInt(json['shares']) : null,
    );
  }

  bool get isCredit {
    const creditTypes = {
      'DEPOSIT', 'INTEREST_CREDIT', 'TRANSFER_IN', 'OPENING',
      'SALARY_CREDIT', 'PURCHASE',
    };
    return creditTypes.contains(type.toUpperCase());
  }

  double get amountKes => amountCents / 100.0;
  double? get balanceAfterKes =>
      balanceAfterCents != null ? balanceAfterCents! / 100.0 : null;

  String get typeLabel {
    return switch (type.toUpperCase()) {
      'DEPOSIT' => 'Deposit',
      'WITHDRAWAL' => 'Withdrawal',
      'TRANSFER_IN' => 'Transfer In',
      'TRANSFER_OUT' => 'Transfer Out',
      'INTEREST_CREDIT' => 'Interest Credit',
      'FEE' => 'Fee',
      'OPENING' => 'Opening',
      'SALARY_CREDIT' => 'Salary Credit',
      'PURCHASE' => 'Share Purchase',
      'EARLY_WITHDRAWAL' => 'Early Withdrawal',
      'MATURITY_PAYOUT' => 'Maturity Payout',
      _ => type,
    };
  }
}

class StatementGenerateResult {
  StatementGenerateResult({
    required this.accountType,
    required this.accountNumber,
    required this.from,
    required this.to,
    required this.transactions,
    required this.saccoName,
    required this.memberName,
  });

  final String accountType;
  final String accountNumber;
  final String from;
  final String to;
  final List<StatementTxnRow> transactions;
  final String saccoName;
  final String memberName;

  factory StatementGenerateResult.fromJson(Map<String, dynamic> json) {
    final txnsJson = json['transactions'];
    final txns = <StatementTxnRow>[];
    if (txnsJson is List) {
      for (final t in txnsJson) {
        if (t is Map<String, dynamic>) txns.add(StatementTxnRow.fromJson(t));
      }
    }
    final report = json['report'];
    final totals = report is Map ? report['totals'] : null;
    return StatementGenerateResult(
      accountType: json['accountType']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      transactions: txns,
      saccoName: totals is Map ? totals['sacco_name']?.toString() ?? 'ProSacco' : 'ProSacco',
      memberName: totals is Map ? totals['member']?.toString() ?? 'Member' : 'Member',
    );
  }

  double get totalCredits => transactions
      .where((t) => t.isCredit)
      .fold(0.0, (s, t) => s + t.amountKes);

  double get totalDebits => transactions
      .where((t) => !t.isCredit)
      .fold(0.0, (s, t) => s + t.amountKes);

  double? get closingBalance {
    for (final t in transactions.reversed) {
      if (t.balanceAfterKes != null) return t.balanceAfterKes;
    }
    return null;
  }

  double? get openingBalance {
    for (final t in transactions) {
      if (t.balanceAfterKes != null) {
        return t.balanceAfterKes! - (t.isCredit ? t.amountKes : -t.amountKes);
      }
    }
    return null;
  }
}

// ── Annual Statement Summary ──────────────────────────────────────────────────

class AnnualAccountSummary {
  AnnualAccountSummary({
    required this.accountNumber,
    required this.balanceCents,
    required this.transactionCount,
    this.totalAmountCents,
    this.totalShares,
  });

  final String accountNumber;
  final int balanceCents;
  final int transactionCount;
  final int? totalAmountCents;
  final int? totalShares;

  double get balanceKes => balanceCents / 100.0;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory AnnualAccountSummary.fromJson(Map<String, dynamic> json) {
    return AnnualAccountSummary(
      accountNumber: json['accountNumber']?.toString() ?? '',
      balanceCents: _toInt(json['balanceCents'] ?? json['totalAmountCents'] ?? 0),
      transactionCount: _toInt(json['transactionCount']),
      totalAmountCents: json['totalAmountCents'] != null
          ? _toInt(json['totalAmountCents'])
          : null,
      totalShares: json['totalShares'] != null
          ? _toInt(json['totalShares'])
          : null,
    );
  }
}

class AnnualStatementSummary {
  AnnualStatementSummary({
    required this.year,
    this.bosa,
    this.fosa,
    this.shareCapital,
    this.fixedDepositTotalCents,
    this.fixedDepositCount,
  });

  final int year;
  final AnnualAccountSummary? bosa;
  final AnnualAccountSummary? fosa;
  final AnnualAccountSummary? shareCapital;
  final int? fixedDepositTotalCents;
  final int? fixedDepositCount;

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory AnnualStatementSummary.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] as Map<String, dynamic>?;
    final fd = s?['fixedDeposits'] as Map<String, dynamic>?;
    return AnnualStatementSummary(
      year: _toInt(json['year']),
      bosa: s?['bosa'] is Map
          ? AnnualAccountSummary.fromJson(s!['bosa'] as Map<String, dynamic>)
          : null,
      fosa: s?['fosa'] is Map
          ? AnnualAccountSummary.fromJson(s!['fosa'] as Map<String, dynamic>)
          : null,
      shareCapital: s?['shareCapital'] is Map
          ? AnnualAccountSummary.fromJson(
              s!['shareCapital'] as Map<String, dynamic>)
          : null,
      fixedDepositTotalCents:
          fd != null ? _toInt(fd['totalCents'] ?? 0) : null,
      fixedDepositCount: fd != null ? _toInt(fd['accounts'] ?? 0) : null,
    );
  }
}

// ── Loan data models ──────────────────────────────────────────────────────────

class LoanProductData {
  LoanProductData({
    required this.id,
    required this.productName,
    required this.productCode,
    required this.loanCategory,
    required this.interestRatePercent,
    required this.minLoanAmountCents,
    required this.maxLoanAmountCents,
    required this.minRepaymentMonths,
    required this.maxRepaymentMonths,
    required this.guarantorsRequired,
    required this.memberMaxEligibleCents,
    required this.eligible,
    this.ineligibleReason,
    this.description,
    this.minGuarantors,
    this.maxGuarantors,
    this.guarantorSavingsLockPercent,
    this.maxGuaranteePerGuarantorPercent,
    this.qualifyingSavingsBasis,
  });

  final String id;
  final String productName;
  final String productCode;
  final String? loanCategory;
  final double interestRatePercent;
  final int minLoanAmountCents;
  final int maxLoanAmountCents;
  final int minRepaymentMonths;
  final int maxRepaymentMonths;
  final bool guarantorsRequired;
  final int memberMaxEligibleCents;
  final bool eligible;
  final String? ineligibleReason;
  final String? description;
  final int? minGuarantors;
  final int? maxGuarantors;
  final double? guarantorSavingsLockPercent;
  final double? maxGuaranteePerGuarantorPercent;
  final String? qualifyingSavingsBasis;

  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
  static double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  factory LoanProductData.fromJson(Map json) {
    return LoanProductData(
      id: json['id']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      loanCategory: json['loanCategory']?.toString(),
      interestRatePercent: _d(json['interestRatePercent']),
      minLoanAmountCents: _i(json['minLoanAmountCents']),
      maxLoanAmountCents: _i(json['maxLoanAmountCents']),
      minRepaymentMonths: _i(json['minRepaymentMonths']),
      maxRepaymentMonths: _i(json['maxRepaymentMonths']),
      guarantorsRequired: json['guarantorsRequired'] == true,
      memberMaxEligibleCents: _i(json['memberMaxEligibleCents']),
      eligible: json['eligible'] == true,
      ineligibleReason: json['ineligibleReason']?.toString(),
      description: json['description']?.toString(),
      minGuarantors: json['minGuarantors'] != null ? _i(json['minGuarantors']) : null,
      maxGuarantors: json['maxGuarantors'] != null ? _i(json['maxGuarantors']) : null,
      guarantorSavingsLockPercent: json['guarantorSavingsLockPercent'] != null ? _d(json['guarantorSavingsLockPercent']) : null,
      maxGuaranteePerGuarantorPercent: json['maxGuaranteePerGuarantorPercent'] != null ? _d(json['maxGuaranteePerGuarantorPercent']) : null,
      qualifyingSavingsBasis: json['qualifyingSavingsBasis']?.toString(),
    );
  }
}

class LoanProductsResponse {
  LoanProductsResponse({
    required this.prereqOk,
    required this.products,
    required this.qualifyingSavingsCents,
    this.prereqMessage,
  });

  final bool prereqOk;
  final String? prereqMessage;
  final int qualifyingSavingsCents;
  final List<LoanProductData> products;
}

class LoanApplicationData {
  LoanApplicationData({
    required this.id,
    required this.status,
    required this.requestedAmountCents,
    required this.repaymentMonths,
    required this.submittedAt,
    this.productName,
    this.productCode,
    this.loanAccountBalanceCents,
    this.loanAccountStatus,
    this.publicLoanId,
    this.loanAccountId,
  });

  final String id;
  final String status;
  final int requestedAmountCents;
  final int repaymentMonths;
  final String submittedAt;
  final String? productName;
  final String? productCode;
  final int? loanAccountBalanceCents;
  final String? loanAccountStatus;
  final String? publicLoanId;
  final String? loanAccountId;

  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  factory LoanApplicationData.fromJson(Map json) {
    final product = json['loanProduct'] as Map?;
    final loanAccount = json['loanAccount'] as Map?;
    return LoanApplicationData(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requestedAmountCents: _i(json['requestedAmountCents']),
      repaymentMonths: _i(json['repaymentMonths']),
      submittedAt: json['submittedAt']?.toString() ?? '',
      productName: product?['productName']?.toString(),
      productCode: product?['productCode']?.toString(),
      loanAccountBalanceCents: loanAccount != null ? _i(loanAccount['balanceCents']) : null,
      loanAccountStatus: loanAccount?['status']?.toString(),
      publicLoanId: json['publicLoanId']?.toString(),
      loanAccountId: loanAccount?['id']?.toString() ?? json['loanAccountId']?.toString(),
    );
  }
}

class AmortisationPreview {
  AmortisationPreview({
    required this.monthlyPaymentCents,
    required this.totalInterestCents,
    required this.totalRepayableCents,
    required this.bosaLockCents,
  });

  final int monthlyPaymentCents;
  final int totalInterestCents;
  final int totalRepayableCents;
  final int bosaLockCents;

  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  factory AmortisationPreview.fromJson(Map<String, dynamic> json) {
    return AmortisationPreview(
      monthlyPaymentCents: _i(json['monthlyPaymentCents']),
      totalInterestCents: _i(json['totalInterestCents']),
      totalRepayableCents: _i(json['totalRepayableCents']),
      bosaLockCents: _i(json['bosaLockCents']),
    );
  }
}

class GuarantorSearchResult {
  GuarantorSearchResult({
    required this.id,
    required this.memberNumber,
    required this.fullName,
  });

  final String id;
  final String memberNumber;
  final String fullName;
}

class LoanGuarantorInput {
  LoanGuarantorInput({
    required this.guarantorMemberId,
    required this.coverageCents,
    required this.requiredLockCents,
    this.requiredShareLockShares = 0,
  });

  final String guarantorMemberId;
  final int coverageCents;
  final int requiredLockCents;
  final int requiredShareLockShares;

  Map<String, dynamic> toJson() => {
    'guarantorMemberId': guarantorMemberId,
    'coverageCents': coverageCents,
    // Backend recalculates final BOSA/share lock from the loan product.
    'requiredLockCents': requiredLockCents,
  };
}

class GuarantorInboxItem {
  GuarantorInboxItem({
    required this.id,
    required this.applicationId,
    required this.borrowerMemberNumber,
    required this.productName,
    required this.requestedAmountCents,
    required this.coverageCents,
    required this.requiredLockCents,
    required this.requiredShareLockShares,
    required this.requestedAt,
    this.expiresAt,
  });

  final String id;
  final String applicationId;
  final String borrowerMemberNumber;
  final String productName;
  final int requestedAmountCents;
  final int coverageCents;
  final int requiredLockCents;
  final int requiredShareLockShares;
  final String requestedAt;
  final String? expiresAt;

  bool get isUrgent {
    if (expiresAt == null) return false;
    final exp = DateTime.tryParse(expiresAt!);
    if (exp == null) return false;
    return exp.difference(DateTime.now()).inHours < 24;
  }

  String get expiryLabel {
    if (expiresAt == null) return 'No expiry';
    final exp = DateTime.tryParse(expiresAt!);
    if (exp == null) return 'Unknown';
    final diff = exp.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return 'Expires in <1 hour';
    if (diff.inHours < 24) return 'Expires in ${diff.inHours}h';
    return 'Expires in ${diff.inDays}d';
  }

  static int _i(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  factory GuarantorInboxItem.fromJson(Map json) {
    final app = json['application'] as Map?;
    final product = app?['loanProduct'] as Map?;
    final member = app?['member'] as Map?;
    return GuarantorInboxItem(
      id: json['id']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      borrowerMemberNumber: member?['memberNumber']?.toString() ?? '—',
      productName: product?['productName']?.toString() ?? 'Loan',
      requestedAmountCents: _i(app?['requestedAmountCents'] ?? 0),
      coverageCents: _i(json['coverageCents'] ?? 0),
      requiredLockCents: _i(json['requiredLockCents'] ?? 0),
      requiredShareLockShares: _i(json['requiredShareLockShares'] ?? 0),
      requestedAt: json['requestedAt']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}

class GuarantorMfaChallenge {
  GuarantorMfaChallenge({required this.method, this.challengeId});

  final String method;
  final String? challengeId;
}
