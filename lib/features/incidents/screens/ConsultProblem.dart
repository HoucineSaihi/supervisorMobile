import 'dart:io';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final String _baseUrl = '${dotenv.env['BASE_URL']}/api';


  late IncidentService _problemService;
  late Future<Problem?> _problemFuture;
  bool _isLoading = true;
  bool _hasError = false;

  // Map for statut colors
  final Map<int, Color> statutColors = {
    0: Colors.blue,
    1: Colors.green,  // Statut 1: Green
    2: Colors.orange, // Statut 2: Orange
    3: Colors.red,    // Statut 3: Red
  };
  String fullImageUrl(String filename) {
    return '$_baseUrl/Files/getImage/$filename';
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
            content: Text('Storage permission denied.'),
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
        throw Exception('Downloads directory not found.');
      }

      // Move the file to the Downloads directory
      String destinationPath = "${downloadsDir.path}/$fileName";
      File destinationFile = tempFile.copySync(destinationPath);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File downloaded successfully: $destinationPath'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      print('File downloaded successfully at: $destinationPath');
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      print('Error downloading file: $e');
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
            String formattedDeclarationDate = DateFormat('dd/MM/yyyy').format(problem.declarationDate ?? DateTime.now());
            String? formattedClosedDate = problem.closedDate != null
                ? DateFormat('dd/MM/yyyy').format(problem.closedDate!)
                : 'N/A';

            // Get the status color based on the statut
            Color statusColor = statutColors[problem.status] ?? Colors.grey;

            return ListView(
              children: [
                // First Row: Declaration Date, Status and Closing Date
                Container(
                  color: statusColor,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 24, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Declared on: $formattedDeclarationDate',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 24, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Closed on: $formattedClosedDate',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
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
                if (problem.problemImageBefore != null) ...[
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
                          String imageUrl = fullImageUrl(problem.problemImageBefore!);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowImageViewer(imageUrl: '$_baseUrl/Files/getImage/${problem.problemImageBefore!}'),
                            ),
                          );
                        },
                      ),

                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.problemImageBefore == null) ...[
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

                if (problem.problemImageAfter != null) ...[
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
                          String imageUrl = fullImageUrl(problem.problemImageBefore!);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowImageViewer(imageUrl: '$_baseUrl/Files/getImage/${problem.problemImageAfter!}'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.problemImageAfter == null) ...[
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
                if (problem.jointFileBefore != null) ...[
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
                          _downloadFile(problem.jointFileBefore!,context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.jointFileBefore == null) ...[
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

                if (problem.jointFileAfter != null) ...[
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
                          _downloadFile(problem.jointFileAfter!,context);

                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (problem.jointFileAfter == null) ...[
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
                        'Cluster: ${problem.cluster == 0 ? 'Retail' : 'Hospitality'}',
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
