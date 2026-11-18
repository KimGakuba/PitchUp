import 'package:cloud_functions/cloud_functions.dart';

import 'config.dart';

/// A user-facing error translated from a callable-function failure.
class AppException implements Exception {
  AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Single entry point for all callable Cloud Functions. Keeping the region
/// here prevents screens from ever calling a function directly.
class FunctionsApi {
  FunctionsApi({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    try {
      final result = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      throw AppException(_friendly(error), code: error.code);
    } catch (error) {
      throw AppException('Something went wrong. Please try again.');
    }
  }

  String _friendly(FirebaseFunctionsException error) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) return message;
    return switch (error.code) {
      'unauthenticated' => 'Please sign in again.',
      'permission-denied' => 'You do not have permission to do that.',
      'not-found' => 'That item no longer exists.',
      'already-exists' => 'That already exists.',
      'failed-precondition' => 'That action is not available right now.',
      'invalid-argument' => 'Please check the details and try again.',
      'unavailable' => 'Network unavailable. Check your connection.',
      'deadline-exceeded' => 'The request timed out. Try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
