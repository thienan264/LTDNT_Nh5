import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/rental_repository.dart';
import '../../../data/models/rental_model.dart';
import 'rental_detail_screen.dart';
import 'rental_form_screen.dart';

class RentalListScreen extends StatefulWidget {
  const RentalListScreen({super.key});

  @override
  State<RentalListScreen> createState() => _RentalListScreenState();
}

class _RentalListScreenState extends State<RentalListScreen> {
  late Future<List<RentalModel>> _rentalsFuture;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  void _loadRentals() {
    setState(() {
      _rentalsFuture = RentalRepository.getRentals();
    });
  }

  Color _getStatusColor(RentalStatus status, bool isOverdue) {
    if (isOverdue) return AppColors.statusBroken;
    switch (status) {
      case RentalStatus.active:
        return AppColors.statusAvailable;
      case RentalStatus.approved:
      case RentalStatus.pending:
        return AppColors.statusRented;
      case RentalStatus.overdue:
        return AppColors.statusBroken;
      case RentalStatus.returned:
        return const Color(0xFF64748B);
      case RentalStatus.cancelled:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hợp đồng & Đơn cho thuê'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadRentals,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const RentalFormScreen()),
          );
          if (created == true) {
            _loadRentals();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tạo hợp đồng'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'ALL'),
                _buildFilterChip('Đang hiệu lực', 'ACTIVE'),
                _buildFilterChip('⚠️ Quá hạn', 'OVERDUE', isAlert: true),
                _buildFilterChip('Đã hoàn tất', 'RETURNED'),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<RentalModel>>(
              future: _rentalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var rentals = snapshot.data ?? [];
                if (_selectedFilter == 'ACTIVE') {
                  rentals = rentals
                      .where(
                        (r) => r.status == RentalStatus.active && !r.isOverdue,
                      )
                      .toList();
                } else if (_selectedFilter == 'OVERDUE') {
                  rentals = rentals.where((r) => r.isOverdue).toList();
                } else if (_selectedFilter == 'RETURNED') {
                  rentals = rentals
                      .where((r) => r.status == RentalStatus.returned)
                      .toList();
                }

                if (rentals.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không tìm thấy hợp đồng phù hợp',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    final statusColor = _getStatusColor(
                      rental.status,
                      rental.isOverdue,
                    );

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: rental.isOverdue
                              ? Colors.red.shade300
                              : AppColors.border,
                          width: rental.isOverdue ? 1.5 : 1.0,
                        ),
                      ),
                      color: rental.isOverdue
                          ? const Color(0xFFFEF2F2)
                          : Colors.white,
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RentalDetailScreen(rental: rental),
                            ),
                          );
                          _loadRentals();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        rental.contractCode,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (rental.isOverdue) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Quá hạn ${rental.daysOverdue} ngày',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ] else if (rental.isDueSoon) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Sắp hết hạn',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      rental.isOverdue
                                          ? 'Quá hạn'
                                          : rental.status.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                rental.unitName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      rental.unitAddress,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 18),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Thời hạn: ${dateFormatter.format(rental.startDate)} - ${dateFormatter.format(rental.expectedEndDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: rental.isOverdue
                                          ? Colors.red.shade700
                                          : AppColors.textSecondary,
                                      fontWeight: rental.isOverdue
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    'Cọc: ${currencyFormatter.format(rental.totalDeposit)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (rental.estimatedTotalCost > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Tiền thuê ước tính: ${currencyFormatter.format(rental.estimatedTotalCost)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0D9488),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: rental.isOverdue
                                      ? Colors.white
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                  border: rental.isOverdue
                                      ? Border.all(color: Colors.red.shade100)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Thiết bị: ${rental.deviceNames.join(', ')}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, {bool isAlert = false}) {
    final isSelected = _selectedFilter == value;
    final activeColor = isAlert ? Colors.red : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: activeColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : (isAlert ? Colors.red.shade700 : AppColors.textSecondary),
          fontWeight: (isSelected || isAlert)
              ? FontWeight.bold
              : FontWeight.normal,
          fontSize: 13,
        ),
        backgroundColor: isAlert ? Colors.red.shade50 : Colors.white,
        side: BorderSide(
          color: isSelected
              ? activeColor
              : (isAlert ? Colors.red.shade200 : AppColors.border),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
