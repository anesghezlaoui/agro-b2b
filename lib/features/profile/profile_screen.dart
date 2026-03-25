import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Client: ${auth.name}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Téléphone: ${auth.phone}'),
          const SizedBox(height: 8),
          Text(
            auth.isValidatedByAdmin ? 'Compte validé' : 'Compte en attente de validation',
            style: TextStyle(
              color: auth.isValidatedByAdmin ? Colors.green : Colors.orange,
            ),
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.credit_score),
            title: Text('Crédit client'),
            subtitle: Text('Dette: 0 DA • Limite: 150 000 DA'),
          ),
          const ListTile(
            leading: Icon(Icons.local_offer),
            title: Text('Promotions'),
            subtitle: Text('Voir les produits en promo et déstockage'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
