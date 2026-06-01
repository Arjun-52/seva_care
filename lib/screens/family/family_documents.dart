import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../models/mock_data.dart';

class FamilyDocuments extends StatefulWidget {
  const FamilyDocuments({super.key});

  @override
  State<FamilyDocuments> createState() => _FamilyDocumentsState();
}

class _FamilyDocumentsState extends State<FamilyDocuments> {
  String _category = 'All';
  final _categories = ['All', 'Medical Reports', 'Prescriptions', 'Identity', 'Insurance', 'Treatment Plans', 'Reports'];
  final _searchController = TextEditingController();

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Medical Reports': return Icons.description;
      case 'Prescriptions': return Icons.medication;
      case 'Identity': return Icons.badge;
      case 'Insurance': return Icons.health_and_safety;
      case 'Treatment Plans': return Icons.assignment;
      case 'Reports': return Icons.assessment;
      default: return Icons.folder;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Medical Reports': return SevaColors.primary;
      case 'Prescriptions': return SevaColors.purple;
      case 'Identity': return SevaColors.teal;
      case 'Insurance': return SevaColors.green;
      case 'Treatment Plans': return SevaColors.orange;
      case 'Reports': return SevaColors.amber;
      default: return SevaColors.textSecondary;
    }
  }

  List<SevaDocument> get _filteredDocs {
    var docs = MockData.documents;
    if (_category != 'All') {
      docs = docs.where((d) => d.category == _category).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      docs = docs.where((d) => d.name.toLowerCase().contains(query) || d.category.toLowerCase().contains(query)).toList();
    }
    return docs;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Document Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Upload feature coming soon'),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            // AES notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: SevaColors.greenLight, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SevaColors.green.withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.lock, size: 16, color: SevaColors.green),
                const SizedBox(width: 8),
                Expanded(child: Text('All documents are secured with AES-256 encryption and DPDP Act compliant.',
                  style: GoogleFonts.inter(fontSize: 12, color: SevaColors.green))),
              ]),
            ),
            const SizedBox(height: 12),

            // Search
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: const Icon(Icons.search, size: 20, color: SevaColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    })
                  : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
          ]),
        ),

        // Categories
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final active = _category == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? SevaColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: active ? null : Border.all(color: SevaColors.border),
                    ),
                    child: Text(cat, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : SevaColors.textSecondary)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Documents list
        Expanded(
          child: _filteredDocs.isEmpty
            ? const EmptyState(icon: Icons.folder_off, title: 'No documents found', subtitle: 'Try a different search or category')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredDocs.length,
                itemBuilder: (_, i) {
                  final doc = _filteredDocs[i];
                  final color = _categoryColor(doc.category);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SevaCard(
                      onTap: () {
                        _showDocumentPreview(context, doc);
                      },
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(_categoryIcon(doc.category), size: 22, color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(doc.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: SevaColors.textPrimary)),
                          const SizedBox(height: 2),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(doc.category, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                            ),
                            const SizedBox(width: 8),
                            Text(doc.size, style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                          ]),
                          const SizedBox(height: 2),
                          Text('By ${doc.uploadedBy} | ${_formatDate(doc.uploadDate)}',
                            style: GoogleFonts.inter(fontSize: 11, color: SevaColors.textTertiary)),
                        ])),
                        const Icon(Icons.chevron_right, color: SevaColors.textTertiary, size: 20),
                      ]),
                    ),
                  );
                },
              ),
        ),
      ]),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showDocumentPreview(BuildContext context, SevaDocument doc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: SevaColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: _categoryColor(doc.category).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(_categoryIcon(doc.category), size: 28, color: _categoryColor(doc.category)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doc.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(doc.category, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 20),
          _detailRow('Uploaded by', doc.uploadedBy),
          _detailRow('Date', _formatDate(doc.uploadDate)),
          _detailRow('Size', doc.size),
          _detailRow('Encryption', 'AES-256'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Download started...'), behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.green,
                ));
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Share link copied!'), behavior: SnackBarBehavior.floating, backgroundColor: SevaColors.primary,
                ));
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            )),
          ]),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: SevaColors.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textPrimary)),
      ]),
    );
  }
}
