import 'package:get_it/get_it.dart';

import '../../core/services/firebase_firestore_service.dart';
import 'data/repositories/timeline_repository_impl.dart';
import 'data/services/timeline_service_impl.dart';
import 'domain/repositories/timeline_repository.dart';
import 'domain/services/timeline_service.dart';

void registerTimelineDependencies(GetIt sl) {
  if (!sl.isRegistered<TimelineRepository>()) {
    sl.registerLazySingleton<TimelineRepository>(
      () => TimelineRepositoryImpl(
        sl<FirebaseFirestoreService>(),
      ),
    );
  }

  if (!sl.isRegistered<TimelineService>()) {
    sl.registerLazySingleton<TimelineService>(
      () => TimelineServiceImpl(
        sl<TimelineRepository>(),
      ),
    );
  }
}