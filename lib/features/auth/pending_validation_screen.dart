import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/support_contact.dart';
import 'auth_provider.dart';

/// Écran affiché tant que le compte n’est pas validé par l’équipe AgroB2B.
class PendingValidationScreen extends StatefulWidget {
  const PendingValidationScreen({super.key});

  @override
  State<PendingValidationScreen> createState() =>
      _PendingValidationScreenState();
}

class _PendingValidationScreenState extends State<PendingValidationScreen> {
  bool _refreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    final auth = context.read<AuthProvider>();
    final validated = await auth.refreshSession();
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (!validated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Compte toujours en attente, ou connexion indisponible. Réessayez plus tard.',
          ),
        ),
      );
    }
  }

  Future<void> _openUri(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Impossible d’ouvrir le lien sur cet appareil.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Validation du compte'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshing ? null : _onRefresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () async {
              await auth.logout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenue chez AgroB2B 🎉',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Votre compte est en cours de validation.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '🚀 Vous êtes à quelques instants d’accéder à une nouvelle façon de travailler',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _Bullet(text: 'Plus de déplacements inutiles', theme: theme),
              _Bullet(
                  text: 'Des prix compétitifs de distributeur', theme: theme),
              _Bullet(
                text: 'Gagner en efficacité dans votre commerce',
                theme: theme,
              ),
              _Bullet(
                text: 'Simplifier votre approvisionnement au quotidien',
                theme: theme,
              ),
              _Bullet(
                text: 'Des commandes en quelques secondes',
                theme: theme,
              ),
              const SizedBox(height: 28),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                      theme.colorScheme.tertiary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    '💼 💡 Notre mission est simple :\nvous faire gagner du temps, de l’effort et augmenter votre rentabilité.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Validation en cours…',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.02,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '⏱️ Temps estimé : quelques heures',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (auth.name.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Compte : ${auth.name} · ${auth.phone}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _openUri(SupportContact.whatsappUri),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('WhatsApp — nous écrire'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openUri(SupportContact.phoneUri),
                icon: const Icon(Icons.phone_rounded),
                label: const Text('Appeler — +213 550 30 54 71'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.theme});

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
