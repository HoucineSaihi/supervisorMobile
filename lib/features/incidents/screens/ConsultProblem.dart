import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';  // To format date
import 'package:permission_handler/permission_handler.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/features/incidents/screens/ShowImageViewer.dart';
import 'package:supervisormobile/features/incidents/services/incident_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConsultProblem extends StatefulWidget {
  final int problemId; // Accept problem ID to fetch the problem data

  const ConsultProblem({Key? key, required this.problemId}) : super(key: key);

  @override
  _ConsultProblemState createState() => _ConsultProblemState();
}

class _ConsultProblemState extends State<ConsultProblem> {
  final String _baseUrl = '${dotenv.env['BASE_URL']}/api';


  late IncidentService _problemService;
  late Future<Problem?> _problemFuture;
  bool _isLoading = true;
  bool _hasError = false;

  String fullImageUrl(String filename) {
    return '$_baseUrl/Files/getImage/$filename';
  }

  final Map<int, Map<int, String>> statusTypeMap = const {
    1: {
      1: 'Declared',
      2: 'Solved',
    },
    2: {
      1: 'Declared',
      2: 'Pending',
      3: 'Solved',
    },
    3: {
      0: 'Pending',
      1: 'Acknowledged',
      2: 'Planned',
      3: 'InProgress',
      4: 'NeedsReview',
      5: 'Solved',
    },
  };

  final Map<String, Map<String, String>> statusColors = const {
    'Declared': {'background': '#f8d7da', 'color': '#721c24'},
    'Solved': {'background': '#d4edda', 'color': '#155724'},
    'Pending': {'background': '#fff3cd', 'color': '#856404'},
    'Acknowledged': {'background': '#d1ecf1', 'color': '#0c5460'},
    'Planned': {'background': '#e2e3e5', 'color': '#383d41'},
    'InProgress': {'background': '#f5c6cb', 'color': '#721c24'},
    'NeedsReview': {'background': '#fff3cd', 'color': '#856404'},
  };

  String? _getStatusKey(int? statusType, int? statusNumber) {
    if (statusType == null || statusNumber == null) return null;
    return statusTypeMap[statusType]?[statusNumber];
  }

  String _translateStatus(String statusKey) {
    final isFrench = Localizations.localeOf(context).languageCode
        .toLowerCase()
        .startsWith('fr');

    if (!isFrench) {
      return switch (statusKey) {
        'Declared' => 'Declared',
        'Solved' => 'Solved',
        'Pending' => 'Pending',
        'Acknowledged' => 'Acknowledged',
        'Planned' => 'Planned',
        'InProgress' => 'In Progress',
        'NeedsReview' => 'Needs Review',
        _ => statusKey,
      };
    }

    return switch (statusKey) {
      'Declared' => 'Declare',
      'Solved' => 'Resolu',
      'Pending' => 'En attente',
      'Acknowledged' => 'Accuse',
      'Planned' => 'Planifie',
      'InProgress' => 'En cours',
      'NeedsReview' => 'A revoir',
      _ => statusKey,
    };
  }

  String _priorityLabel(Problem problem) {
    if (problem.coefficient?.libelle != null &&
        problem.coefficient!.libelle!.trim().isNotEmpty) {
      return problem.coefficient!.libelle!;
    }
    if (problem.coefficientName != null &&
        problem.coefficientName!.trim().isNotEmpty) {
      return problem.coefficientName!;
    }
    return AppLocalizations.of(context)!.nA;
  }

  @override
  void initState() {
    super.initState();
    _problemService = IncidentService();
    // Start the fetching of problem data and update _isLoading state when done
    _problemFuture = _problemService.getProblemById(widget.problemId).then((problem) {
      setState(() {
        _isLoading = false;
      });
      return problem;  // Return the fetched problem to FutureBuilder
    }).catchError((e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return null;  // Handle error scenario by returning null
    });
  }

