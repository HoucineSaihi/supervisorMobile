import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:supervisormobile/common/widgets/appbar/appbar.dart';
import 'package:supervisormobile/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/RapporterMissionWidget.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/addMissionForm.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/calendar_appbar.dart';
import 'package:supervisormobile/features/calendar/screens/widgets/missionDetails.dart';
import 'package:supervisormobile/features/calendar/services/missionService.dart';
import 'package:supervisormobile/utils/Helpers/helper_functions.dart';
import 'package:supervisormobile/utils/constants/colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sticky_float_button/sticky_float_button.dart';
import 'package:flutter_awesome_bottom_sheet/flutter_awesome_bottom_sheet.dart';
import 'dart:html'; // Import for web localStorage

class CalendarPlanning extends StatefulWidget {
  const CalendarPlanning({super.key});

  @override
  _CalendarPlanningState createState() => _CalendarPlanningState();
}

class _CalendarPlanningState extends State<CalendarPlanning> {
  late Future<List<Mission>> futureMissions;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  List<int> boutiqueIds = []; // example boutiqueIds

  @override
  void initState() {
    super.initState();
    _handleRefresh();
    _loadAuthToken();

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


  void _showModal(BuildContext context, Mission mission) {
    final MissionService _missionService = MissionService(); // Initialize the MissionService

    final AwesomeBottomSheet _awesomeBottomSheet = AwesomeBottomSheet(); // Create an instance of AwesomeBottomSheet

    _awesomeBottomSheet.show(
      context: context,
      title: const Text("Modifier la mission"),
      description: const Text("Choisissez une option pour modifier la mission"),
      color: CustomSheetColor(
        mainColor: TColors.primary,
        accentColor: TColors.secondary,
        iconColor: Colors.white,
      ),
      positive: AwesomeSheetAction(
        onPressed: () async {
          Navigator.of(context).pop(); // Close the bottom sheet
          await _showConfirmationBottomSheet(
            context: context,
            title: 'Annuler',
            content: 'Êtes-vous sûr de vouloir annuler la mission?',
            color: CustomSheetColor(
              mainColor: const Color(0xE88B0000),
              accentColor: const Color(0xFF8B0000),
              iconColor: Colors.white,

            ),
            onConfirm: () async {
              try {
                await _missionService.updateMission(mission.id, mission, 5);
                setState(() {}); // Refresh state
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update mission: $e')),
                );
              }
            },
          );
        },
        title: 'Annuler',
        icon: Icons.cancel,
      ),
      negative: AwesomeSheetAction(
        onPressed: () async {
          Navigator.of(context).pop(); // Close the bottom sheet
          await _showConfirmationBottomSheet(
            context: context,
            title: 'Reporter',
            content: 'Êtes-vous sûr de vouloir reporter la mission?',
            color: CustomSheetColor(
              mainColor: const Color(0xE8B8860B),
              accentColor: const Color(0xFFB8860B),
              iconColor: Colors.white,
            ),
            onConfirm: () async {
              final shouldRefresh = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RapporterMissionWidget(mission: mission),
                ),
              );
              if (shouldRefresh == true) {
                setState(() {}); // Refresh state
              }
            },
          );
        },
        title: 'Reporter',
      ),
    );
  }

  Future<void> _showConfirmationBottomSheet({
    required BuildContext context,
    required String title,
    required String content,
    required CustomSheetColor color,
    required Future<void> Function() onConfirm,
  }) async {
    final AwesomeBottomSheet _awesomeBottomSheet = AwesomeBottomSheet(); // Create an instance of AwesomeBottomSheet

    _awesomeBottomSheet.show(
      context: context,
      title: Text(title),
      description: Text(content),
      icon: Icons.question_mark,
      color: color, // Use the provided color
      positive: AwesomeSheetAction(
        onPressed: () async {
          Navigator.of(context).pop(); // Close the bottom sheet
          await onConfirm(); // Execute the confirm action
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
                child: Text(
                  'Code: ${boutique.code ?? 'No Code'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increase font size
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Libelle: ${boutique.libelle ?? 'No Libelle'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increase font size
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'City: ${boutique.city ?? 'No City'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increase font size
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Region: ${boutique.region ?? 'No Region'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increase font size
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Country: ${boutique.country ?? 'No Country'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increase font size
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Address: ${boutique.adress ?? 'No Address'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increase font size
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

  Future<void> _handleRefresh() async {
    setState(() {
      futureMissions = MissionService()
          .getPlanifiedMissions([_currentUserID], boutiqueIds, _focusedDay);

    });
  }


  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

  Future<void> _loadAuthToken() async {
    // Retrieve the user ID from the browser's local storage
    String? userIdString = await window.localStorage['currentUserId'];

    // Update the state
    setState(() {
      // Convert the string to an integer, default to 0 if null or invalid
      _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;
      print(_currentUserID);
    });
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
        headerHeight = 330.0;
        break;
      case CalendarFormat.week:
        headerHeight = 250.0;
        break;
      default:
        headerHeight = 500.0; // Default height if needed
        break;
    }

    return Scaffold(
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        springAnimationDurationInMilliseconds: 300, // Speed up the animation
        height: 60.0, // Adjust the height as needed
        color: TColors.primary,
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
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
                                  .getPlanifiedMissions([_currentUserID], boutiqueIds, selectedDay);
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
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: TextStyle(color: Colors.white), // Text color of days
                          todayTextStyle: TextStyle(color: Colors.white), // Text color for today's day
                          selectedTextStyle: TextStyle(color: Colors.white), // Text color for selected day
                          weekendTextStyle: TextStyle(color: Colors.white), // Text color for weekend days
                          outsideTextStyle: TextStyle(color: Colors.white), // Text color for days outside the current month
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: Colors.white), // Text color for weekdays
                          weekendStyle: TextStyle(color: Colors.white), // Text color for weekends
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: TextStyle(color: Colors.white), // Header title text color
                          formatButtonVisible: true, // Show format button
                          formatButtonTextStyle: TextStyle(color: Colors.white), // Format button text color
                          formatButtonDecoration: BoxDecoration(
                            color: TColors.buttonDisabled, // Background color for format button
                            borderRadius: BorderRadius.circular(8.0), // Border radius for format button
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white), // Left navigation arrow color
                          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white), // Right navigation arrow color
                        ),
                        locale: Localizations.localeOf(context).languageCode,
                      )
            
            
            
                      ,
                    ],
                  ),
                  secondChild:  FutureBuilder<List<Mission>>(
                      future: futureMissions,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Column(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                // Center the text widgets
                                children: [
                                  Text(
                                    'Vous avez 0 missions pour ce jour',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? TColors.textWhite
                                          : TColors.darkGrey,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign
                                        .center, // Center text within the text widget
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Cliquer sur ajouter une mission, pour faire un planning',
                                    style: TextStyle(
                                      color: TColors.darkGrey,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign
                                        .center, // Center text within the text widget
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              SizedBox(
                                width: 250.0, // Set a fixed width for the button
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final shouldRefresh = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddMissionForm(Date: _selectedDay),
                                      ),
                                    );
                                    if(shouldRefresh == true){
                                      setState(() {
                                        futureMissions = MissionService()
                                            .getPlanifiedMissions([_currentUserID], boutiqueIds, _focusedDay);
                                      });
                                    }
                                  },
                                  icon: Icon(Iconsax.add, color: TColors.buttonPrimary), // Add the icon
                                  label: Text('Ajouter une mission'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: TColors.buttonPrimary, side: BorderSide(color: TColors.buttonPrimary, width: 2), // Border color and width
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    textStyle: TextStyle(fontSize: 16),
                                  ),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center, // Center the children horizontally
                                children: [
                                  SizedBox(
                                    width: 250.0, // Set a fixed width for the button
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddMissionForm(Date: _selectedDay),
                                          ),
                                        );
                                        if(shouldRefresh == true ) {
                                          setState(() {
                                            futureMissions = MissionService()
                                                .getPlanifiedMissions([_currentUserID], boutiqueIds, _focusedDay);
                                          });
                                        }
                                      },
                                      icon: Icon(Iconsax.add), // Add the icon
                                      label: Text('Ajouter une mission'),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 16.0),
                                        textStyle: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
            
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
                              SingleChildScrollView(
                                child: GroupedListView<Mission, String>(
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
                                      onTap: () async {
                                        final shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MissionDetailsWidget(missionId: mission.id,mode: 1,)                                  ),
                                        );
                                        if(shouldRefresh == true){
                                          setState(() {
                                            futureMissions = MissionService()
                                                .getPlanifiedMissions([_currentUserID], boutiqueIds, _focusedDay);
                                          });
                                        }
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
                                                      color: Color(int.parse(
                                                          colors['primary']!
                                                              .replaceFirst(
                                                                  '0x', '0xff'))),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  // Space between the progress indicator and text
                                                  Text(
                                                    '${percentage.toStringAsFixed(0)}%',
                                                    // Display percentage as text
                                                    style: TextStyle(
                                                      color: Color(int.parse(
                                                          colors['primary']!
                                                              .replaceFirst(
                                                                  '0x', '0xff'))),
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
        ),
      ),
    );
  }
}

