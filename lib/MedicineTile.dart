import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MedicineTile extends StatelessWidget {
  final Medicine medicine;

  const MedicineTile({
    Key? key,
    required this.medicine,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');
    final nextDoseTime = medicine.getNextDoseTime();
    final status = medicine.getStatus();

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case MedicineStatus.due:
        statusColor = theme.colorScheme.tertiary;
        statusIcon = Icons.notifications_active;
        break;
      case MedicineStatus.overdue:
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case MedicineStatus.upcoming:
      default:
        statusColor = theme.colorScheme.secondary;
        statusIcon = Icons.schedule;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to medicine details
          Navigator.pushNamed(
            context,
            '/medicine-details',
            arguments: medicine.id,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Medication icon or image
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: statusColor,
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 16),

                  // Medicine name and dosage
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontSize: 20,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${medicine.dosage} ${medicine.dosageUnit}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  // Status icon
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ],
              ),

              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 8),

              // Time and buttons
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: theme.colorScheme.onPrimary.withOpacity(0.7),
                  ),
                  SizedBox(width: 8),
                  Text(
                    timeFormat.format(nextDoseTime),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),

                  // Mark as taken button
                  _buildTakeButton(context, theme, statusColor),
                ],
              ),

              // Show refill reminder if needed
              if (medicine.isDueForRefill())
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                        color: theme.colorScheme.secondary.withOpacity(0.8),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Refill needed soon',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
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

  Widget _buildTakeButton(BuildContext context, ThemeData theme, Color statusColor) {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);

    return ElevatedButton.icon(
      onPressed: () {
        _showTakenConfirmation(context);
      },
      icon: Icon(Icons.check, size: 20),
      label: Text('Take'),
      style: ElevatedButton.styleFrom(
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showTakenConfirmation(BuildContext context) {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Taken?'),
        content: Text('Did you take ${medicine.dosage} ${medicine.dosageUnit} of ${medicine.name}?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              medicineProvider.markAsTaken(medicine.id);
              Navigator.of(context).pop();

              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${medicine.name} marked as taken'),
                  duration: Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      medicineProvider.undoMarkAsTaken(medicine.id);
                    },
                  ),
                ),
              );
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }
}