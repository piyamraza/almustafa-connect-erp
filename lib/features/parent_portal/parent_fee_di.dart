import 'package:get_it/get_it.dart';

import '../fees/domain/repositories/monthly_fee_due_repository.dart';
import 'data/services/parent_fee_service_impl.dart';
import 'domain/services/parent_fee_service.dart';

void registerParentFeeDependencies(GetIt sl) {
  if (!sl.isRegistered<ParentFeeService>()) {
    sl.registerLazySingleton<ParentFeeService>(
      () => ParentFeeServiceImpl(sl<MonthlyFeeDueRepository>()),
    );
  }
}
