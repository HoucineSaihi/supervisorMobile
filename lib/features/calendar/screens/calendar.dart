import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:supervisormobile/common/widgets/appbar/appbar.dart';
import 'package:supervisormobile/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/screens/checklist.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/RapporterMissionWidget.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/calendar_appbar.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sticky_float_button/sticky_float_button.dart';

class CalendarPlanning extends StatefulWidget {
  const CalendarPlanning({super.key});

  @override
  _CalendarPlanningState createState() => _CalendarPlanningState();
}

class _CalendarPlanningState extends State<CalendarPlanning> {
  late Future<List<Mission>> futureMissions;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<int> userIds = [2]; // example userIds
  List<int> boutiqueIds = []; // example boutiqueIds

  @override
  void initState() {
    super.initState();
    futureMissions = MissionService()
        .getPlanifiedMissions(userIds, boutiqueIds, _focusedDay);
  }

  Map<String, String> getStatusColors(int? status) {
    final statusColors = {
      1: {
        'primary': '0xFF00008b',
        'secondary': '0xFF00008b',
        'status': 'Planifié'
      },
      2: {
        'primary': '0xFF9932CC',
        'secondary': '0xFF9932CC',
        'status': 'En Cours'
      },
      3: {
        'primary': '0xFFB8860B',
        'secondary': '0xFFB8860B',
        'status': ' Reporté'
      },
      4: {
        'primary': '0xFF008B8B',
        'secondary': '0xFF008B8B',
        'status': 'Confirmé'
      },
      5: {
        'primary': '0xFF8B0000',
        'secondary': '0xFF8B0000',
        'status': 'Annulé'
      },
      6: {
        'primary': '0xFF006400',
        'secondary': '0xFF006400',
        'status': 'Terminé'
      },
    };

    final colors = statusColors[status ?? 0] ??
        {
          'primary': '0xFF808080',
          'secondary': '0xFF808080',
          'status': 'unknown'
        };

    return {
      'primary': colors['primary']!,
      'secondary': colors['secondary']!,
      'status': colors['status']!
    };
  }
  Widget _body() {
    return Center(
      child: GestureDetector(onTap: () {}, child: const Text("Sticky")),
    );
  }

