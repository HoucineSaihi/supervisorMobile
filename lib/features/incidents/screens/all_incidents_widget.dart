import 'package:animations/animations.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_bottom_sheet/flutter_awesome_bottom_sheet.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:supervisormobile/features/calendar/models/Problem.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/edit_question_response.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/features/incidents/models/Coefficient.dart';
import 'package:supervisormobile/features/incidents/screens/ConsultProblem.dart';
import 'package:supervisormobile/features/incidents/screens/IncidentFormWidget.dart';
import 'package:supervisormobile/features/incidents/services/incident_service.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class AllIncidentsWidget extends StatefulWidget {
  AllIncidentsWidget({Key? key}) : super(key: key);

  @override
  _AllIncidentsWidgetState createState() => _AllIncidentsWidgetState();
}

class _AllIncidentsWidgetState extends State<AllIncidentsWidget> {
  late final IncidentService _incidentService;

  List<Problem> _incidents = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _showFilters = false; // State to control filter visibility
  final MissionService _missionService = MissionService();

  // Filter fields
  final TextEditingController _missionLibelleController =
      TextEditingController();
  final TextEditingController _sousMissionLibelleController =
      TextEditingController();
  final TextEditingController _questionLibelleController =
      TextEditingController();
  final TextEditingController _actionIdController = TextEditingController();
  final TextEditingController _boutiqueLibelleController =
      TextEditingController();
  final TextEditingController _statusValidationController =
      TextEditingController();
  List<BoutiqueModel> _boutiques = [];

  DateTime? _dateDb;
  DateTime? _dateF;
  DateTime? _dateClotDb;
  DateTime? _dateClotF;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  var _selectedStatus;

  var _selectedOrigin;

  var _selectedCluster;

  var _selectedPriority;

  var _selectedBoutiqueId;

  bool _hasMoreData = true;

  int _totalRecords = 0;

  List<Coefficient> _priorities = [];

  ScrollController _scrollController = ScrollController();
  int _first = 0; // Offset for API request
  final int _rows = 10; // Number of items per page
  bool _isFetchingMore = false; // Flag to prevent multiple calls

  var _alowedStatus;

