import 'package:get/get.dart';

import '../../../core/widgets/ui.dart';
import '../../events/data/event_models.dart';
import '../../events/data/events_repository.dart';
import '../../profile/data/profile_repository.dart';

class HomeController extends GetxController {
  HomeController(this._events, this._profile);
  final EventsRepository _events;
  final ProfileRepository _profile;

  final name = 'there'.obs;
  final completion = 0.9.obs;
  final upcoming = <SparkEvent>[].obs;
  final live = <SparkEvent>[].obs;
  final loading = true.obs;

  SparkEvent? get next => upcoming.isEmpty ? null : upcoming.first;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final me = await _profile.getMe();
      if (me.fullName != null) name.value = me.fullName!;
      var c = 0.4;
      if (me.photos.isNotEmpty) c += .2;
      if ((me.bio ?? '').isNotEmpty) c += .1;
      if (me.interests.isNotEmpty) c += .1;
      if (me.verificationStatus == 'approved') c += .2;
      completion.value = me.profileCompleted ? c.clamp(0, 1).toDouble() : .4;
      upcoming.assignAll(await _events.myUpcoming());
      live.assignAll(await _events.list(filter: const EventFilter(status: EventStatus.live)));
    } catch (e) {
      showError(e);
    } finally {
      loading.value = false;
    }
  }
}