  void _downloadFile(String fileName, BuildContext context) async {
    try {
      // Request storage permissions
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.storagePermissionDenied),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Download the file to a temporary location
      String tempFilePath = await MissionService().downloadFile(fileName);
      File tempFile = File(tempFilePath);

      // Get the system's Downloads directory
      Directory downloadsDir = Directory('/storage/emulated/0/Download');

      if (!downloadsDir.existsSync()) {
        throw Exception(AppLocalizations.of(context)!.downloadsDirectoryNotFound);
      }

      // Move the file to the Downloads directory
      String destinationPath = "${downloadsDir.path}/$fileName";
      tempFile.copySync(destinationPath);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.fileDownloadedSuccessfully} $destinationPath'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      print('${AppLocalizations.of(context)!.fileDownloadedSuccessfully} $destinationPath');
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.errorDownloadingFile} $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      print('${AppLocalizations.of(context)!.errorDownloadingFile} $e');
    }
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add opacity if missing
    }
    return Color(int.parse('0x$hex'));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.consultProblem),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Problem?>(
          future: _problemFuture,
          builder: (context, snapshot) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_hasError) {
              return Center(child: Text(AppLocalizations.of(context)!.errorLoadingProblem));
            }

            if (!snapshot.hasData) {
              return Center(child: Text(AppLocalizations.of(context)!.problemNotFound));
            }

            final problem = snapshot.data!;
            final String formattedDeclarationDate = DateFormat('dd/MM/yyyy')
                .format(problem.declaration_date ?? DateTime.now());
            final String formattedClosedDate = problem.closed_date != null
                ? DateFormat('dd/MM/yyyy').format(problem.closed_date!)
                : AppLocalizations.of(context)!.nA;
            final String statusKey =
                _getStatusKey(problem.StatusType, problem.Status) ?? 'Pending';
            final String statusLabel = _translateStatus(statusKey);
            final colorInfo = statusColors[statusKey];
            final Color chipBackground = colorInfo != null
                ? hexToColor(colorInfo['background']!)
                : Colors.grey.shade200;
            final Color chipText = colorInfo != null
                ? hexToColor(colorInfo['color']!)
                : Colors.black87;
            final String priority = _priorityLabel(problem);

            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          problem.description,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              backgroundColor: chipBackground,
                              label: Text(
                                AppLocalizations.of(context)!
                                    .statusLabel(statusLabel),
                                style: TextStyle(color: chipText),
                              ),
                            ),
                            Chip(
                              avatar: const Icon(Icons.trending_up, size: 18),
                              label: Text(
                                AppLocalizations.of(context)!.coefficient(priority),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (problem.commentaire != null &&
                            problem.commentaire!.trim().isNotEmpty)
                          Text(
                            AppLocalizations.of(context)!
                                .commentColon(problem.commentaire!),
                            style: const TextStyle(fontSize: 15),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow(Icons.calendar_today,
                            AppLocalizations.of(context)!.declaredOn(formattedDeclarationDate)),
                        _infoRow(Icons.event_available,
                            AppLocalizations.of(context)!.closedOn(formattedClosedDate)),
                        _infoRow(
                          Icons.store,
                          AppLocalizations.of(context)!.cluster(
                            problem.cluster == 0
                                ? AppLocalizations.of(context)!.retail
                                : problem.cluster == 1
                                    ? AppLocalizations.of(context)!.hospitality
                                    : problem.cluster == 2
                                        ? AppLocalizations.of(context)!.production
                                        : AppLocalizations.of(context)!.office,
                          ),
                        ),
                        _infoRow(
                          Icons.assignment,
                          AppLocalizations.of(context)!.originColon(
                            problem.origin == 0
                                ? AppLocalizations.of(context)!.checklist
                                : AppLocalizations.of(context)!.free,
                          ),
                        ),
                        _infoRow(
                          Icons.monetization_on,
                          AppLocalizations.of(context)!.cost(
                              problem.cost?.toStringAsFixed(2) ??
                                  AppLocalizations.of(context)!.nA),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Media',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        _mediaImageRow(
                          labelWhenExists:
                              AppLocalizations.of(context)!.photoBeforeAvailable,
                          labelWhenMissing:
                              AppLocalizations.of(context)!.photoBeforeNotAvailable,
                          filename: problem.problem_image_before,
                        ),
                        _mediaImageRow(
                          labelWhenExists:
                              AppLocalizations.of(context)!.photoAfterAvailable,
                          labelWhenMissing:
                              AppLocalizations.of(context)!.photoAfterNotAvailable,
                          filename: problem.problem_image_after,
                        ),
                        _fileRow(
                          labelWhenExists:
                              AppLocalizations.of(context)!.fileBeforeAvailable,
                          labelWhenMissing:
                              AppLocalizations.of(context)!.fileBeforeNotAvailable,
                          filename: problem.joint_file_before,
                        ),
                        _fileRow(
                          labelWhenExists:
                              AppLocalizations.of(context)!.fileAfterAvailable,
                          labelWhenMissing:
                              AppLocalizations.of(context)!.fileAfterNotAvailable,
                          filename: problem.joint_file_after,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _mediaImageRow({
    required String labelWhenExists,
    required String labelWhenMissing,
    required String? filename,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.camera_alt, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(filename != null ? labelWhenExists : labelWhenMissing)),
          if (filename != null)
            IconButton(
              icon: const Icon(Icons.visibility, size: 18),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShowImageViewer(
                        imageUrl: fullImageUrl(filename)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _fileRow({
    required String labelWhenExists,
    required String labelWhenMissing,
    required String? filename,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(filename != null ? labelWhenExists : labelWhenMissing)),
          if (filename != null)
            IconButton(
              icon: const Icon(Icons.download, size: 18),
              onPressed: () => _downloadFile(filename, context),
            ),
        ],
      ),
    );
  }
}
