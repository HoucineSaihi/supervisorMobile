import 'package:flutter/material.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/missionDetails.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  int? _selectedBoutiqueId;
  int? _selectedMissionId;
  bool _isLoadingBoutiques = true;
  bool _isLoadingMissions = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final boutiquesFuture = _missionService.getBoutiques();
      final missionsFuture = _missionService.getAllNotPlanifiedMissions();

      final results = await Future.wait([boutiquesFuture, missionsFuture]);

      final boutiques = results[0] as List<BoutiqueModel>;
      final missions = results[1] as List<Mission>;

      setState(() {
        _boutiques = boutiques;
        _notPlanifiedMissions = missions;
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

    List<int> userIdArray = [];
    userIdArray.add(_currentUserID);

    final selectedMission = _notPlanifiedMissions.firstWhere((m) => m.id == _selectedMissionId);

    // Reset mission properties
    selectedMission.id = 0;
    selectedMission.boutique = null;
    selectedMission.boutiqueId = _selectedBoutiqueId;
    selectedMission.userId = _currentUserID; // Set the user ID as needed
    selectedMission.status = 1;
    selectedMission.planifiedAt = widget.Date != null
        ? DateTime(widget.Date!.year, widget.Date!.month, widget.Date!.day)
        .add(Duration(seconds: 10))
        : null; // Add 10 seconds to the date
 // Use the selectedDate here

    // Process each sousMission
    for (var sousMission in selectedMission.sousMissions ?? []) {
      sousMission.code = sousMission.code?.toUpperCase();
      sousMission.id = 0;
      sousMission.missionId = 0;

      // Process each missionQuestion in sousMission
      for (var question in sousMission.missionQuestions ?? []) {
        question.id = 0;
        question.sousMissionId = 0;

      }
    }

      await _missionService.addMission(selectedMission,context);

      Navigator.pop(context, true); // Navigate back

  }



  Future<void> _fetchNotPlanifiedMissions() async {
    if (_selectedBoutiqueId == null) return;

    setState(() {
      _isLoadingMissions = true;
    });
    try {
      final missions = await _missionService.getAllNotPlanifiedMissions();
      setState(() {
        _notPlanifiedMissions = missions;
        _isLoadingMissions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMissions = false;
      });
    }
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
                  setState(() {
                    _selectedBoutiqueId = newValue;
                    _fetchNotPlanifiedMissions();
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
                items: _notPlanifiedMissions.map((mission) {
                  return DropdownMenuItem<int>(
                    value: mission.id,
                    child: Text(
                        '${mission.libelle ?? 'No Name'} -- ${mission.missionCode ?? 'No Code'}'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedMissionId = newValue;
                  });
                },
                value: _selectedMissionId,
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
                              'Code: ${_notPlanifiedMissions.firstWhere((m) => m.id == _selectedMissionId).missionCode ?? 'N/A'}'),
                          Text(
                              'Libelle: ${_notPlanifiedMissions.firstWhere((m) => m.id == _selectedMissionId).libelle ?? 'N/A'}'),

                          Text(
                              'Description: ${_notPlanifiedMissions.firstWhere((m) => m.id == _selectedMissionId).description ?? 'N/A'}'),
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
