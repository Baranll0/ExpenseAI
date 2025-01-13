import 'package:flutter/material.dart';
import 'package:project/src/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kullanıcı Bilgileri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user?.email?.substring(0, 1).toUpperCase() ?? 'K',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.email ?? 'Kullanıcı',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Uygulama Hakkında
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uygulama Hakkında',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bu uygulama, kişisel finans yönetiminizi kolaylaştırmak için tasarlanmıştır. '
                      'Gelir ve giderlerinizi takip edebilir, bütçe oluşturabilir ve finansal hedeflerinize ulaşmak için ilerlemenizi izleyebilirsiniz.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Özellikler',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      context,
                      icon: Icons.list,
                      title: 'Harcama Takibi',
                      description: 'Günlük harcamalarınızı kategorilere göre kaydedin ve takip edin.',
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.insert_chart,
                      title: 'Grafikler',
                      description: 'Harcama dağılımınızı görsel grafiklerle analiz edin.',
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.account_balance_wallet,
                      title: 'Bütçe Yönetimi',
                      description: 'Aylık bütçe belirleyin ve harcamalarınızı kontrol altında tutun.',
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.flag,
                      title: 'Hedef Takibi',
                      description: 'Finansal hedefler belirleyin ve ilerlemenizi takip edin.',
                    ),
                    _buildFeatureItem(
                      context,
                      icon: Icons.balance,
                      title: 'Gelir/Gider Dengesi',
                      description: 'Gelir ve giderlerinizi karşılaştırın, finansal dengenizi koruyun.',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nasıl Kullanılır?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildHowToItem(
                      context,
                      step: '1',
                      title: 'Harcama Ekleme',
                      description: 'Ana ekrandaki + butonuna tıklayarak yeni harcama ekleyin.',
                    ),
                    _buildHowToItem(
                      context,
                      step: '2',
                      title: 'Gelir Kaydetme',
                      description: 'Gelir/Gider ekranından gelirlerinizi kaydedin.',
                    ),
                    _buildHowToItem(
                      context,
                      step: '3',
                      title: 'Bütçe Belirleme',
                      description: 'Bütçe ekranından aylık harcama limitinizi belirleyin.',
                    ),
                    _buildHowToItem(
                      context,
                      step: '4',
                      title: 'Hedef Oluşturma',
                      description: 'Hedefler ekranından finansal hedeflerinizi belirleyin ve takip edin.',
                    ),
                    _buildHowToItem(
                      context,
                      step: '5',
                      title: 'Analiz',
                      description: 'Grafikler ekranından harcama analizlerinizi inceleyin.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Çıkış Yap Butonu
            ElevatedButton.icon(
              onPressed: () async {
                await authService.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToItem(
    BuildContext context, {
    required String step,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 