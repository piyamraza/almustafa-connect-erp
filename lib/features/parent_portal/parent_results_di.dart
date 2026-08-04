import 'package:get_it/get_it.dart';

import '../exams/domain/repositories/exam_result_repository.dart';
import 'data/services/parent_results_service_impl.dart';
import 'domain/services/parent_results_service.dart';

void registerParentResultsDependencies(GetIt sl) {
  if (!sl.isRegistered<ParentResultsService>()) {
    sl.registerLazySingleton<ParentResultsService>(
      () => ParentResultsServiceImpl(sl<ExamResultRepository>()),
    );
  }
}
