import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../models/medicine.dart';
import '../utils/constants.dart';
import '../widgets/medicine_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/doserly_logo.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            Text('Doserly'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month),
            onPressed: () {
              // Navigate to calendar view
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, medicineProvider, child) {
          final todaysMedicines = medicineProvider.getTodaysMedicines();

          if (todaysMedicines.isEmpty) {
            return _buildEmptyState(context);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Today's Date and Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Today - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: theme.textTheme.displayMedium,
                  ),
                ),

                // Upcoming Medications Section
                _buildMedicineSection(
                  context,
                  'Upcoming Doses',
                  medicineProvider.getUpcomingMedicines(),
                  Icons.access_time,
                  theme.colorScheme.secondary,
                ),

                // Overdue Medications Section
                _buildMedicineSection(
                  context,
                  'Overdue',
                  medicineProvider.getOverdueMedicines(),
                  Icons.error_outline,
                  theme.colorScheme.error.withOpacity(0.8),
                ),

                // Taken Medications Section
                _buildMedicineSection(
                  context,
                  'Taken Today',
                  medicineProvider.getTakenMedicines(),
                  Icons.check_circle_outline,
                  theme.colorScheme.secondary.withOpacity(0.5),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add-medicine');
        },
        backgroundColor: theme.colorScheme.tertiary,
        foregroundColor: Colors.white,
        elevation: 4,
        label: Text('Add Medicine'),
        icon: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: theme.colorScheme.tertiary,
        unselectedItemColor: theme.colorScheme.onPrimary.withOpacity(0.6),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineSection(
      BuildContext context,
      String title,
      List<Medicine> medicines,
      IconData icon,
      Color iconColor,
      ) {
    if (medicines.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
        ...medicines.map((medicine) => MedicineTile(medicine: medicine)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No medications scheduled',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first medication',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/add-medicine');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Add Medicine'),
            ),
          ),
        ],
      ),
    );
  }
}