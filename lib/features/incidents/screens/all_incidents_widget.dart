import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_awesome_bottom_sheet/flutter_awesome_bottom_sheet.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/edit_question_response.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/features/incidents/services/incident_service.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../../calendar/models/actionsModel.dart';

class AllIncidentsWidget extends StatefulWidget {
  AllIncidentsWidget({Key? key}) : super(key: key);

  @override
  _AllIncidentsWidgetState createState() => _AllIncidentsWidgetState();
}

class _AllIncidentsWidgetState extends State<AllIncidentsWidget> {
  late final IncidentService _incidentService;
  late Future<List<ActionM>> _actionsFuture;
  List<ActionM> _actions = [];


  List<Map<String, dynamic>> _incidents = [];
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
  int? _selectedActionId;

  @override
  void initState() {
    super.initState();
    _incidentService = IncidentService();
    _missionService.getBoutiques().then((boutiques) {
      setState(() {
        _boutiques = boutiques;
      });

      _fetchIncidents(userId: 2);
    });

    _actionsFuture = MissionService().getActions();
    _actionsFuture.then((actions) {
      if (mounted) {
        setState(() {
          _actions = actions;
        });
      }
    });
  }
  int _totalIncidents = 0;

  Future<void> _fetchIncidents({
    String? mLibelle,
    String? smLibelle,
    String? qLibelle,
    int? actionId,
    String? btqLibelle,
    int? statusValidation,
    required int userId,
    DateTime? dateDb,
    DateTime? dateF,
    DateTime? dateClotDb,
    DateTime? dateClotF,
  }) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final incidents = await _incidentService.getAllRecommendationsByIdUserFiltered(
        mLibelle: mLibelle,
        smLibelle: smLibelle,
        qLibelle: qLibelle,
        actionId: _selectedActionId,
        btqLibelle: btqLibelle,
        statusValidation: statusValidation,
        userId: userId,
        dateDb: dateDb,
        dateF: dateF,
        dateClotDb: dateClotDb,
        dateClotF: dateClotF,
      );
      setState(() {
        _incidents = List<Map<String, dynamic>>.from(incidents);
        _totalIncidents = _incidents.length; // Update the total count
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }


  void _applyFilters() async {
    await _fetchIncidents(
      mLibelle: _missionLibelleController.text,
      smLibelle: _sousMissionLibelleController.text,
      qLibelle: _questionLibelleController.text,
      actionId: _selectedActionId,
      btqLibelle: _boutiqueLibelleController.text,
      statusValidation: int.tryParse(_statusValidationController.text),
      userId: 2, // Assuming userId is 2 for this example
      dateDb: _dateDb,
      dateF: _dateF,
      dateClotDb: _dateClotDb ,
      dateClotF: _dateClotF ,
    );

  }
  Future<void> _handleRefresh() async {
    setState(() async { await _fetchIncidents(
      mLibelle: _missionLibelleController.text,
      smLibelle: _sousMissionLibelleController.text,
      qLibelle: _questionLibelleController.text,
      actionId: _selectedActionId,
      btqLibelle: _boutiqueLibelleController.text,
      statusValidation: int.tryParse(_statusValidationController.text),
      userId: 2, // Assuming userId is 2 for this example
      dateDb: _dateDb,
      dateF: _dateF,
      dateClotDb: _dateClotDb ,
      dateClotF: _dateClotF ,
    );
  });
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _missionLibelleController,
          decoration: InputDecoration(labelText: 'Mission Libelle'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _sousMissionLibelleController,
          decoration: InputDecoration(labelText: 'Sous Mission Libelle'),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _questionLibelleController,
          decoration: InputDecoration(labelText: 'Question Libelle'),
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Choisir une boutique',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('Tous'),
            ),
            ..._boutiques.map((boutique) {
              return DropdownMenuItem<String>(
                value: boutique.libelle,
                child: Text(boutique.libelle ?? 'No Name'),
              );
            }).toList(),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _boutiqueLibelleController.text = newValue ?? '';
            });
          },
          value: _boutiqueLibelleController.text.isNotEmpty
              ? _boutiqueLibelleController.text
              : null,
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _statusValidation,
          decoration: InputDecoration(
            labelText: 'Status Validation',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(value: null, child: Text('Tous')),
            DropdownMenuItem(value: 1, child: Text('Non Cloturée')),
            DropdownMenuItem(value: 2, child: Text('Cloturée')),
          ],
          onChanged: (value) {
            setState(() {
              _statusValidation = value;
              _statusValidationController.text =
                  value?.toString() ?? '';
            });
          },
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'Choisir une action',
            border: OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<int>(
              value: null,
              child: Text('Tous'),
            ),
            ..._actions.map((action) {
              return DropdownMenuItem<int>(
                value: action.id,
                child: Text(
                  action.description,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              );
            }).toList(),
          ],
          onChanged: (int? newValue) {
            setState(() {
              _selectedActionId = newValue;
            });
          },
          value: _selectedActionId,
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => _selectDate(context, _dateDb, (date) {
                  setState(() {
                    _dateDb = date;
                  });
                }),
                child: Text(_dateDb != null
                    ? _dateFormat.format(_dateDb!)
                    : 'Date Début'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextButton(
                onPressed: () => _selectDate(context, _dateF, (date) {
                  setState(() {
                    _dateF = date;
                  });
                }),
                child: Text(_dateF != null
                    ? _dateFormat.format(_dateF!)
                    : 'Date Fin'),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _applyFilters,
            icon: Icon(Iconsax.filter, size: 20),
            label: Text('Appliquer Filtre'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
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
                      item["missionLibelle"] ?? 'No mission',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item["sousMissionLibelle"] ?? 'No sous-mission',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item["questionLibelle"] ?? 'No question',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item["actionLibelle"] ?? 'No action',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item["responsable"] ?? 'No responsable',
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
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditQuestionResponse(questionId: item["id"] ?? 0),
            ),
          );
        },
        title: 'Consulter',
        icon: Iconsax.eye,
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
      body: Padding(
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
                    IconButton(
                      icon: Icon(Iconsax.refresh), // Replace with the reload icon you are using
                      onPressed: () {
                        // Your function to reload or refresh
                        _handleRefresh();
                      },
                    ),

                ],
              ),
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

    );
  }



}
