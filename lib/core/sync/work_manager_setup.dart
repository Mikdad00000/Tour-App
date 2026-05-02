import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';

import '../config/firebase_options.dart';
import 'sync_service.dart';

const String kSyncTask = 'tour_app.sync';

@pragma('vm:entry-point')
void wmDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task == kSyncTask) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      await SyncService.instance.syncNow();
    }
    return true;
  });
}

Future<void> initWorkManager() async {
  await Workmanager().initialize(wmDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    kSyncTask,
    kSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
