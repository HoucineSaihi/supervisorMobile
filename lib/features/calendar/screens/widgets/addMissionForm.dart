import 'package:flutter/material.dart';
import 'package:supervisormobile/features/calendar/DTOs/PlanifyMissionDTO.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/missionDetails.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/UserChecklistAssignment.dart';
import '../../services/AssignementService.dart';

class AddMissionForm extends StatefulWidget {
  final DateTime? Date; // Add this parameter

  AddMissionForm({Key? key, this.Date}) : super(key: key);

  @override
  _AddMissionFormState createState() => _AddMissionFormState();
}


class _AddMissionFormState extends State<AddMissionForm> {
  final MissionService _missionService = MissionService();
  List<BoutiqueModel> _boutiques = [];
  List<Mission> _notPlanifiedMissions = [];
  int? _selectedBoutiqueId = null;
  int? _selectedMissionId = null;
  bool _isLoadingBoutiques = true;
  bool _isLoadingMissions = false;
  bool _isLoading = false;


  List<UserChecklistAssignment> assignments = [];
  late Assignementservice assignementService;
  @override
  void initState() {
    super.initState();
    assignementService = Assignementservice();
    _initializeData();
    get_assignement();
  }

  Future<void> get_assignement()async {
    try {
      List<UserChecklistAssignment> fetchedAssignments = await assignementService.getAssignmentsByUserId();
      setState(() {
        assignments = fetchedAssignments;  // Store fetched data in assignments array
      });
    } catch (e) {
      print('Error fetching assignments: $e');
    }
  }
  Future<void> _initializeData() async {
    try {
      var btqs = await _missionService.getBoutiques();

      setState(() {
        _boutiques = btqs;
        _isLoadingBoutiques = false;
        _isLoadingMissions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBoutiques = false;
        _isLoadingMissions = false;
      });
    }
  }
  final _storage = FlutterSecureStorage();

  void _navigateToMissionDetails(int missionId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MissionDetailsWidget(
          missionId: missionId,
          mode: 0,
          status: 0,// Pass the mode as needed
        ),
      ),
    );
  }

  Future<void> _handleAddMission() async {
    if (_selectedBoutiqueId == null || _selectedMissionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: 'Error!',
            message: 'Please select both boutique and mission.',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
      return;
    }
    String? userIdString = await _storage.read(key: 'currentUserId');
    var _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

    PlanifyMissionDTO payload = PlanifyMissionDTO(planifiedAt: DateTime(widget.Date!.year, widget.Date!.month, widget.Date!.day)
        .add(Duration(seconds: 10)), posId: _selectedBoutiqueId!, assignementId: _selectedMissionId!);

      await _missionService.addMission(payload,context);

      Navigator.pop(context, true); // Navigate back

  }





  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Ajouter une mission'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Boutique Selection
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Choisir une boutique',
                  border: OutlineInputBorder(),
                ),
                items: _boutiques.map((boutique) {
                  return DropdownMenuItem<int>(
                    value: boutique.id,
                    child: Text(boutique.libelle ?? 'No Name'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  _selectedBoutiqueId = newValue;

                  setState(() {
                  });
                },
                value: _selectedBoutiqueId,
              ),
              SizedBox(height: 16.0),

              // Display selected Boutique Info
              if (_selectedBoutiqueId != null)
                Card(
                  child: ListTile(
                    title: Text('Boutique Info'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Code: ${_boutiques.firstWhere((b) => b.id == _selectedBoutiqueId).code ?? 'N/A'}'),
                        Text(
                            'Libelle: ${_boutiques.firstWhere((b) => b.id == _selectedBoutiqueId).libelle ?? 'N/A'}'),
                        Text(
                            'Adresse: ${_boutiques.firstWhere((b) => b.id == _selectedBoutiqueId).adress ?? 'N/A'}'),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 16.0),

              // Mission Selection
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Choisir une mission',
                  border: OutlineInputBorder(),
                ),
                items: assignments.isNotEmpty
                    ? assignments.map((assignment) {
                  return DropdownMenuItem<int>(
                    value: assignment.id,
                    child: Text(
                        '${assignment.checklist?.libelle ?? 'No Name'} -- ${assignment.checklist?.missionCode ?? 'No Code'}'),
                  );
                }).toList()
                    : [],  // Empty list if no assignments
                onChanged: (int? newValue) {
                  print("this is he new value ");
                  print(newValue);
                  setState(() {
                    _selectedMissionId = newValue;
                  });
                },
                value: _selectedMissionId != null && _selectedMissionId != 0
                    ? _selectedMissionId
                    : null,  // Safely handle the default value
              ),

              SizedBox(height: 16.0),

              // Display selected Mission Info
              if (_selectedMissionId != null)
                GestureDetector(
                  onTap: () => _navigateToMissionDetails(_selectedMissionId!),
                  child: Card(
                    child: ListTile(
                      title: Text('Mission Info'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Code: ${assignments.firstWhere((m) => m.id == _selectedMissionId).checklist!.libelle ?? 'N/A'}'),
                          Text(
                              'Libelle: ${assignments.firstWhere((m) => m.id == _selectedMissionId).checklist!.libelle  ?? 'N/A'}'),

                          Text(
                              'Description: ${assignments.firstWhere((m) => m.id == _selectedMissionId).checklist!.description  ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 16.0),

              // Display selected Mission Info

              SizedBox(height: 16.0),

              // Add Mission Button
              ElevatedButton(
                onPressed: _handleAddMission,
                child: Text('Ajouter'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: TColors.buttonSecondary,
                  side : const BorderSide(color: TColors.buttonSecondary),


                ),
              ),

            ],
          ),
        ),
      ),
    );
  }


}
