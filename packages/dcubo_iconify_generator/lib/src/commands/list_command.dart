import 'package:args/command_runner.dart';
import 'package:dcubo_iconify_generator/src/api.dart';
import 'package:mason_logger/mason_logger.dart';

/// `dcubo_iconify_generator list`
/// A [Command] to list all icon sets
class ListCommand extends Command<int> {
  ListCommand({
    required Logger logger,
  }) : _logger = logger;

  @override
  String get description => 'A command to list all icon sets.';

  @override
  String get name => 'list';

  final Logger _logger;

  @override
  Future<int> run() async {
    final sets = await getIconSets(globalResults?.option('token') ?? '');
    for (final set in sets) {
      _logger.info(set.name);
    }
    return ExitCode.success.code;
  }
}
