import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    try {
      // Update the mission's planifiedAt date
      widget.mission.planifiedAt = _selectedDate;

      // Call the updateMission service
      await _missionService.updateMission(widget.mission.id, widget.mission,3);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mission updated successfully.')),
      );

      // Optionally, you could pop the screen or update the UI
      Navigator.pop(context);
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update mission: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get boutique information
    final boutique = widget.mission.boutique;
    final boutiqueLibelle = boutique?.libelle ?? 'No Boutique Name';
    final boutiqueCode = boutique?.code ?? 'No Boutique Code';
    final planifiedAt = widget.mission.planifiedAt != null
        ? _dateFormat.format(widget.mission.planifiedAt!)
        : 'No Date';

    return Scaffold(
      appBar: AppBar(
        title: Text('Rapporter Mission'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mission Info:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Code: ${widget.mission.missionCode ?? 'No Code'}'),
            Text('Libelle: ${widget.mission.libelle ?? 'No Title'}'),
            Text('Description: ${widget.mission.description ?? 'No Description'}'),
            SizedBox(height: 16),
            Text(
              'Date de planification:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(planifiedAt),
            SizedBox(height: 16),
            Text(
              'Information Boutique:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Boutique Code: $boutiqueCode'),
            Text('Boutique Libelle: $boutiqueLibelle'),
            SizedBox(height: 25),
            Text(
              'Choisir la date pour rapporter la mission',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Display the selected date
            if (_selectedDate != null)
              Text(
                'Date sélectionner: ${_dateFormat.format(_selectedDate!)}',
                style: TextStyle(fontSize: 16,),
              ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: _selectedDate == null
                        ? 'Select a date'
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
                child: Text('Reporter'),
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
