import 'dart:io';
import 'package:data_keeper/widget/custom_fab.dart';
import 'package:data_keeper/widget/top_snackbar.dart';
import 'package:data_keeper/widget/user_data_table.dart';
import 'package:data_keeper/widget/user_empty_state.dart';
import 'package:data_keeper/widget/user_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:data_keeper/database/database_helper.dart';
import 'package:data_keeper/models/user_model.dart';
import 'package:data_keeper/screens/db_file_upload_screen.dart';
import 'package:data_keeper/screens/user_form_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> users = [];
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final ScrollController _horizontalScrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final loadedUsers = await dbHelper.getUsers();
      setState(() {
        users = loadedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showTopSnackBar(
        context: context,
        message: 'Error loading users: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _refreshUsers() async {
    await _loadUsers();
  }

  void _navigateToUserForm(User? user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          user: user,
          isEditMode: user != null,
        ),
      ),
    );

    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _exportDatabase() async {
    try {
      final exportedPath = await dbHelper.exportDatabase();
      if (exportedPath != null) {
        if (!mounted) return;
        showTopSnackBar(
          context: context,
          message: 'Database exported to Downloads',
          isError: false,
          onDismiss: () => _openFile(exportedPath),
        );
      } else {
        if (!mounted) return;
        showTopSnackBar(
          context: context,
          message: 'Failed to export database',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        context: context,
        message: 'Database export error: ${e.toString()}',
        isError: true,
        durationSeconds: 5,
      );
    }
  }

  Future<void> _openFile(String path) async {
    try {
      await OpenFile.open(path);
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        context: context,
        message: 'Could not open file: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Users Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                children: [
                  pw.TableRow(
                    children: [
                      _buildPdfCell('No.', isHeader: true),
                      _buildPdfCell('Name', isHeader: true),
                      _buildPdfCell('Phone', isHeader: true),
                      _buildPdfCell('City', isHeader: true),
                      _buildPdfCell('Postal Code', isHeader: true),
                      _buildPdfCell('Street', isHeader: true),
                    ],
                  ),
                  ...users.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final user = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildPdfCell(index.toString()),
                        _buildPdfCell(user.name),
                        _buildPdfCell(user.phone),
                        _buildPdfCell(user.city),
                        _buildPdfCell(user.postalCode),
                        _buildPdfCell(user.street),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Generated on: ${DateTime.now().toString()}',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/users_report.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      if (!mounted) return;
      showTopSnackBar(
        context: context,
        message: 'PDF exported successfully',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        context: context,
        message: 'Failed to export PDF: ${e.toString()}',
        isError: true,
      );
    }
  }

  pw.Widget _buildPdfCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      child: pw.Text(
        text,
        style: isHeader
            ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
            : const pw.TextStyle(),
      ),
    );
  }

  Future<void> _deleteUser(int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await dbHelper.deleteUser(id);
              _loadUsers();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActions(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Users Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      centerTitle: true,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: _refreshUsers,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          UserStatsCard(userCount: users.length),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? UserEmptyState(
                        onAddUser: () => _navigateToUserForm(null),
                      )
                    : UserDataTable(
                        users: users,
                        scrollController: _horizontalScrollController,
                        onEdit: (user) => _navigateToUserForm(user),
                        onDelete: (id) => _deleteUser(id),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CustomFAB(
          icon: Icons.picture_as_pdf,
          backgroundColor: Colors.red.shade600,
          onPressed: _exportToPDF,
          heroTag: 'pdf',
        ),
        const SizedBox(height: 10),
        CustomFAB(
          icon: Icons.save_alt,
          backgroundColor: Colors.green.shade600,
          onPressed: _exportDatabase,
          heroTag: 'export',
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.blue,
      elevation: 1,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
        BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Import'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            _navigateToUserForm(null);
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ImportDbScreen()),
            );
            break;
        }
      },
    );
  }
}
