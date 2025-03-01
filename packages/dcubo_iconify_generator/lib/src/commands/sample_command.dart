import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template sample_command}
///
/// `dcubo_iconify_generator sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class SampleCommand extends Command<int> {
  /// {@macro sample_command}
  SampleCommand({
    required Logger logger,
  }) : _logger = logger;

  @override
  String get description => 'A command to generate all icon packages. '
      'You optionally specify which to generate vie arguments';

  @override
  String get name => 'generate';

  final Logger _logger;

  @override
  Future<int> run() async {
    var output = 'Which unicorn has a cold? The Achoo-nicorn!';
    _logger.info(output);
    return ExitCode.success.code;
  }
}
