import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';

class AddEditMedicineScreen extends StatefulWidget {
  final bool isEditing;
  final String? medicineId;

  const AddEditMedicineScreen({
    Key? key,
    this.isEditing = false,
    this.medicineId,
  }) : super(key: key);

  @override
  _AddEditMedicineScreenState createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  String _dosageUnit = 'pill(s)';
  DateTime _startDate = DateTime.now();
  DateTime? _refillDate;
  DateTime? _expiryDate;
  int _intervalHours = 24;
  List<DateTime> _scheduledTimes = [];
  bool _isActive = true;

  Medicine? _originalMedicine;
  bool _isLoading = false;

  final List<String> _dosageUnits = [
    'pill(s)',
    'ml',
    'mg',
    'g',
    'unit(s)',
    'drop(s)',
    'tablet(s)',
    'capsule(s)',
    'injection(s)',
    'spray(s)',
    'teaspoon(s)',
    'tablespoon(s)',
  ];

  final List<int> _commonIntervals = [
    4, 6, 8, 12, 24, 48
  ];

  @override
  void initState() {
    super.initState();

    // Set default scheduled time for once-a-day medication
    final now = DateTime.now();
    _scheduledTimes = [
      DateTime(now.year, now.month, now.day, 8, 0), // 8:00 AM
    ];

    // Load medicine data if editing
    if (widget.isEditing && widget.medicineId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMedicineData();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadMedicineData() async {
    setState(() {
      _isLoading = true;
    });

    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    final medicine = medicineProvider.getMedicineById(widget.medicineId!);

    if (medicine != null) {
      _originalMedicine = medicine;

      _nameController.text = medicine.name;
      _dosageController.text = medicine.dosage.toString();
      _dosageUnit = medicine.dosageUnit;
      _startDate = medicine.startDate;
      _refillDate = medicine.refillDate;
      _expiryDate = medicine.expiryDate;
      _intervalHours = medicine.intervalHours;
      _scheduledTimes = List.from(medicine.scheduledTimes);
      _isActive = medicine.isActive;
      _notesController.text = medicine.notes;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);

    try {
      final medicine = Medicine(
        id: widget.isEditing ? _originalMedicine!.id : const Uuid().v4(),
        name: _nameController.text.trim(),
        dosage: double.parse(_dosageController.text),
        dosageUnit: _dosageUnit,
        startDate: _startDate,
        refillDate: _refillDate,
        expiryDate: _expiryDate,
        intervalHours: _intervalHours,
        scheduledTimes: _scheduledTimes,
        takenTimes: widget.isEditing ? _originalMedicine!.takenTimes : [],
        notes: _notesController.text.trim(),
        isActive: _isActive,
      );

      if (widget.isEditing) {
        await medicineProvider.updateMedicine(medicine);
      } else {
        await medicineProvider.addMedicine(medicine);
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.isEditing
                  ? '${medicine.name} updated successfully'
                  : '${medicine.name} added successfully'
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving medicine: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, DateType dateType) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
      dateType == DateType.start ? _startDate :
      dateType == DateType.refill ? (_refillDate ?? DateTime.now()) :
      (_expiryDate ?? DateTime.now().add(Duration(days: 30))),
      firstDate: dateType == DateType.start ? DateTime.now().subtract(Duration(days: 365)) : DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.secondary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (dateType) {
          case DateType.start:
            _startDate = picked;
            break;
          case DateType.refill:
            _refillDate = picked;
            break;
          case DateType.expiry:
            _expiryDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    TimeOfDay initialTime = TimeOfDay.fromDateTime(_scheduledTimes[index]);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.secondary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _scheduledTimes[index] = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _addScheduledTime() {
    setState(() {
      // Add a new time 1 hour after the last one or at 8 AM if this is the first
      final DateTime newTime = _scheduledTimes.isNotEmpty
          ? _scheduledTimes.last.add(Duration(hours: 1))
          : DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 0);

      _scheduledTimes.add(newTime);
    });
  }

  void _removeScheduledTime(int index) {
    setState(() {
      if (_scheduledTimes.length > 1) {
        _scheduledTimes.removeAt(index);
      }
    });
  }

  void _updateIntervalBasedOnScheduledTimes() {
    if (_scheduledTimes.length >= 2) {
      // Sort times chronologically
      _scheduledTimes.sort((a, b) => a.compareTo(b));

      // Calculate average interval
      int totalMinutes = 0;
      for (int i = 0; i < _scheduledTimes.length - 1; i++) {
        totalMinutes += _scheduledTimes[i + 1].difference(_scheduledTimes[i]).inMinutes;
      }

      // Add the wrap-around time from last to first (next day)
      final firstTimeNextDay = _scheduledTimes.first.add(Duration(days: 1));
      totalMinutes += firstTimeNextDay.difference(_scheduledTimes.last).inMinutes;

      // Calculate average interval in hours
      final avgIntervalHours = (totalMinutes / _scheduledTimes.length) / 60;

      // Find the closest standard interval
      _intervalHours = _commonIntervals.reduce((prev, curr) {
        return (avgIntervalHours - prev).abs() < (avgIntervalHours - curr).abs()
            ? prev
            : curr;
      });
    } else {
      // Default to 24 hours if only one time
      _intervalHours = 24;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Medicine?'),
        content: Text('Are you sure you want to delete ${_nameController.text}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
              await medicineProvider.deleteMedicine(widget.medicineId!);

              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to previous screen

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_nameController.text} deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MM/dd/yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Medicine' : 'Add New Medicine'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation(context);
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Text(
                'Basic Information',
                style: theme.textTheme.displayMedium,
              ),
              SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Medicine Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a medicine name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Dosage
              Row(
                children: [
                  // Dosage amount
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        labelText: 'Dosage *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),

                  // Dosage unit
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _dosageUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: _dosageUnits.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _dosageUnit = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Important Dates
              Text(
                'Important Dates',
                style: theme.textTheme.displayMedium,
              ),
              SizedBox(height: 16),

              // Start Date
              ListTile(
                title: Text('Start Date'),
                subtitle: Text(dateFormat.format(_startDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, DateType.start),
                tileColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                ),
              ),
              SizedBox(height: 12),

              // Refill Date
              ListTile(
                title: Text('Refill Date (Optional)'),
                subtitle: _refillDate == null
                    ? Text('Not set')
                    : Text(dateFormat.format(_refillDate!)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_refillDate != null)
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _refillDate = null;
                          });
                        },
                      ),
                    Icon(Icons.calendar_today),
                  ],
                ),
                onTap: () => _selectDate(context, DateType.refill),
                tileColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                ),
              ),
              SizedBox(height: 12),

              // Expiry Date
              ListTile(
                title: Text('Expiry Date (Optional)'),
                subtitle: _expiryDate == null
                    ? Text('Not set')
                    : Text(dateFormat.format(_expiryDate!)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expiryDate != null)
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _expiryDate = null;
                          });
                        },
                      ),
                    Icon(Icons.calendar_today),
                  ],
                ),
                onTap: () => _selectDate(context, DateType.expiry),
                tileColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                ),
              ),
              SizedBox(height: 24),

              // Schedule
              Text(
                'Scheduled Times',
                style: theme.textTheme.displayMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Set times when you need to take this medicine',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 16),

              // Scheduled times
              ...List.generate(_scheduledTimes.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text('Time ${index + 1}'),
                    subtitle: Text(timeFormat.format(_scheduledTimes[index])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_scheduledTimes.length > 1)
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeScheduledTime(index),
                          ),
                        Icon(Icons.access_time),
                      ],
                    ),
                    onTap: () => _selectTime(context, index),
                    tileColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                    ),
                  ),
                );
              }),

              // Add another time button
              Center(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add Another Time'),
                  onPressed: _addScheduledTime,
                ),
              ),
              SizedBox(height: 24),

              // Interval
              Text(
                'Interval',
                style: theme.textTheme.displayMedium,
              ),
              SizedBox(height: 8),
              Text(
                'How often should this medicine be taken?',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 16),

              // Interval selection
              DropdownButtonFormField<int>(
                value: _intervalHours,
                decoration: InputDecoration(
                  labelText: 'Interval',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                items: _commonIntervals.map((hours) {
                  String label = 'Every $hours hour';
                  if (hours > 1) label += 's';
                  if (hours == 24) label = 'Once daily';
                  if (hours == 12) label = 'Twice daily';
                  if (hours == 8) label = 'Three times daily';
                  if (hours == 6) label = 'Four times daily';

                  return DropdownMenuItem<int>(
                    value: hours,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _intervalHours = value!;
                  });
                },
              ),
              SizedBox(height: 24),

              // Notes
              Text(
                'Additional Notes',
                style: theme.textTheme.displayMedium,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Take with food, etc.',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),

              // Active status
              SwitchListTile(
                title: Text('Active'),
                subtitle: Text('Receive reminders for this medicine'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                tileColor: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                ),
              ),
              SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    widget.isEditing ? 'Update Medicine' : 'Add Medicine',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DateType { start, refill, expiry }