  Widget _floatButton() {
    return const CircleAvatar(
      backgroundColor: Colors.grey,
      child: Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

  void _showModal(BuildContext context, Mission mission) {
    final MissionService _missionService =
        MissionService(); // Initialize the MissionService

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Modifier la mission'),
          content: Text('Choisissez une option pour modifier la mission'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                try {
                  await _missionService.updateMission(mission.id, mission, 5);
                  Navigator.of(context).pop(); // Close the dialog after update
                } catch (e) {
                  // Handle error if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update mission: $e')),
                  );
                }
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        RapporterMissionWidget(mission: mission),
                  ),
                );
              },
              child: Text('Reporter'),
            ),
          ],
        );
      },
    );
  }

  Map<int, int> countMissionsByStatus(List<Mission> missions) {
    // Define all possible statuses
    const List<int> possibleStatuses = [1, 2, 3, 4, 5, 6];

    // Initialize statusCount with default 0 values for all possible statuses
    Map<int, int> statusCount = {
      for (var status in possibleStatuses) status: 0
    };

    for (var mission in missions) {
      int status = mission.status ?? 0;
      if (statusCount.containsKey(status)) {
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }
    }

    return statusCount;
  }

  void _showBoutiqueInfo(BuildContext context, BoutiqueModel boutique) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Boutique Info',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20, // Increase title font size
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // Add spacing between attributes
                child: RichText(
                  text: TextSpan(
                    text: 'Code: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Increase font size
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: boutique.code ?? 'No Code',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16, // Increase font size
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // Add spacing between attributes
                child: RichText(
                  text: TextSpan(
                    text: 'Libelle: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Increase font size
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: boutique.libelle ?? 'No Libelle',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16, // Increase font size
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // Add spacing between attributes
                child: RichText(
                  text: TextSpan(
                    text: 'City: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Increase font size
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: boutique.city ?? 'No City',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16, // Increase font size
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // Add spacing between attributes
                child: RichText(
                  text: TextSpan(
                    text: 'Region: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Increase font size
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: boutique.region ?? 'No Region',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16, // Increase font size
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // Add spacing between attributes
                child: RichText(
                  text: TextSpan(
                    text: 'Country: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Increase font size
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: boutique.country ?? 'No Country',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16, // Increase font size
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                // Add spacing between attributes
                child: RichText(
                  text: TextSpan(
                    text: 'Address: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Increase font size
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: boutique.adress ?? 'No Address',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16, // Increase font size
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  double calculateAnsweredPercentage(Mission mission) {
    int totalQuestions = 0;
    int answeredQuestions = 0;

    for (var sousMission in mission.sousMissions ?? []) {
      for (var question in sousMission.missionQuestions ?? []) {
        totalQuestions++;
        if (question.reponse != null && question.reponse!.isNotEmpty) {
          answeredQuestions++;
        }
      }
    }

    if (totalQuestions == 0) {
      return 0;
    }

    return (answeredQuestions / totalQuestions) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = THelperFunctions.isDarkMode(context);

    double headerHeight;
    switch (_calendarFormat) {
      case CalendarFormat.month:
        headerHeight = 500.0;
        break;
      case CalendarFormat.twoWeeks:
        headerHeight = 300.0;
        break;
      case CalendarFormat.week:
        headerHeight = 230.0;
        break;
      default:
        headerHeight = 500.0; // Default height if needed
        break;
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TPrimaryHeaderContainer(
              height: headerHeight,
              child: Column(
                children: [
                  THomeAppBar(),
                  TableCalendar(
                    firstDay: DateTime.utc(2021, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          futureMissions = MissionService()
                              .getPlanifiedMissions(
                              userIds, boutiqueIds, selectedDay);
                        });
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ],
              ),
              secondChild: FutureBuilder<List<Mission>>(
                future: futureMissions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Column(
                      children: [
                        Text(
                          'Vous avez 0 missions pour ce jour',
                          style: TextStyle(
                            color: isDarkMode
                                ? TColors.textWhite
                                : TColors.darkGrey,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tous les missions sont regroupés avec les boutiques',
                          style: TextStyle(
                            color: TColors.darkGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  } else {
                    final missions = snapshot.data!;
                    final statusCounts = countMissionsByStatus(missions);
                    final totalMissions = missions.length;
                    final allTermine = (statusCounts[1] ?? 0) == 0 &&
                        (statusCounts[6] ?? 0) > 0;

                    return Column(
                      children: [
                        Column(
                          children: [
                            Center(
                              child: Text(
                                allTermine
                                    ? 'Tous les missions terminées ✔️'
                                    : 'Vous avez ${statusCounts[1] ?? 0} mission Planifié',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? TColors.textWhite
                                      : TColors.dark,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign
                                    .center, // Center the text within its container
                              ),
                            ),
                            SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Tous les missions sont regroupés par boutique',
                                style: TextStyle(
                                  color: TColors.darkGrey,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign
                                    .center, // Center the text within its container
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        GroupedListView<Mission, String>(
                          shrinkWrap: true,
                          elements: missions,
                          groupBy: (Mission mission) =>
                          mission.boutique?.libelle ?? 'No Boutique',
                          groupSeparatorBuilder: (String boutiqueLibelle) {
                            // Find a sample mission with the given boutiqueLibelle
                            final sampleMission = missions.firstWhere(
                                  (mission) =>
                              mission.boutique?.libelle == boutiqueLibelle,
                            );

                            return Center(
                              child: GestureDetector(
                                onTap: () {
                                  // Pass the boutique object to the _showBoutiqueInfo method
                                  _showBoutiqueInfo(
                                      context, sampleMission.boutique!);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.store,
                                        // Replace with appropriate icon
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        boutiqueLibelle,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          itemBuilder: (context, Mission mission) {
                            final statusData = getStatusColors(mission.status);
                            final colors = getStatusColors(mission.status);
                            final percentage =
                            calculateAnsweredPercentage(mission);

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MissionDetailsScreen(mission: mission),
                                  ),
                                );
                              },
                              onLongPress: () {
                                _showModal(context,
                                    mission); // Pass the mission to the modal
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: TColors.softGrey,
                                  border: Border(
                                    left: BorderSide(
                                      color: Color(int.parse(colors['primary']!
                                          .replaceFirst('0x', '0xff'))),
                                      width:
                                      8.0, // Adjust the width of the border as needed
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(
                                          0, 3), // changes position of shadow
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      // Row for code and libelle with status
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Code: ${mission.missionCode ?? 'No Code'}',
                                                        style: TextStyle(
                                                          color: Color(int.parse(
                                                              colors['secondary']!
                                                                  .replaceFirst(
                                                                  '0x',
                                                                  '0xff'))),
                                                          fontWeight:
                                                          FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${statusData['status'] ?? 'Unknown'}',
                                                      style: TextStyle(
                                                        color: Color(int.parse(
                                                            statusData[
                                                            'secondary']!
                                                                .replaceFirst(
                                                                '0x',
                                                                '0xff'))),
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Libelle: ${mission.libelle ?? 'No Libelle'}',
                                                  style: TextStyle(
                                                    color: Color(int.parse(
                                                        colors['secondary']!
                                                            .replaceFirst(
                                                            '0x', '0xff'))),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Description: ${mission.description ?? 'No Description'}',
                                                  style: TextStyle(
                                                    color: Color(int.parse(
                                                        colors['secondary']!
                                                            .replaceFirst(
                                                            '0x', '0xff'))),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      // Linear progress indicator
                                      Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: percentage / 100,
                                              backgroundColor: Colors.grey[200],
                                              color: Color(int.parse(colors['primary']!.replaceFirst('0x', '0xff'))),
                                            ),
                                          ),
                                          SizedBox(width: 8), // Space between the progress indicator and text
                                          Text(
                                            '${percentage.toStringAsFixed(0)}%', // Display percentage as text
                                            style: TextStyle(
                                              color: Color(int.parse(
                                                  colors['primary']!
                                                      .replaceFirst('0x', '0xff'))),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: StickyFloatButton(
        icon: Icons.add,
        onPressed: () {
          // Define what happens when the button is pressed
          print('Floating action button pressed');
        },
        iconSize: 30.0,
        buttonColor: Colors.blue,
        iconColor: Colors.white,
      ),
    );
  }

}

class StickyFloatButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color buttonColor;
  final Color iconColor;

  StickyFloatButton({
    required this.icon,
    required this.onPressed,
    this.iconSize = 24.0,
    this.buttonColor = Colors.blue,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: buttonColor,
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}
