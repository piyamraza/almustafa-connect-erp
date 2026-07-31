// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('❌ Please provide a module name.');
    print('');
    print('Example:');
    print('dart run tool/create_module.dart students');
    return;
  }

  final module = args.first.toLowerCase();
  final modulePascal = _toPascalCase(module);

  final root = Directory.current.path;
  final featurePath = '$root/lib/features/$module';

  final directories = [
    '$featurePath/data/datasources',
    '$featurePath/data/models',
    '$featurePath/data/repositories',
    '$featurePath/domain/entities',
    '$featurePath/domain/repositories',
    '$featurePath/domain/usecases',
    '$featurePath/presentation/bloc',
    '$featurePath/presentation/pages',
    '$featurePath/presentation/widgets',
  ];

  for (final dir in directories) {
    Directory(dir).createSync(recursive: true);
  }

  final files = {
    '$featurePath/domain/entities/${module}_entity.dart': _entityTemplate(
      modulePascal,
    ),

    '$featurePath/domain/repositories/${module}_repository.dart':
        _repositoryTemplate(modulePascal),

    '$featurePath/domain/usecases/get_$module.dart': _useCaseTemplate(
      modulePascal,
    ),

    '$featurePath/data/models/${module}_model.dart': _modelTemplate(
      modulePascal,
    ),

    '$featurePath/data/datasources/${module}_remote_datasource.dart':
        _datasourceTemplate(modulePascal),

    '$featurePath/data/repositories/${module}_repository_impl.dart':
        _repositoryImplTemplate(modulePascal),

    '$featurePath/presentation/bloc/${module}_bloc.dart': _blocTemplate(
      modulePascal,
    ),

    '$featurePath/presentation/bloc/${module}_event.dart': _eventTemplate(
      modulePascal,
    ),

    '$featurePath/presentation/bloc/${module}_state.dart': _stateTemplate(
      modulePascal,
    ),

    '$featurePath/presentation/pages/${module}_page.dart': _pageTemplate(
      modulePascal,
    ),
  };

  files.forEach((path, content) {
    final file = File(path);

    if (!file.existsSync()) {
      file.createSync(recursive: true);
      file.writeAsStringSync(content);
      print('✅ ${file.path}');
    } else {
      print('⚠️ Already exists: ${file.path}');
    }
  });

  print('');
  print('🎉 $modulePascal module generated successfully.');
}

String _toPascalCase(String value) {
  return value
      .split('_')
      .map((e) => e[0].toUpperCase() + e.substring(1))
      .join();
}

String _entityTemplate(String name) =>
    '''
class ${name}Entity {

}
''';

String _repositoryTemplate(String name) =>
    '''
abstract class ${name}Repository {

}
''';

String _useCaseTemplate(String name) =>
    '''
class Get${name}UseCase {

}
''';

String _modelTemplate(String name) =>
    '''
class ${name}Model {

}
''';

String _datasourceTemplate(String name) =>
    '''
abstract class ${name}RemoteDataSource {

}
''';

String _repositoryImplTemplate(String name) =>
    '''
class ${name}RepositoryImpl {

}
''';

String _blocTemplate(String name) =>
    '''
class ${name}Bloc {

}
''';

String _eventTemplate(String name) =>
    '''
abstract class ${name}Event {

}
''';

String _stateTemplate(String name) =>
    '''
abstract class ${name}State {

}
''';

String _pageTemplate(String name) =>
    '''
class ${name}Page {

}
''';
