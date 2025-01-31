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
  final TextEditingController _missionLibelleController = TextEditingController();
  final TextEditingController _sousMissionLibelleController = TextEditingController();
  final TextEditingController _questionLibelleController = TextEditingController();
  final TextEditingController _actionIdController = TextEditingController();
  final TextEditingController _boutiqueLibelleController = TextEditingController();
  final TextEditingController _statusValidationController = TextEditingController();
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

  List<Coefficient> _priorities = [];

  var _selectedBoutiqueId;

  @override
  void initState() {
    super.initState();
    _incidentService = IncidentService();

    _missionService.getBoutiques().then((boutiques) {
      setState(() {
        _boutiques = boutiques;
      });



    });
    IncidentService().getAllCoefficients().then((coef){
      setState(() {
        _priorities = coef ;
      });
    });

    _fetchIncidents(null,null,null,null,null);
  }
  int _totalIncidents = 0;

  Future<void> _fetchIncidents(
      int? boutiqueId,
      int? coefId,
      int? cluster,
      int? origin,
      int? statut,
      ) async {
    // Show loading state before making the API call
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch incidents from the service
      final rawIncidents = await IncidentService().getFilteredProblems(
        boutiqueId,
        coefId,
        cluster,
        origin,
        statut,
      );

      // Process and map the raw incidents to Problem objects
      List<Problem> processedIncidents = rawIncidents.map<Problem>((incident) {
        return Problem(
          id: incident['id'] ?? 0,
          userId: incident['userId'] ?? 0,
          boutiqueId: incident['boutiqueId'] ?? 0,
          boutique: incident['boutique'] != null
              ? BoutiqueModel.fromJson(incident['boutique'])
              : null, // Handle null boutique
          description: incident['description'] ?? 'N/A',
          commentaire: incident['commentaire'] ?? 'N/A',
          problemImageBefore: incident['problemImageBefore'],
          problemImageAfter: incident['problemImageAfter'],
          jointFileBefore: incident['jointFileBefore'],
          jointFileAfter: incident['jointFileAfter'],
          coefId: incident['coefId'] ?? 0,
          coefficient: incident['coefficient'] != null
              ? Coefficient.fromJson(incident['coefficient'])
              : null,
          cluster: incident['cluster'] ?? 0,
          origin: incident['origin'] ?? 0,
          declarationDate: incident['declarationDate'] != null
              ? DateTime.parse(incident['declarationDate'])
              : DateTime.now(),
          closedDate: incident['closedDate'] != null
              ? DateTime.parse(incident['closedDate'])
              : null, // Handle null closedDate
          status: incident['status'] ?? 0,
          closingComment: incident['closingComment'] ?? 'No comment',
          cost: (incident['cost'] ?? 0).toDouble(),
        );
      }).toList();

      // Update state with the processed incidents
      setState(() {
        _incidents = processedIncidents;
        _totalIncidents = _incidents.length;
        _isLoading = false;
      });
    } catch (e) {
      // Handle errors gracefully
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error fetching incidents: $e');
    }
  }




  Future<void> _applyFilters() async {
    // Trigger the API call with selected filters
    await _fetchIncidents(
       _selectedBoutiqueId,
       _selectedPriority,
       _selectedCluster,
       _selectedOrigin,
       _selectedStatus,
    );
  }

  Future<void> _handleRefresh() async {
    // Refresh the incidents list with current filters
    await _fetchIncidents(
       _selectedBoutiqueId,
       _selectedPriority,
       _selectedCluster,
       _selectedOrigin,
       _selectedStatus,
    );
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, Function(DateTime?) onDateSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    onDateSelected(pickedDate);
  }
  var _statusValidation = null;

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
                child: Text(boutique.libelle ?? 'No Name'), // Display boutique name
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
        SizedBox(height: 10), // Spacing

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
        ),
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
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Statut',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<int>(value: null, child: Text('Tous')),
            DropdownMenuItem<int>(value: 0, child: Text('Non Résolu')),
            DropdownMenuItem<int>(value: 1, child: Text('Clôturé')),
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







  Widget _listItem(Problem problem) {
    // Define a dictionary for statut colors
    final Map<int, Color> statutColors = {
      1: Colors.yellow,
      2: Colors.greenAccent,  // Statut 1: Green
      3: Colors.orange, // Statut 2: Orange
      4: Colors.blueAccent,    // Statut 3: Red
      5: Colors.green,
    };

    // Get the color based on the statut, or use a default color
    final Color borderColor = statutColors[problem.status] ?? Colors.grey;

    // Format the date (display only the date part)
    final String formattedDate = problem.declarationDate != null
        ? DateFormat('yyyy-MM-dd').format(problem.declarationDate!)
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Decr:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      problem.coefficient?.libelle ?? 'No priority',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.0),
                Text(
                  problem.description ?? 'No description',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],

                  ),
                ),
                SizedBox(height: 8.0),

                // Commentaire
                Text(
                  'Commentaire:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  problem.commentaire ?? 'No comment',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.0),

                // Date déclaration
                Text(
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), // Adjusted padding for SafeArea
      positive: AwesomeSheetAction(
          title: 'Consulter',
        onPressed: ()=> {},
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
        icon: item["clouture"] != null ? Iconsax.close_circle :Iconsax.tick_circle,
      ),
    );
  }



  void _showConfirmationDialog(Map<String, dynamic> item) {
    AwesomeBottomSheet().show(
      context: context,
      title: Text('Confirmer Clôture'),
      description: Text('Êtes-vous sûr de vouloir changer l état de cloture "${item['questionLibelle'] ?? 'No question'}"?'),
      color: CustomSheetColor(
        mainColor: const Color(0xAD0BB819),
        accentColor: const Color(0xFF0BB819),
        iconColor: Colors.white,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0), // Adjusted padding for SafeArea
      positive: AwesomeSheetAction(
        onPressed: () async {
          Navigator.of(context).pop(); // Close the bottom sheet

          // Extract the questionId from the item
          final questionId = item['id'] as int?; // Ensure that 'questionId' exists and is of type int

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
  void dispose() {
    _missionLibelleController.dispose();
    _sousMissionLibelleController.dispose();
    _questionLibelleController.dispose();
    _actionIdController.dispose();
    _boutiqueLibelleController.dispose();
    _statusValidationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => IncidentFormWidget()),
          );
        },
        backgroundColor: TColors.primary,
        child: const Icon(Iconsax.add_circle, color: Colors.white),
      ),
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        springAnimationDurationInMilliseconds: 300, // Speed up the animation
        height: 60.0, // Adjust the height as needed
        color: TColors.primary,
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(_showFilters ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Incidents: $_totalIncidents',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_showFilters) _buildFilterForm(),
                    if (_isLoading) const Center(child: CircularProgressIndicator()),
                    if (_hasError)
                      const Center(child: Text('Error loading incidents.')),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _incidents.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: OpenContainer(
                              transitionType: ContainerTransitionType.fadeThrough, // Smooth fade transition
                              openBuilder: (context, _) {
                                return ConsultProblem(problemId: _incidents[index].id); // Pass the problemId instead of the entire problem
                              },
                              closedElevation: 0.0,
                              closedShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              closedColor: Colors.transparent,
                              closedBuilder: (context, openContainer) {
                                return GestureDetector(
                                  onTap: openContainer, // Trigger animation
                                  child: _listItem(_incidents[index]), // Pass the incident to list item display
                                );
                              },
                            )
                            ,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }






}
