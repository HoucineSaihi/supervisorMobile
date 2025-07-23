import 'dart:io';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // To format date
import 'package:permission_handler/permission_handler.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/features/incidents/screens/ShowImageViewer.dart';
import 'package:supervisormobile/features/incidents/services/incident_service.dart';

class ConsultProblem extends StatefulWidget {
  final int problemId; // Accept problem ID to fetch the problem data

  const ConsultProblem({Key? key, required this.problemId}) : super(key: key);

  @override
  _ConsultProblemState createState() => _ConsultProblemState();
}

class _ConsultProblemState extends State<ConsultProblem> {
  final String _baseUrl = "http://172.28.3.180:7070";


  late IncidentService _problemService;
  late Future<Problem?> _problemFuture;
  bool _isLoading = true;
  bool _hasError = false;

  // Map for statut colors
  final Map<int, Color> statutColors = {
    1: Color(0xFF856404), // Pending
    2: Color(0xFF1A237E), // Planned
    3: Color(0xFFFF6F00), // In Progress
    4: Color(0xFF33691E), // Finished
    5: Color(0xFF2E7D32), // Solved
  };
  String fullImageUrl(String filename) {
    return '$_baseUrl/Files/getImage/$filename';
  }

  final Map<int, Map<int, String>> statusTypeMap = {
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
      1: 'Pending',
      2: 'Planned',
      3: 'InProgress',
      4: 'Finished',
      5: 'Solved',
    },
  };

// Example function to get status string:
  String? getStatusLabel(int statusType, int statusNumber) {
    return statusTypeMap[statusType]?[statusNumber];
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
  final Map<String, Map<String, String>> statusColors = {
    'Declared': {'background': '#f8d7da', 'color': '#721c24'},
    // Light red background, dark red text
    'Solved': {'background': '#d4edda', 'color': '#155724'},
    // Light green background, dark green text
    'Pending': {'background': '#fff3cd', 'color': '#856404'},
    // Light yellow background, dark yellow text
    'Planned': {'background': '#e2e3e5', 'color': '#383d41'},
    // Light gray background, dark gray text
    'InProgress': {'background': '#f5c6cb', 'color': '#721c24'},
    // Light red background, dark red text
    'Finished': {'background': '#f8d7da', 'color': '#721c24'},
    // Light red background, dark red text
  };
  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add opacity if missing
    }
    return Color(int.parse('0x$hex'));
  }
  void _downloadFile(String fileName, BuildContext context) async {
    try {
      if (kIsWeb) {
        // ✅ Web: Download via browser
        final bytes = await MissionService().getFileBytes(fileName);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fichier téléchargé via le navigateur.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // ✅ Mobile: Download using service and save to Downloads
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission de stockage refusée.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        final tempFilePath = await MissionService().downloadFile(fileName);
        final tempFile = File(tempFilePath);

        // ✅ Downloads directory (fallback if needed)
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (!downloadsDir.existsSync()) {
          await downloadsDir.create(recursive: true);
        }

        final destinationPath = '${downloadsDir.path}/$fileName';
        await tempFile.copy(destinationPath);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fichier téléchargé : $destinationPath'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        print('📥 File saved at: $destinationPath');
      }
    } catch (e) {
      print('❌ Error downloading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consult Problem'),
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
              return const Center(child: Text('Error loading problem'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('Problem not found'));
            }

            final problem = snapshot.data!;
            String formattedDeclarationDate = DateFormat('dd/MM/yyyy').format(problem.declaration_date ?? DateTime.now());
            String? formattedClosedDate = problem.closed_date != null
                ? DateFormat('dd/MM/yyyy').format(problem.closed_date!)
                : 'N/A';

            // Get the status color based on the statut
            Color statusColor = statutColors[problem.Status] ?? Colors.grey;

            return ListView(
              children: [
                // First Row: Declaration Date, Status and Closing Date
                Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Declared on: $formattedDeclarationDate',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Closed on: $formattedClosedDate',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.comment, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          String? label = getStatusLabel(problem.StatusType!, problem.Status!);
                          if (label == null) {
                            return const Text('Statut: N/A', style: TextStyle(fontSize: 16));
                          }

                          final colorInfo = statusColors[label];
                          final backgroundColor = colorInfo != null ? hexToColor(colorInfo['background']!) : Colors.grey[200]!;
                          final textColor = colorInfo != null ? hexToColor(colorInfo['color']!) : Colors.black;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Statut: $label',
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description Row
                Row(
                  children: [
                    const Icon(Icons.description, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        problem.description ?? 'N/A',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Commentaire
                Row(
                  children: [
                    const Icon(Icons.comment, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Commentaire: ${problem.commentaire ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Problem Images Before and After
                if (problem.problem_image_before != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.camera_alt, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Photo avant disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () {
                          String imageUrl = fullImageUrl(problem.problem_image_before!);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowImageViewer(imageUrl: '$_baseUrl/Files/getImage/${problem.problem_image_before!}'),
                            ),
                          );
                        },
                      ),

                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.problem_image_before == null) ...[
                  Row(
                    children: [
                      const Icon(Icons.camera_alt, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Photo avant non disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                if (problem.problem_image_after != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.camera_alt, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Photo apres disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () {
                          String imageUrl = fullImageUrl(problem.problem_image_after!);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowImageViewer(imageUrl: '$_baseUrl/Files/getImage/${problem.problem_image_after!}'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.problem_image_after == null) ...[
                  Row(
                    children: [
                      const Icon(Icons.camera_alt, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Photo apres non disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Files Before and After
                if (problem.joint_file_before != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fichier avant disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, size: 18),
                        onPressed: () {
                          _downloadFile(problem.joint_file_before!,context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.joint_file_before == null) ...[
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fichier avant non disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                if (problem.joint_file_after != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fichier apres disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, size: 18),
                        onPressed: () {
                          _downloadFile(problem.joint_file_after!,context);

                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.joint_file_after == null) ...[
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fichier apres non disponible',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Coefficient Info
                if (problem.coefficient != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Coefficient: ${problem.coefficient?.libelle ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.coefficient == null) ...[
                  Row(
                    children: [
                      const Icon(Icons.trending_up, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Coefficient: N/A',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Cluster (Retail or Hospitality)
                Row(
                  children: [
                    const Icon(Icons.store, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cluster: ${problem.cluster == 0 ? 'Retail' : problem.cluster == 1 ? 'Hospitality' : problem.cluster == 2 ? 'Production' : 'Office'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Origin (Checklist or Libre)
                Row(
                  children: [
                    const Icon(Icons.assignment, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Origin: ${problem.origin == 0 ? 'Checklist' : 'Libre'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cost Info
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cost: \$${problem.cost?.toStringAsFixed(2) ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
