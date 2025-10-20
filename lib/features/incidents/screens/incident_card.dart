import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supervisormobile/features/calendar/models/Problem.dart';

class IncidentCard extends StatelessWidget {
  final Problem problem;
  final VoidCallback? onTap;

  const IncidentCard({Key? key, required this.problem, this.onTap}) : super(key: key);

  String? _getStatusLabel(int statusType, int statusNumber) {
    const statusTypeMap = {
      1: {1: 'Declared', 2: 'Solved'},
      2: {1: 'Declared', 2: 'Pending', 3: 'Solved'},
      3: {1: 'Pending', 2: 'Planned', 3: 'InProgress', 4: 'Finished', 5: 'Solved'},
    };
    return statusTypeMap[statusType]?[statusNumber];
  }

  Color _hexToColor(String hex) {
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.parse('0x$value'));
  }

  Map<String, Map<String, String>> get _statusColors => const {
        'Declared': {'background': '#f8d7da', 'color': '#721c24'},
        'Solved': {'background': '#d4edda', 'color': '#155724'},
        'Pending': {'background': '#fff3cd', 'color': '#856404'},
        'Planned': {'background': '#e2e3e5', 'color': '#383d41'},
        'InProgress': {'background': '#f5c6cb', 'color': '#721c24'},
        'Finished': {'background': '#f8d7da', 'color': '#721c24'},
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String formattedDate = problem.declaration_date != null
        ? DateFormat('yyyy-MM-dd').format(problem.declaration_date!)
        : l10n.noDateLower;

    final String? statusLabel =
        _getStatusLabel(problem.StatusType ?? 3, problem.Status ?? 5);
    final String statusText = l10n.statusLabel(statusLabel ?? 'N/A');

    final String priorityText = problem.coefficient?.libelle ?? l10n.noPriority;
    final String descriptionText = problem.description ?? l10n.noDescription;

    final String? hexBackground = _statusColors[statusLabel]?['background'];
    final Color borderColor = hexBackground != null
        ? _hexToColor(hexBackground)
        : Colors.grey;

    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
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
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        priorityText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    l10n.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    descriptionText,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    l10n.declarationDate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 8.0,
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
      ),
    );
  }
}

