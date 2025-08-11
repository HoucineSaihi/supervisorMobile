import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:supervisormobile/common/widgets/appbar/appbar.dart';
import 'package:supervisormobile/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:supervisormobile/features/calendar/models/boutiqueModel.dart';
import 'package:supervisormobile/features/calendar/models/missionModel.dart';
import 'package:supervisormobile/features/calendar/models/missionResponseModel.dart';
import 'package:supervisormobile/features/calendar/models/paginationModel.dart';
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
import 'dart:html' as html;  // For localStorage on web

import '../../../utils/Helpers/secure_storage_data.dart';

class CalendarPlanning extends StatefulWidget {
  const CalendarPlanning({super.key});

  @override
  _CalendarPlanningState createState() => _CalendarPlanningState();
}

class _CalendarPlanningState extends State<CalendarPlanning> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  List<int> boutiqueIds = []; // example boutiqueIds
  
  // Pagination state
  int _currentPage = 1;
  int _pageSize = 20; // Changed to 20 as requested
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  List<Mission> _allMissions = [];
  PaginationModel? _pagination;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    loadMissions(resetPagination: true);
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
   Future<void> loadMissions({bool resetPagination = true}) async {
     try {
       print('🔄 loadMissions: Starting to load missions...');
       
       // Retrieve the user ID from storage (localStorage for web)
       String? userIdString;
       int? userId;

       if (kIsWeb) {
         SharedPreferences prefs = await SharedPreferences.getInstance();
         userIdString = prefs.getString('currentUserId');
       } else {
         final _storage = FlutterSecureStorage();
         userIdString = await _storage.read(key: 'currentUserId');
       }

       _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;

       // Reset pagination if needed
       if (resetPagination) {
         _currentPage = 1;
         _allMissions.clear();
         _pagination = null;
         setState(() {
           _isInitialLoading = true;
         });
       }

       // Fetch missions based on the currentUserID and other parameters with pagination
       final response = await MissionService().getPlanifiedMissions(
         [_currentUserID],
         boutiqueIds,
         _focusedDay,
         pageNumber: _currentPage,
         pageSize: _pageSize,
       );

       setState(() {
         if (resetPagination) {
           _allMissions = response.data;
         } else {
           _allMissions.addAll(response.data);
         }
         _pagination = response.pagination;
         _isInitialLoading = false;
       });

       print('✅ loadMissions: Loaded ${response.data.length} missions, total: ${_allMissions.length}');

     } catch (e) {
       print('❌ Error loading missions: $e');
       setState(() {
         _isInitialLoading = false;
       });
     }
   }

     Future<void> loadMoreMissions() async {
    if (_isLoadingMore) return;

    print('🔄 loadMoreMissions: Starting to load more missions...');
    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Check if we have pagination info
      if (_pagination == null) {
        print('❌ loadMoreMissions: No pagination info available');
        setState(() {
          _isLoadingMore = false;
        });
        return;
      }
      
      print('📊 loadMoreMissions: Current pagination - hasNextPage: ${_pagination!.hasNextPage}, nextPageNumber: ${_pagination!.nextPageNumber}');
      
      if (!_pagination!.hasNextPage || _pagination!.nextPageNumber == null) {
        print('ℹ️ loadMoreMissions: No more pages to load');
        setState(() {
          _isLoadingMore = false;
        });
        return;
      }

      // Use the next page number from pagination
      final nextPage = _pagination!.nextPageNumber!;
      _currentPage = nextPage;
      print('📄 loadMoreMissions: Loading page $nextPage');
      
      final response = await MissionService().getPlanifiedMissions(
        [_currentUserID],
        boutiqueIds,
        _focusedDay,
        pageNumber: _currentPage,
        pageSize: _pageSize,
      );

      print('✅ loadMoreMissions: Received ${response.data.length} new missions');
      if (response.data.isNotEmpty) {
        setState(() {
          _allMissions.addAll(response.data);
          _pagination = response.pagination;
          _isLoadingMore = false;
        });
        print('📈 loadMoreMissions: Total missions now: ${_allMissions.length}');
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }

      print('✅ loadMoreMissions: Completed successfully');
    } catch (e) {
      print('❌ loadMoreMissions: Error loading more missions: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
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
    int totalQuestions =  mission.totalQuestion!;
    int answeredQuestions =  mission.progression!.toInt();

    return (answeredQuestions / totalQuestions) * 100;
  }

  Future<void> _handleRefresh() async {
    loadMissions(resetPagination: true);
  }


  final _storage = FlutterSecureStorage();
  int _currentUserID = 0;

   Future<void> _loadAuthToken() async {
     String? userIdString;
     if (kIsWeb) {
       SharedPreferences prefs = await SharedPreferences.getInstance();
       userIdString = prefs.getString('currentUserId');
     } else {
       final _storage = FlutterSecureStorage();
       userIdString = await _storage.read(key: 'currentUserId');
     }


     try {

       setState(() {
         _currentUserID = userIdString != null ? int.tryParse(userIdString) ?? 0 : 0;
       });
     } catch (e) {
       print("Error loading auth token: $e");
       setState(() {
         _currentUserID = 0;
       });
     }
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
        headerHeight = 500.0;
        break;
    }

    return Scaffold(
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        springAnimationDurationInMilliseconds: 300,
        height: 60.0,
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
                        daysOfWeekHeight: 30,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mois',
                          CalendarFormat.twoWeeks: '2 Semaine',
                          CalendarFormat.week: 'Semaine'
                        },
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          if (!isSameDay(_selectedDay, selectedDay)) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            loadMissions(resetPagination: true);
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
                          defaultTextStyle: TextStyle(color: Colors.white),
                          todayTextStyle: TextStyle(color: Colors.white),
                          selectedTextStyle: TextStyle(color: Colors.white),
                          weekendTextStyle: TextStyle(color: Colors.white),
                          outsideTextStyle: TextStyle(color: Colors.white),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: Colors.white),
                          weekendStyle: TextStyle(color: Colors.white),
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: TextStyle(color: Colors.white),
                          formatButtonVisible: true,
                          formatButtonTextStyle: TextStyle(color: Colors.white),
                          formatButtonDecoration: BoxDecoration(
                            color: TColors.buttonDisabled,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                        ),
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                    ],
                  ),
                  secondChild: _isInitialLoading
                      ? Center(child: CircularProgressIndicator())
                      : _allMissions.isEmpty
                          ? Column(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(Iconsax.refresh),
                                          onPressed: () => loadMissions(resetPagination: true),
                                          tooltip: 'Refresh Missions',
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Vous avez 0 missions pour ce jour',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? TColors.textWhite
                                            : TColors.darkGrey,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Cliquer sur ajouter une mission, pour faire un planning',
                                      style: TextStyle(
                                        color: TColors.darkGrey,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                SizedBox(
                                  width: 250.0,
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final shouldRefresh = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddMissionForm(Date: _selectedDay),
                                        ),
                                      );
                                      if (shouldRefresh == true) {
                                        loadMissions(resetPagination: true);
                                      }
                                    },
                                    icon: Icon(Iconsax.add, color: TColors.buttonPrimary),
                                    label: Text('Ajouter une mission'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: TColors.buttonPrimary,
                                      side: BorderSide(color: TColors.buttonPrimary, width: 2),
                                      padding: EdgeInsets.symmetric(vertical: 16.0),
                                      textStyle: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 250.0,
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          final shouldRefresh = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AddMissionForm(Date: _selectedDay),
                                            ),
                                          );
                                          if (shouldRefresh == true) {
                                            loadMissions(resetPagination: true);
                                          }
                                        },
                                        icon: Icon(Iconsax.add),
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(Iconsax.refresh),
                                          onPressed: () => loadMissions(resetPagination: true),
                                          tooltip: 'Refresh Missions',
                                        ),
                                      ],
                                    ),
                                    Center(
                                      child: Text(
                                        countMissionsByStatus(_allMissions)[1] == 0 &&
                                                countMissionsByStatus(_allMissions)[6]! > 0
                                            ? 'Tous les missions terminées ✔️'
                                            : 'Vous avez ${countMissionsByStatus(_allMissions)[1] ?? 0} mission Planifié',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? TColors.textWhite
                                              : TColors.dark,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
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
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                GroupedListView<Mission, String>(
                                  shrinkWrap: true,
                                  elements: _allMissions,
                                  groupBy: (Mission mission) =>
                                      mission.boutique?.libelle ?? 'No Boutique',
                                  groupSeparatorBuilder: (String boutiqueLibelle) {
                                    final sampleMission = _allMissions.firstWhere(
                                      (mission) =>
                                          mission.boutique?.libelle == boutiqueLibelle,
                                    );
                                    return Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          _showBoutiqueInfo(context, sampleMission.boutique!);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.store,
                                                color: isDarkMode ? Colors.white : Colors.black,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                boutiqueLibelle,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDarkMode ? Colors.white : Colors.black,
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
                                    final percentage = calculateAnsweredPercentage(mission);
                                    return GestureDetector(
                                      onTap: () async {
                                        final shouldRefresh = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MissionDetailsWidget(missionId: mission.id, mode: 1, status: mission.status!),
                                          ),
                                        );
                                        if (shouldRefresh == true) {
                                          loadMissions(resetPagination: true);
                                        }
                                      },
                                      onLongPress: () {
                                        _showModal(context, mission);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                        decoration: BoxDecoration(
                                          color: TColors.softGrey,
                                          border: Border(
                                            left: BorderSide(
                                              color: Color(int.parse(colors['primary']!.replaceFirst('0x', '0xff'))),
                                              width: 8.0,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(8.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                'Code: ${mission.missionCode ?? 'No Code'}',
                                                                style: TextStyle(
                                                                  color: Color(int.parse(colors['secondary']!.replaceFirst('0x', '0xff'))),
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                            Text(
                                                              '${statusData['status'] ?? 'Unknown'}',
                                                              style: TextStyle(
                                                                color: Color(int.parse(statusData['secondary']!.replaceFirst('0x', '0xff'))),
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Libelle: ${mission.libelle ?? 'No Libelle'}',
                                                          style: TextStyle(
                                                            color: Color(int.parse(colors['secondary']!.replaceFirst('0x', '0xff'))),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Description: ${mission.description ?? 'No Description'}',
                                                          style: TextStyle(
                                                            color: Color(int.parse(colors['secondary']!.replaceFirst('0x', '0xff'))),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: LinearProgressIndicator(
                                                      value: percentage / 100,
                                                      backgroundColor: Colors.grey[200],
                                                      color: Color(int.parse(colors['primary']!.replaceFirst('0x', '0xff'))),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    '${percentage.toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      color: Color(int.parse(colors['primary']!.replaceFirst('0x', '0xff'))),
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
                                SizedBox(height: 20),
                                if (_pagination != null && _pagination!.hasNextPage && _pagination!.nextPageNumber != null) ...[
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoadingMore ? null : loadMoreMissions,
                                      icon: _isLoadingMore
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Icon(Icons.keyboard_arrow_down),
                                      label: Text(
                                        _isLoadingMore ? 'Chargement...' : 'Charger plus de missions',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: TColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                ],
                                if (_pagination != null) ...[
                                  Center(
                                    child: Text(
                                      'Total: ${_pagination!.totalCount} missions',
                                      style: TextStyle(
                                        color: TColors.darkGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
