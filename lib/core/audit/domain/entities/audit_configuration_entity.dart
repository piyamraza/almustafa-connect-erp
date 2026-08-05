import 'package:equatable/equatable.dart';

enum AuditLogLevel { off, critical, standard, detailed }

enum AuditRetentionPeriod {
  thirtyDays,
  ninetyDays,
  oneHundredEightyDays,
  oneYear,
  forever,
}

class AuditModule {
  const AuditModule._();

  static const String authentication = 'Authentication';
  static const String students = 'Students';
  static const String teachers = 'Teachers';
  static const String attendance = 'Attendance';
  static const String academicStructure = 'Academic Structure';
  static const String homework = 'Homework';
  static const String exams = 'Exams';
  static const String results = 'Results';
  static const String fees = 'Fees';
  static const String accounts = 'Accounts';
  static const String payroll = 'Payroll';
  static const String teacherFinance = 'Teacher Finance';
  static const String employeeFinance = 'Employee Finance';
  static const String schoolStore = 'School Store';
  static const String communication = 'Communication';
  static const String accessControl = 'Access Control';
  static const String settings = 'Settings';
  static const String audit = 'Audit';

  static const List<String> all = [
    authentication,
    students,
    teachers,
    attendance,
    academicStructure,
    homework,
    exams,
    results,
    fees,
    accounts,
    payroll,
    teacherFinance,
    employeeFinance,
    schoolStore,
    communication,
    accessControl,
    settings,
    audit,
  ];
}

class AuditConfigurationEntity extends Equatable {
  const AuditConfigurationEntity({
    required this.enabled,
    required this.level,
    required this.enabledModules,
    required this.retentionPeriod,
    required this.updatedAt,
    this.updatedBy = '',
    this.temporaryDetailedLoggingExpiresAt,
    this.temporaryDetailedLoggingFallbackLevel = AuditLogLevel.critical,
  });

  factory AuditConfigurationEntity.defaultConfiguration() {
    return AuditConfigurationEntity(
      enabled: true,
      level: AuditLogLevel.critical,
      enabledModules: const {
        AuditModule.authentication,
        AuditModule.students,
        AuditModule.teachers,
        AuditModule.exams,
        AuditModule.results,
        AuditModule.fees,
        AuditModule.accounts,
        AuditModule.payroll,
        AuditModule.teacherFinance,
        AuditModule.employeeFinance,
        AuditModule.schoolStore,
        AuditModule.accessControl,
        AuditModule.settings,
        AuditModule.audit,
      },
      retentionPeriod: AuditRetentionPeriod.ninetyDays,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final bool enabled;
  final AuditLogLevel level;
  final Set<String> enabledModules;
  final AuditRetentionPeriod retentionPeriod;
  final DateTime updatedAt;
  final String updatedBy;

  final DateTime? temporaryDetailedLoggingExpiresAt;
  final AuditLogLevel temporaryDetailedLoggingFallbackLevel;

  bool get isLoggingEnabled {
    return enabled && effectiveLevel != AuditLogLevel.off;
  }

  bool get isTemporaryDetailedLoggingActive {
    final expiry = temporaryDetailedLoggingExpiresAt;

    if (expiry == null) {
      return false;
    }

    return expiry.isAfter(DateTime.now());
  }

  AuditLogLevel get effectiveLevel {
    if (!enabled) {
      return AuditLogLevel.off;
    }

    if (isTemporaryDetailedLoggingActive) {
      return AuditLogLevel.detailed;
    }

    if (temporaryDetailedLoggingExpiresAt != null &&
        level == AuditLogLevel.detailed) {
      return temporaryDetailedLoggingFallbackLevel;
    }

    return level;
  }

  bool isModuleEnabled(String module) {
    if (!isLoggingEnabled) {
      return false;
    }

    final normalizedModule = module.trim().toLowerCase();

    return enabledModules.any(
      (enabledModule) => enabledModule.trim().toLowerCase() == normalizedModule,
    );
  }

  bool allowsLevel(AuditLogLevel requiredLevel) {
    if (!isLoggingEnabled) {
      return false;
    }

    return effectiveLevel.index >= requiredLevel.index;
  }

  int? get retentionDays {
    return switch (retentionPeriod) {
      AuditRetentionPeriod.thirtyDays => 30,
      AuditRetentionPeriod.ninetyDays => 90,
      AuditRetentionPeriod.oneHundredEightyDays => 180,
      AuditRetentionPeriod.oneYear => 365,
      AuditRetentionPeriod.forever => null,
    };
  }

  AuditConfigurationEntity copyWith({
    bool? enabled,
    AuditLogLevel? level,
    Set<String>? enabledModules,
    AuditRetentionPeriod? retentionPeriod,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? temporaryDetailedLoggingExpiresAt,
    bool clearTemporaryDetailedLoggingExpiry = false,
    AuditLogLevel? temporaryDetailedLoggingFallbackLevel,
  }) {
    return AuditConfigurationEntity(
      enabled: enabled ?? this.enabled,
      level: level ?? this.level,
      enabledModules: Set<String>.unmodifiable(
        enabledModules ?? this.enabledModules,
      ),
      retentionPeriod: retentionPeriod ?? this.retentionPeriod,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      temporaryDetailedLoggingExpiresAt: clearTemporaryDetailedLoggingExpiry
          ? null
          : temporaryDetailedLoggingExpiresAt ??
                this.temporaryDetailedLoggingExpiresAt,
      temporaryDetailedLoggingFallbackLevel:
          temporaryDetailedLoggingFallbackLevel ??
          this.temporaryDetailedLoggingFallbackLevel,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    level,
    enabledModules,
    retentionPeriod,
    updatedAt,
    updatedBy,
    temporaryDetailedLoggingExpiresAt,
    temporaryDetailedLoggingFallbackLevel,
  ];
}
