import 'package:get_it/get_it.dart';

import '../homework/domain/repositories/homework_repository.dart';
import 'data/services/parent_homework_service_impl.dart';
import 'domain/services/parent_homework_service.dart';

void registerParentHomeworkDependencies(GetIt sl) {
  if (!sl.isRegistered<ParentHomeworkService>()) {
    sl.registerLazySingleton<ParentHomeworkService>(
      () => ParentHomeworkServiceImpl(sl<HomeworkRepository>()),
    );
  }
}