  @override
  void initState() {
    super.initState();
    _incidentService = IncidentService();

    _missionService.getBoutiques().then((boutiques) {
      setState(() {
        _boutiques = boutiques;
      });
    });
    IncidentService().getAllCoefficients().then((coef) {
      setState(() {
        _priorities = coef;
      });
    });
    IncidentService().getAllowedStatus().then((status) {
      setState(() {
        _alowedStatus = status;
        print(_alowedStatus);
      });
    });

    _fetchIncidents();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isFetchingMore) {
        _fetchIncidents(isLoadMore: true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _missionLibelleController.dispose();
    _sousMissionLibelleController.dispose();
    _questionLibelleController.dispose();
    _actionIdController.dispose();
    _boutiqueLibelleController.dispose();
    _statusValidationController.dispose();
    super.dispose();
  }

  int _totalIncidents = 0;

  Future<void> _fetchIncidents({bool isLoadMore = false}) async {
    if (isLoadMore == true && (_isFetchingMore || !_hasMoreData)) {
      print(
          "triggered this condition !! "); // Stop if already fetching or no more data
      return;
    }

    setState(() => _isFetchingMore = true);
    if (isLoadMore == true) {
      _first += _rows;
    } else {
      _first = 0;
    }

    try {
      final response = await IncidentService().getFilteredProblems(
        _selectedBoutiqueId,
        _selectedPriority,
        _selectedOrigin,
        _selectedStatus,
        _first,
      );

      // Ensure response matches expected structure
      List<Problem> problemsData = response.problems;
      int totalRecords = response.totalRecords;

      print(problemsData);

      List<Problem> newIncidents = problemsData.map<Problem>((incident) {
        return Problem(
          id: incident.id ?? 0,
          user_id: incident.user_id ?? 0,
          boutique_id: incident.boutique_id ?? 0,
          /* boutique: incident.boutique != null
              ? BoutiqueModel.fromJson(incident.boutique as Map<String, dynamic>)
              : null,*/
          description: incident.description ?? 'N/A',
          commentaire: incident.commentaire ?? 'N/A',
          problem_image_before: incident.problem_image_before,
          problem_image_after: incident.problem_image_after,
          joint_file_before: incident.joint_file_before,
          joint_file_after: incident.joint_file_after,
          coef_id: incident.coef_id ?? 0,
          coefficient: (incident.coefficient is Map<String, dynamic>)
              ? Coefficient.fromJson(incident.coefficient as Map<String, dynamic>)
              : incident.coefficient as Coefficient?,
          cluster: incident.cluster ?? 0,
          origin: incident.origin ?? 0,
          declaration_date: incident.declaration_date != null
              ? incident.declaration_date
              : DateTime.now(),
          closed_date:
              incident.closed_date != null ? incident.closed_date : null,
          Status: incident.Status ?? 0,
          closing_comment: incident.closing_comment ?? 'No comment',
          cost: incident.cost ?? 0.0,
        );
      }).toList();

      setState(() {
        if (isLoadMore == true) {
          _incidents.addAll(newIncidents);
        } else {
          _incidents = newIncidents; // First 10 items
        }

        _totalRecords = totalRecords; // Set total record count
        // Update pagination offset
        _hasMoreData =
            _incidents.length < _totalRecords; // Stop loading if reached total
      });
    } catch (e) {
      debugPrint('Error fetching incidents: $e');
    } finally {
      setState(() {
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _applyFilters() async {
    // Trigger the API call with selected filters
    await _fetchIncidents();
  }

  Future<void> _handleRefresh() async {
    // Refresh the incidents list with current filters
    await _fetchIncidents();
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate,
      Function(DateTime?) onDateSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    onDateSelected(pickedDate);
  }

  var _statusValidation = null;

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

  // statusColors in Dart
  final Map<String, Map<String, String>> statusColors = {
    'Solved': {
      'background': '#e6f4ea', // Light green
      'color': '#2e7d32'
    },
    // Light green background, dark green text
    'Pending': {
      'background': '#fff3cd', // Light yellow
      'color': '#856404'
    },
    // Light yellow background, dark yellow text
    'Planned': {
      'background': '#e8f0fe', // Light blue
      'color': '#1a237e'
    },
    // Light gray background, dark gray text
    'InProgress': {
      'background': '#fff8e1', // Light amber
      'color': '#ff6f00'
    },
    // Light red background, dark red text
    'Finished': {
      'background': '#f1f8e9', // Pale green
      'color': '#33691e'
    },
    // Light red background, dark red text
  };
  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add opacity if missing
    }
    return Color(int.parse('0x$hex'));
  }
  Widget _buildFilterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
      children: [
        // Boutique Dropdown
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Choisir une boutique',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<int>(
              value: null,
              child: Text('Tous'),
            ),
            ..._boutiques.map((boutique) {
              return DropdownMenuItem<int>(
                value: boutique.id, // Store the boutique ID
                child: Text(
                    boutique.libelle ?? 'No Name'), // Display boutique name
              );
            }).toList(),
          ],
          onChanged: (int? newValue) {
            setState(() {
              _selectedBoutiqueId = newValue;
            });
          },
          value: _selectedBoutiqueId,
        ),
        SizedBox(height: 10), // Spacing

        // Priorities Dropdown
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Priorité',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<int>(value: null, child: Text('Tous')),
            ..._priorities.map((priority) {
              return DropdownMenuItem<int>(
                value: priority.coefId, // Store priority ID
                child: Text(priority.libelle!), // Display priority name
              );
            }).toList(),
          ],
          onChanged: (int? newValue) {
            setState(() {
              _selectedPriority = newValue;
            });
          },
          value: _selectedPriority,
        ),
        /* SizedBox(height: 10), // Spacing

        // Cluster Dropdown
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Cluster',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<int>(value: null, child: Text('Tous')),
            DropdownMenuItem<int>(value: 1, child: Text('Hôtel')),
            DropdownMenuItem<int>(value: 0, child: Text('Retail')),
          ],
          onChanged: (int? newValue) {
            setState(() {
              _selectedCluster = newValue;
            });
          },
          value: _selectedCluster,
        ),*/
        SizedBox(height: 10), // Spacing

        // Origin Dropdown
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Origine',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<int>(value: null, child: Text('Tous')),
            DropdownMenuItem<int>(value: 1, child: Text('Manuelle')),
            DropdownMenuItem<int>(value: 0, child: Text('Checklist')),
          ],
          onChanged: (int? newValue) {
            setState(() {
              _selectedOrigin = newValue;
            });
          },
          value: _selectedOrigin,
        ),
        SizedBox(height: 10), // Spacing

        // Status Dropdown
        SizedBox(height: 10), // Spacing

        // Status Dropdown
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Statut',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<int>(
              value: null,
              child: Text('Tous'),
            ),
            ..._alowedStatus.map((status) {
              int statusId = status['identifier'];
              String statusName = status['name'] ?? 'Unknown';

              // Use 'color' from statusColors instead of 'background'
              final String? hexColor = statusColors[statusName]?['color'];
              final Color colorDot = hexColor != null ? hexToColor(hexColor) : Colors.grey;

              return DropdownMenuItem<int>(
                value: statusId,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorDot,
                      ),
                    ),
                    Text(statusName),
                  ],
                ),
              );
            }).toList(),



          ],
          onChanged: (int? newValue) {
            setState(() {
              _selectedStatus = newValue;
            });
          },
          value: _selectedStatus,
        ),

        SizedBox(height: 10), // Spacing

        // Apply Filters Button
        SizedBox(
          width: double.infinity, // Full width button
          child: ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: Icon(Iconsax.filter, size: 20), // Replace with desired icon
            label: Text('Appliquer Filtre'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16), // Adjust padding
            ),
          ),
        ),
      ],
    );
  }

  final Map<int, Color> statutColors = {
    1: Color(0xFF856404), // Pending
    2: Color(0xFF1A237E), // Planned
    3: Color(0xFFFF6F00), // In Progress
    4: Color(0xFF33691E), // Finished
    5: Color(0xFF2E7D32), // Solved
  };
  String? getStatusLabel(int statusType, int statusNumber) {
    return statusTypeMap[statusType]?[statusNumber];
  }

  Widget _listItem(Problem problem) {
    // Get status label
    final String? statusLabel =
    getStatusLabel(problem.StatusType ?? 3, problem.Status ?? 5);

    // Get background color for the left border using status label
    final String? hexBackground =
    statusColors[statusLabel]?['background'];

    final Color borderColor = hexBackground != null
        ? hexToColor(hexBackground)
        : Colors.grey; // Default color if not found

    // Format the date (display only the date part)
    final String formattedDate = problem.declaration_date != null
        ? DateFormat('yyyy-MM-dd').format(problem.declaration_date!)
        : 'No date';

    return Stack(
      children: [
        // Card Content
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.black, width: 1.0), // Black border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description and coefficient on the same line
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Statut: ${statusLabel ?? 'N/A'}',
                        style: TextStyle(
                          color: TColors.black,
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                      ),
                    ),
                    Text(
                      problem.coefficient?.libelle ?? 'No priority',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9.0),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  problem.description ?? 'No description',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8.0),

                // Commentaire
                const Text(
                  'Commentaire:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  problem.commentaire ?? 'No comment',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8.0),


                // Date déclaration
                const Text(
                  'Date déclaration:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Left Colored Border
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 8.0, // Border width
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8.0),
                bottomLeft: Radius.circular(8.0),
              ),
            ),
          ),
        ),
      ],
    );
  }


  void _showModal(BuildContext context, Map<String, dynamic> item) {
    AwesomeBottomSheet().show(
      context: context,
      title: const Text("Consultation de l'incident"),
      description: const Text("Choisissez une option pour modifier l'incident"),
      color: CustomSheetColor(
        mainColor: TColors.primary,
        accentColor: TColors.secondary,
        iconColor: Colors.white,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      // Adjusted padding for SafeArea
      positive: AwesomeSheetAction(
        title: 'Consulter',
        onPressed: () => {},
        /*onPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditQuestionResponse(questionId: item["id"] ?? 0),
            ),
          ); // Close the bottom sheet
        },
        ,
        icon: Iconsax.eye,*/
      ),
      negative: AwesomeSheetAction(
        onPressed: () {
          Navigator.of(context).pop(); // Close the bottom sheet
          _showConfirmationDialog(item);
        },
        title: item["clouture"] != null ? 'UnCloturer' : "Cloturer",
        icon: item["clouture"] != null
            ? Iconsax.close_circle
            : Iconsax.tick_circle,
      ),
    );
  }

  void _showConfirmationDialog(Map<String, dynamic> item) {
    AwesomeBottomSheet().show(
      context: context,
      title: Text('Confirmer Clôture'),
      description: Text(
          'Êtes-vous sûr de vouloir changer l état de cloture "${item['questionLibelle'] ?? 'No question'}"?'),
      color: CustomSheetColor(
        mainColor: const Color(0xAD0BB819),
        accentColor: const Color(0xFF0BB819),
        iconColor: Colors.white,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      // Adjusted padding for SafeArea
      positive: AwesomeSheetAction(
        onPressed: () async {
          Navigator.of(context).pop(); // Close the bottom sheet

          // Extract the questionId from the item
          final questionId = item['id']
              as int?; // Ensure that 'questionId' exists and is of type int

          if (questionId != null) {
            try {
              // Call the cloturerIncident function from IncidentService
              await IncidentService().cloturerIncident(questionId);

              // Show a success message using AwesomeSnackbarContent
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AwesomeSnackbarContent(
                    title: 'Succès!',
                    message: 'Incident clôturé avec succès.',
                    contentType: ContentType.success,
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              );
            } catch (e) {
              // Handle any errors that occur during the API call
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AwesomeSnackbarContent(
                    title: 'Erreur!',
                    message: 'Erreur lors de la clôture de l\'incident.',
                    contentType: ContentType.failure,
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
              );
            }
          } else {
            // Handle the case where questionId is null
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AwesomeSnackbarContent(
                  title: 'Erreur!',
                  message: 'ID de la question invalide.',
                  contentType: ContentType.failure,
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            );
          }
        },
        title: 'Confirmer',
        icon: Icons.check,
      ),
      negative: AwesomeSheetAction(
        onPressed: () {
          Navigator.of(context).pop(); // Close the bottom sheet
        },
        title: 'Annuler',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IncidentFormWidget()),
          );

          if (result == true) {
            // Refresh your widget or call setState
            setState(() {
              _handleRefresh();
            });
          }
        },

        backgroundColor: TColors.primary,
        child: const Icon(Iconsax.add_circle, color: Colors.white),
      ),
      body:  Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align to right
                children: [
                  IconButton(
                    icon: Icon(Iconsax.refresh),
                    onPressed: _handleRefresh,
                    tooltip: 'Refresh Incidents',
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Show the filter form when _showFilters is true
              if (_showFilters) _buildFilterForm(), // Conditional rendering

              const SizedBox(height: 16.0),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  // Attach scroll listener
                  itemCount: _incidents.length + (_isFetchingMore ? 1 : 0),
                  // Add extra item for loader
                  itemBuilder: (context, index) {
                    if (index == _incidents.length) {
                      return _hasMoreData
                          ? const Center(
                          child:
                          CircularProgressIndicator()) // Show loading if more data
                          : const SizedBox(); // No more data, show nothing
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: OpenContainer(
                        transitionType: ContainerTransitionType.fadeThrough,
                        openBuilder: (context, _) =>
                            ConsultProblem(problemId: _incidents[index].id),
                        closedElevation: 0.0,
                        closedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        closedColor: Colors.transparent,
                        closedBuilder: (context, openContainer) {
                          return GestureDetector(
                            onTap: openContainer,
                            child: _listItem(_incidents[index]),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

    );
  }
}
