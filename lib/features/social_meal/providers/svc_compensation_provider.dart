// ignore_for_file: empty_catches
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/compensation_request.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STORAGE KEY
// ─────────────────────────────────────────────────────────────────────────────

const String _myRequestsKey = 'svc_my_compensations';

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

class SVCCompensationState {
  /// All requests — mock (other students) + the current user's submissions.
  final List<CompensationRequest> requests;
  final bool isLoaded;

  const SVCCompensationState({this.requests = const [], this.isLoaded = false});

  /// Requests submitted by the current device user.
  List<CompensationRequest> get myRequests =>
      requests.where((r) => r.studentId == 'current_user').toList();

  SVCCompensationState copyWith({
    List<CompensationRequest>? requests,
    bool? isLoaded,
  }) {
    return SVCCompensationState(
      requests: requests ?? this.requests,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class SVCCompensationNotifier extends StateNotifier<SVCCompensationState> {
  SVCCompensationNotifier() : super(const SVCCompensationState()) {
    _loadState();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_myRequestsKey);

      List<CompensationRequest> myRequests = [];
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        myRequests = list
            .map((e) => CompensationRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      state = SVCCompensationState(requests: myRequests, isLoaded: true);
    } catch (e) {
      state = SVCCompensationState(requests: [], isLoaded: true);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Submits a new compensation request on behalf of the current user.
  Future<void> submitRequest({
    required CompensationRequestType type,
    required DateTime mealDate,
    required String mealType,
    required String documentName,
  }) async {
    final req = CompensationRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      studentId: 'current_user',
      studentName: 'Me',
      type: type,
      mealDate: mealDate,
      mealType: mealType,
      documentName: documentName,
      status: CompensationStatus.pending,
      submittedAt: DateTime.now(),
    );

    final updated = [...state.requests, req];
    state = state.copyWith(requests: updated);

    // Persist only this user's own requests
    try {
      final prefs = await SharedPreferences.getInstance();
      final mine = updated
          .where((r) => r.studentId == 'current_user')
          .map((r) => r.toJson())
          .toList();
      await prefs.setString(_myRequestsKey, jsonEncode(mine));
    } catch (e) {
    }
  }

  /// Marks a request as approved (admin action).
  void approveRequest(String id) {
    state = state.copyWith(
      requests: state.requests.map((r) {
        if (r.id == id) return r.copyWith(status: CompensationStatus.approved);
        return r;
      }).toList(),
    );
  }

  /// Marks a request as rejected (admin action).
  void rejectRequest(String id) {
    state = state.copyWith(
      requests: state.requests.map((r) {
        if (r.id == id) return r.copyWith(status: CompensationStatus.rejected);
        return r;
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final svcCompensationProvider =
    StateNotifierProvider<SVCCompensationNotifier, SVCCompensationState>(
      (ref) => SVCCompensationNotifier(),
    );
