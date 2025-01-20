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
      final incidents = await IncidentService().getFilteredProblems(
         boutiqueId,
        coefId,
         cluster,
         origin,
         statut,
      );

      // Update state with the fetched incidents
      setState(() {
        _incidents = List<Map<String, dynamic>>.from(incidents);
        _totalIncidents = _incidents.length;
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors during API call
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      print("Error fetching incidents: $e");
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
            DropdownMenuItem<int>(value: 0, child: Text('Manuelle')),
            DropdownMenuItem<int>(value: 1, child: Text('Checklist')),
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






  Widget _listItem(Map<String, dynamic> item) {
    // Determine the border color based on clouture
    Color borderColor = item["clouture"] != null ? Colors.green : Colors.red;

    // Format the clouture date if it exists
    String cloutureDate = item["clouture"] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item["clouture"]))
        : '';

    return GestureDetector(
      onLongPress: () {
        // Show the Awesome Bottom Sheet when a long press is detected
        _showModal(context, item);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            top: BorderSide(
              color: borderColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission :'+item["missionLibelle"] ?? 'No mission',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Btq :'+item["boutiqueLibelle"] ?? 'No sous-mission',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Catégorie :'+item["sousMissionLibelle"] ?? 'No sous-mission',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Quest :'+item["questionLibelle"] ?? 'No question',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Action: '+item["actionLibelle"] ?? 'No action',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Resp: '+item["responsable"] ?? 'No responsable',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (item["clouture"] != null)
                Text(
                  cloutureDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.green, // Style for the clouture date
                  ),
                ),
            ],
          ),
        ),
      ),
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
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        springAnimationDurationInMilliseconds: 300, // Speed up the animation
        height: 60.0, // Adjust the height as needed
        color: TColors.primary,
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0), // Add top spacing from the device's top bar
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Align the icon to the end of the row
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
              // Add the button here
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => IncidentFormWidget()),
                    );
                  },
                  icon: const Icon(Iconsax.add_circle, color: Colors.white), // Modern icon from Iconsax
                  label: const Text(
                    "Ajouter un incident",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0), // Add spacing between the button and text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start
                  children: [
                    // Display the total number of incidents
                    Text(
                      'Total Incidents: $_totalIncidents',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (_showFilters) _buildFilterForm(),
                    if (_isLoading) const CircularProgressIndicator(),
                    if (_hasError) const Text('Error loading incidents.'),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _incidents.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical spacing
                            child: _listItem(_incidents[index]),
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
