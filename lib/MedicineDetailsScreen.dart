import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';

class MedicineDetailsScreen extends StatelessWidget {
  const MedicineDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final medicineId = ModalRoute.of(context)!.settings.arguments as String;
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    final medicine = medicineProvider.getMedicineById(medicineId);
    final theme = Theme.of(context);

    if (medicine == null) {
      // Handle case where medicine is not found
      return Scaffold(
        appBar: AppBar(title: Text('Medicine Details')),
        body: Center(
          child: Text('Medicine not found', style: theme.textTheme.displayMedium),
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-medicine',
                arguments: medicineId,
              );
            },
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            // Get the latest medicine data in case it was updated
            final updatedMedicine = provider.getMedicineById(medicineId);
            if (updatedMedicine == null) {
              return Center(child: Text('Medicine not found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine header with icon
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.medication,
                          color: theme.colorScheme.tertiary,
                          size: 36,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              updatedMedicine.name,
                              style: theme.textTheme.displayLarge,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${updatedMedicine.dosage} ${updatedMedicine.dosageUnit}',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Active Status
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: updatedMedicine.isActive
                          ? theme.colorScheme.secondary.withOpacity(0.1)
                          : theme.colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          updatedMedicine.isActive ? Icons.notifications_active : Icons.notifications_off,
                          color: updatedMedicine.isActive ? theme.colorScheme.secondary : theme.colorScheme.error,
                        ),
                        SizedBox(width: 12),
                        Text(
                          updatedMedicine.isActive ? 'Reminders Active' : 'Reminders Disabled',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: updatedMedicine.isActive ? theme.colorScheme.secondary : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Next dose section
                  _buildSectionHeader(context, 'Next Dose'),
                  SizedBox(height: 8),
                  _buildInfoTile(
                    context,
                    'Scheduled at',
                    timeFormat.format(updatedMedicine.getNextDoseTime()),
                    Icons.access_time,
                  ),
                  SizedBox(height: 24),

                  // Schedule section
                  _buildSectionHeader(context, 'Schedule'),
                  SizedBox(height: 8),

                  // Interval
                  _buildInfoTile(
                    context,
                    'Interval',
                    _getIntervalText(updatedMedicine.intervalHours),
                    Icons.timer,
                  ),
                  SizedBox(height: 12),

                  // Daily times
                  _buildInfoTile(
                    context,
                    'Daily Times',
                    updatedMedicine.scheduledTimes.map((time) => timeFormat.format(time)).join(', '),
                    Icons.schedule,
                  ),
                  SizedBox(height: 24),

                  // Important dates
                  _buildSectionHeader(context, 'Important Dates'),
                  SizedBox(height: 8),

                  // Start date
                  _buildInfoTile(
                    context,
                    'Start Date',
                    dateFormat.format(updatedMedicine.startDate),
                    Icons.calendar_today,
                  ),
                  SizedBox(height: 12),

                  // Refill date (if set)
                  if (updatedMedicine.refillDate != null)
                    Column(
                      children: [
                        _buildInfoTile(
                          context,
                          'Refill Date',
                          dateFormat.format(updatedMedicine.refillDate!),
                          Icons.shopping_bag,
                          updatedMedicine.isDueForRefill() ? theme.colorScheme.secondary : null,
                        ),
                        SizedBox(height: 12),
                      ],
                    ),

                  // Expiry date (if set)
                  if (updatedMedicine.expiryDate != null)
                    Column(
                      children: [
                        _buildInfoTile(
                          context,
                          'Expiry Date',
                          dateFormat.format(updatedMedicine.expiryDate!),
                          Icons.event_busy,
                          _isExpiringSoon(updatedMedicine) ? theme.colorScheme.error : null,
                        ),
                        SizedBox(height: 12),
                      ],
                    ),

                  // Notes (if any)
                  if (updatedMedicine.notes.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12),
                        _buildSectionHeader(context, 'Notes'),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                          ),
                          child: Text(
                            updatedMedicine.notes,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 24),

                  // Recent history section
                  _buildSectionHeader(context, 'Recent History'),
                  SizedBox(height: 8),

                  if (updatedMedicine.takenTimes.isNotEmpty)
                    Column(
                      children: [
                        ...updatedMedicine.takenTimes
                            .reversed
                            .take(5)
                            .map((time) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildInfoTile(
                            context,
                            'Taken',
                            '${dateFormat.format(time)} at ${timeFormat.format(time)}',
                            Icons.check_circle,
                            theme.colorScheme.secondary,
                          ),
                        ))
                            .toList(),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                      ),
                      child: Text(
                        'No history yet',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  SizedBox(height: 32),

                  // Take medication button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check),
                      label: Text('Take Medication Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.tertiary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        _showTakenConfirmation(context, updatedMedicine);
                      },
                    ),
                  ),
                ],
              ),
            );
          }
      ),
    );
  }

  String _getIntervalText(int hours) {
    switch (hours) {
      case 24: return 'Once daily';
      case 12: return 'Twice daily';
      case 8: return 'Three times daily';
      case 6: return 'Four times daily';
      case 4: return 'Six times daily';
      default: return 'Every $hours hours';
    }
  }

  bool _isExpiringSoon(Medicine medicine) {
    if (medicine.expiryDate == null) return false;
    final now = DateTime.now();
    final difference = medicine.expiryDate!.difference(now).inDays;
    return difference <= 30; // Consider expiring soon if within 30 days
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.displayMedium,
    );
  }

  Widget _buildInfoTile(
      BuildContext context,
      String label,
      String value,
      IconData icon, [
        Color? iconColor,
      ]) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? theme.colorScheme.onPrimary.withOpacity(0.7),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTakenConfirmation(BuildContext context, Medicine medicine) {
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