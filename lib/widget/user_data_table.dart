import 'package:data_keeper/widget/user_table_cell.dart';
import 'package:data_keeper/widget/user_table_header.dart';
import 'package:flutter/material.dart';
import 'package:data_keeper/models/user_model.dart';

class UserDataTable extends StatelessWidget {
  final List<User> users;
  final ScrollController scrollController;
  final Function(User) onEdit;
  final Function(int) onDelete;

  const UserDataTable({
    super.key,
    required this.users,
    required this.scrollController,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: scrollController,
            child: DataTable(
              columns: const [
                DataColumn(label: UserTableHeader(text: 'ID', width: 60)),
                DataColumn(label: UserTableHeader(text: 'Name', width: 150)),
                DataColumn(label: UserTableHeader(text: 'Phone', width: 150)),
                DataColumn(label: UserTableHeader(text: 'City', width: 120)),
                DataColumn(
                    label: UserTableHeader(text: 'Postal Code', width: 120)),
                DataColumn(label: UserTableHeader(text: 'Street', width: 180)),
                DataColumn(label: UserTableHeader(text: 'Actions', width: 120)),
              ],
              rows: users.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final user = entry.value;
                return DataRow(
                  cells: [
                    DataCell(UserTableCell(text: index.toString(), width: 60)),
                    DataCell(UserTableCell(text: user.name, width: 150)),
                    DataCell(UserTableCell(text: user.phone, width: 150)),
                    DataCell(UserTableCell(text: user.city, width: 120)),
                    DataCell(UserTableCell(text: user.postalCode, width: 120)),
                    DataCell(UserTableCell(text: user.street, width: 180)),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon:
                                  Icon(Icons.edit, color: Colors.blue.shade600),
                              onPressed: () => onEdit(user),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red.shade600),
                              onPressed: () => onDelete(user.id!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
              headingRowHeight: 56,
              dataRowHeight: 56,
              horizontalMargin: 0,
              columnSpacing: 0,
              border: TableBorder.all(color: Colors.grey.shade600, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
