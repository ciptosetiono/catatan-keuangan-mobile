import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final WalletService _walletService = WalletService();

  void _openWalletForm({Wallet? wallet}) {
    final TextEditingController _controller = TextEditingController(
      text: wallet?.name ?? '',
    );
    final isEdit = wallet != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(isEdit ? 'Edit Wallet' : 'Add Wallet'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Wallet Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(
                  255,
                  65,
                  64,
                  64,
                ), // Set your desired color here
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _controller.text.trim();
                if (name.isEmpty) return;

                final userId = FirebaseAuth.instance.currentUser!.uid;
                final newWallet = Wallet(
                  id: wallet?.id ?? '',
                  name: name,
                  userId: userId,
                );

                if (isEdit) {
                  await _walletService.updateWallet(newWallet);
                } else {
                  await _walletService.addWallet(newWallet);
                }

                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteWallet(Wallet wallet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Wallet'),
            content: Text('Are you sure to delete wallet "${wallet.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromARGB(
                    255,
                    65,
                    64,
                    64,
                  ), // Set your desired color here
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Set your desired color here
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _walletService.deleteWallet(wallet.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: StreamBuilder<List<Wallet>>(
        stream: _walletService.getWalletStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = snapshot.data ?? [];
          if (accounts.isEmpty) {
            return const Center(
              child: Text('THre are no wallets yet. Add one now!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: accounts.length,
            itemBuilder: (ctx, i) {
              final a = accounts[i];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(a.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openWalletForm(wallet: a),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _deleteWallet(a),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openWalletForm(),
        child: const Icon(Icons.add),
        backgroundColor: Colors.lightBlue, // Set your desired color here
        foregroundColor: Colors.white, // Set icon color
      ),
    );
  }
}
