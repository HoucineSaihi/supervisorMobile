import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';

class RapporterMissionWidget extends StatefulWidget {
  final Mission mission;

  RapporterMissionWidget({required this.mission, Key? key}) : super(key: key);

  @override
  _RapporterMissionWidgetState createState() => _RapporterMissionWidgetState();
}

class _RapporterMissionWidgetState extends State<RapporterMissionWidget> {
  DateTime? _selectedDate;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final MissionService _missionService = MissionService(); // Initialize the MissionService

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _reportMission() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: AppLocalizations.of(context)!.error,
            message: AppLocalizations.of(context)!.pleaseSelectDate,
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
      return;
    }

    try {
      // Update the mission's planifiedAt date
      widget.mission.planifiedAt = _selectedDate;

      // Call the updateMission service
      await _missionService.updateMission(widget.mission.id, widget.mission, 3);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: AppLocalizations.of(context)!.success,
            message: AppLocalizations.of(context)!.missionUpdatedSuccessfully,
            contentType: ContentType.success,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );

      Navigator.pop(context, true); // Navigate back

    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: AwesomeSnackbarContent(
            title: AppLocalizations.of(context)!.error,
            message: '${AppLocalizations.of(context)!.failedToUpdateMission}: $e',
            contentType: ContentType.failure,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Get boutique information
    final boutique = widget.mission.boutique;
    final boutiqueLibelle = boutique?.libelle ?? AppLocalizations.of(context)!.noName;
    final boutiqueCode = boutique?.code ?? AppLocalizations.of(context)!.noCode;
    final planifiedAt = widget.mission.planifiedAt != null
        ? _dateFormat.format(widget.mission.planifiedAt!)
        : AppLocalizations.of(context)!.noDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reportMission),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.missionInfo}:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.code}: ${widget.mission.missionCode ?? AppLocalizations.of(context)!.noCode}'),
            Text('${AppLocalizations.of(context)!.libelle}: ${widget.mission.libelle ?? AppLocalizations.of(context)!.noTitle}'),
            Text('${AppLocalizations.of(context)!.description}: ${widget.mission.description ?? AppLocalizations.of(context)!.noDescription}'),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.planningDate,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(planifiedAt),
            SizedBox(height: 16),
            Text(
              '${AppLocalizations.of(context)!.boutiqueInfo}:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('${AppLocalizations.of(context)!.code}: $boutiqueCode'),
            Text('${AppLocalizations.of(context)!.libelle}: $boutiqueLibelle'),
            SizedBox(height: 25),
            Text(
              AppLocalizations.of(context)!.chooseDateToReportMission,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Display the selected date
            if (_selectedDate != null)
              Text(
                '${AppLocalizations.of(context)!.selectedDate} ${_dateFormat.format(_selectedDate!)}',
                style: TextStyle(fontSize: 16,),
              ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.selectDate,
                    hintText: _selectedDate == null
                        ? AppLocalizations.of(context)!.selectADate
                        : _dateFormat.format(_selectedDate!),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity, // Make button take full width
              child: ElevatedButton(
                onPressed: _reportMission,
                child: Text(AppLocalizations.of(context)!.report),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
