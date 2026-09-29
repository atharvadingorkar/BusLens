import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ManageOperatorsScreen extends StatefulWidget {
  const ManageOperatorsScreen({super.key});

  @override
  State<ManageOperatorsScreen> createState() =>
      _ManageOperatorsScreenState();
}

class _ManageOperatorsScreenState
    extends State<ManageOperatorsScreen> {
  List<dynamic> operators = [];

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadOperators();
  }

  // Load operators from the backend
  Future<void> loadOperators() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await ApiService.getOperators();

      if (!mounted) return;

      setState(() {
        operators = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to load operators';
      });
    }
  }

  // Create operator account dialog
  Future<void> showCreateOperatorDialog() async {
    final formKey = GlobalKey<FormState>();

    final adminEmailController = TextEditingController();
    final adminPasswordController = TextEditingController();

    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    bool isCreating = false;
    bool obscureAdminPassword = true;
    bool obscureOperatorPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Operator Account'),

              content: SingleChildScrollView(
                child: Form(
                  key: formKey,

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Admin Verification',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: adminEmailController,
                        keyboardType:
                        TextInputType.emailAddress,

                        decoration: const InputDecoration(
                          labelText: 'Admin Email',
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Enter Admin email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: adminPasswordController,
                        obscureText: obscureAdminPassword,

                        decoration: InputDecoration(
                          labelText: 'Admin Password',
                          border: const OutlineInputBorder(),

                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureAdminPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),

                            onPressed: () {
                              setDialogState(() {
                                obscureAdminPassword =
                                !obscureAdminPassword;
                              });
                            },
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter Admin password';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Operator Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: fullNameController,

                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Enter full name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: emailController,
                        keyboardType:
                        TextInputType.emailAddress,

                        decoration: const InputDecoration(
                          labelText: 'Operator Email',
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Enter operator email';
                          }

                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,

                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),

                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Enter phone number';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: passwordController,
                        obscureText: obscureOperatorPassword,

                        decoration: InputDecoration(
                          labelText: 'Operator Password',
                          border: const OutlineInputBorder(),

                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureOperatorPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),

                            onPressed: () {
                              setDialogState(() {
                                obscureOperatorPassword =
                                !obscureOperatorPassword;
                              });
                            },
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter operator password';
                          }

                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [

                TextButton(
                  onPressed: isCreating
                      ? null
                      : () {
                    Navigator.pop(dialogContext);
                  },

                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    setDialogState(() {
                      isCreating = true;
                    });

                    try {
                      final result =
                      await ApiService.createOperator(
                        adminEmail:
                        adminEmailController.text.trim(),

                        adminPassword:
                        adminPasswordController.text,

                        fullName:
                        fullNameController.text.trim(),

                        email:
                        emailController.text.trim(),

                        phone:
                        phoneController.text.trim(),

                        password:
                        passwordController.text,
                      );

                      if (!mounted) return;

                      if (result['success'] == true) {
                        Navigator.pop(dialogContext);

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Operator account created successfully',
                            ),
                          ),
                        );

                        await loadOperators();
                      } else {
                        setDialogState(() {
                          isCreating = false;
                        });

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ??
                                  'Failed to create operator',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      setDialogState(() {
                        isCreating = false;
                      });

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unable to create operator account',
                          ),
                        ),
                      );
                    }
                  },

                  child: isCreating
                      ? const SizedBox(
                    height: 20,
                    width: 20,

                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    // Controller disposal intentionally omitted here.
    // This avoids disposing the controllers while
    // Flutter is still completing the dialog lifecycle.
  }

  // Open status change dialog
  Future<void> showStatusDialog(
      Map<String, dynamic> operator,
      ) async {
    final int userId = operator['user_id'];

    final String fullName =
        operator['full_name'] ?? 'Unknown Operator';

    final String currentStatus =
    (operator['status'] ?? 'active')
        .toString()
        .toLowerCase();

    final String newStatus =
    currentStatus == 'active' ? 'inactive' : 'active';

    final bool? confirmChange = await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('Change Operator Status'),

          content: Text(
            'Do you want to change $fullName from '
                '${currentStatus.toUpperCase()} to '
                '${newStatus.toUpperCase()}?',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              child: Text(
                newStatus == 'active'
                    ? 'Activate'
                    : 'Deactivate',
              ),
            ),
          ],
        );
      },
    );

    if (confirmChange != true) {
      return;
    }

    await updateOperatorStatus(
      userId: userId,
      status: newStatus,
    );
  }

  // Update operator status using the backend
  Future<void> updateOperatorStatus({
    required int userId,
    required String status,
  }) async {
    try {
      final result = await ApiService.updateOperatorStatus(
        userId: userId,
        status: status,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Operator status changed to '
                  '${status.toUpperCase()}',
            ),
          ),
        );

        await loadOperators();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Failed to update operator status',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to update operator status',
          ),
        ),
      );
    }
  }

  // Build operator card
  Widget buildOperatorCard(
      Map<String, dynamic> operator,
      ) {
    final String fullName =
        operator['full_name'] ?? 'Unknown Operator';

    final String email =
        operator['email'] ?? 'No email available';

    final String phone =
        operator['phone'] ?? 'No phone available';

    final String role =
        operator['role'] ?? 'operator';

    final String status =
    (operator['status'] ?? 'active')
        .toString()
        .toLowerCase();

    final bool isActive = status == 'active';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        onTap: () {
          showStatusDialog(operator);
        },

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              CircleAvatar(
                radius: 25,

                backgroundColor: isActive
                    ? Colors.green.shade100
                    : Colors.red.shade100,

                child: Icon(
                  Icons.person,

                  color: isActive
                      ? Colors.green.shade700
                      : Colors.red.shade700,

                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(
                      fullName,

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Email: $email',

                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Phone: $phone',

                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Role: ${role.toUpperCase()}',

                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),

                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.shade100
                                : Colors.red.shade100,

                            borderRadius:
                            BorderRadius.circular(20),
                          ),

                          child: Text(
                            status.toUpperCase(),

                            style: TextStyle(
                              color: isActive
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,

                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          'Tap to change',

                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Operators'),

        actions: [

          // Create Operator button
          IconButton(
            onPressed: showCreateOperatorDialog,

            icon: const Icon(Icons.add),

            tooltip: 'Create Operator',
          ),

          // Refresh button
          IconButton(
            onPressed: loadOperators,

            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.error_outline,
              size: 50,
            ),

            const SizedBox(height: 15),

            Text(errorMessage),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadOperators,

              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : operators.isEmpty
          ? const Center(
        child: Text('No operators found'),
      )
          : RefreshIndicator(
        onRefresh: loadOperators,

        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
          ),

          itemCount: operators.length,

          itemBuilder: (context, index) {
            final operator =
            Map<String, dynamic>.from(
              operators[index],
            );

            return buildOperatorCard(
              operator,
            );
          },
        ),
      ),
    );
  }
}