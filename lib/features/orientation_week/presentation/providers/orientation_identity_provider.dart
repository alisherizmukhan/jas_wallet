import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_repository_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../domain/entities/orientation_identity.dart';
import 'orientation_repository_provider.dart';

/// The student's school — resolved automatically, never asked for.
///
/// The backend derives SSH/SEDS/…/NUFYP from the student's own record in the
/// SALTO directory (the same index that already governs their physical door
/// access), keyed off the student ID they registered with. There is nothing
/// for the student to declare: a code with no school in it cannot be
/// compared against anything, so the QR tasks simply wait — via [load], not
/// a picker — until this resolves.
class OrientationSchoolNotifier extends StateNotifier<AsyncValue<NuSchool?>> {
  OrientationSchoolNotifier(this._read, this._write, this._resolve)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Future<NuSchool?> Function() _read;
  final Future<void> Function(NuSchool) _write;

  /// Directory lookup — null when the student's record has no derivable
  /// school (e.g. staff, or a directory row SALTO hasn't mapped yet) or the
  /// network is down. [load] can simply be called again once that clears.
  final Future<NuSchool?> Function() _resolve;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      var school = await _read();
      if (school == null) {
        school = await _resolve();
        if (school != null) await _write(school);
      }
      state = AsyncValue.data(school);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final orientationSchoolProvider =
    StateNotifierProvider<OrientationSchoolNotifier, AsyncValue<NuSchool?>>((ref) {
  final repo = ref.watch(orientationRepositoryProvider);
  // Watched (not read) so the lookup reruns once the profile — and with it
  // the NU student ID — finishes loading after this provider was first built.
  final studentId =
      ref.watch(userProvider.select((user) => user.valueOrNull?.studentId));
  return OrientationSchoolNotifier(
    repo.getSchool,
    repo.setSchool,
    () async {
      if (studentId == null || studentId.trim().isEmpty) return null;
      try {
        final record =
            await ref.read(authRepositoryProvider).lookupStudentId(studentId);
        return NuSchoolX.fromCode(record.schoolCode);
      } catch (_) {
        // Offline or not in the directory — the manual picker still works.
        return null;
      }
    },
  );
});

/// This student's own QR payload, or null until their school is known.
///
/// Identity is assembled here rather than stored: the id and name belong to
/// the signed-in profile and must never drift from it, so Orientation Week
/// keeps only the one field that is genuinely its own.
final orientationIdentityProvider = Provider<OrientationIdentity?>((ref) {
  final school = ref.watch(orientationSchoolProvider).valueOrNull;
  final user = ref.watch(userProvider).valueOrNull;
  if (school == null || user == null) return null;

  return OrientationIdentity(
    // `studentId` is the real one where the profile carries it; the account id
    // is the fallback, and either is stable enough to stop a student being
    // scanned twice for the same task.
    studentId: (user.studentId?.isNotEmpty ?? false) ? user.studentId! : user.id,
    displayName: user.fullName.trim().isEmpty ? user.username : user.fullName,
    school: school,
  );
});
