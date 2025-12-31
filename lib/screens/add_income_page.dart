import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

final supabase = Supabase.instance.client;

class AddIncomePage extends ConsumerStatefulWidget {
  const AddIncomePage({super.key});

  @override
  ConsumerState<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends ConsumerState<AddIncomePage> {
  final Color primaryColor = const Color(0xFF2F8F8B);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _category;
  bool _loading = false;

  final List<String> fixedCategories = [
    "Salary",
    "Business",
    "Bonus",
    "Investment",
    "Others"
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  /// ---------- ADD INCOME ----------
  Future<void> _addIncome() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final dateText = _dateController.text.trim();
    final category = _category;

    if (name.isEmpty || amount == null || dateText.isEmpty || category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final newTransaction = TransactionModel(
        id: const Uuid().v4(),
        title: name,
        amount: amount,
        date: DateTime.parse(dateText),
        category: category,
        userId: supabase.auth.currentUser!.id,
        isIncome: true,
      );

      await supabase.from('income').insert(newTransaction.toJson());

      // ✅ Riverpod: refresh the transaction list
      ref.read(transactionProvider.notifier).refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Income Added Successfully")),
      );

      context.pop(newTransaction); // Return the model
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Add Income",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [
          Icon(Icons.more_horiz),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildLabel("NAME"),
                    buildTextField(_nameController),
                    const SizedBox(height: 20),

                    buildLabel("AMOUNT"),
                    buildAmountField(),
                    const SizedBox(height: 20),

                    buildLabel("DATE"),
                    buildDateField(),
                    const SizedBox(height: 20),

                    buildLabel("CATEGORY"),
                    buildCategoryButton(),
                    const SizedBox(height: 30),

                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addIncome,
                        child: const Text("Add Income"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ---------- WIDGETS ----------
  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        prefixText: "\$ ",
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.teal),
        ),
      ),
    );
  }

  Widget buildDateField() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        suffixIcon: const Icon(Icons.calendar_today_outlined),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          _dateController.text = pickedDate.toIso8601String();
        }
      },
    );
  }

  Widget buildCategoryButton() {
    return GestureDetector(
      onTap: () async {
        final selected = await showDialog<String>(
          context: context,
          builder: (_) => SimpleDialog(
            title: const Text("Select Category"),
            children: fixedCategories
                .map((c) => SimpleDialogOption(
              onPressed: () => Navigator.pop(context, c),
              child: Text(c),
            ))
                .toList(),
          ),
        );
        if (selected != null) setState(() => _category = selected);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              _category ?? "Add Category",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
