import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../models/professional_model.dart';
import '../../models/shop_model.dart';
import '../../widgets/chat/gradient_search_input.dart';
import '../../widgets/chat/chat_message_widget.dart';
import '../../widgets/chat/category_grid.dart';
import '../../widgets/common/menu_drawer.dart';
import '../../widgets/shop/shop_card.dart';
import '../messages/inbox_screen.dart';
import '../services/professional_detail_screen.dart';
import '../auth/login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  String _activeTab = 'Services';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final dataProvider = context.read<DataProvider>();
    await dataProvider.loadCategories();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final query = _inputController.text.trim();
    if (query.isEmpty) return;

    final dataProvider = context.read<DataProvider>();

    _inputController.clear();

    // Switch to Services tab if on Shops tab
    if (_activeTab == 'Shops') {
      setState(() => _activeTab = 'Services');
    }

    // AI Chat works without login! 
    await dataProvider.sendAIMessage(
      message: query,
      userId: null, // No user ID needed for basic search
      city: AppConfig.defaultCity,
    );

    // Scroll to bottom after message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleVoiceInput() {
    _inputController.text =
        'Looking for private teacher / lawyer / electrician / grocers shop near me';
  }

  void _navigateToProfessionalDetail(ProfessionalModel professional) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessionalDetailScreen(professional: professional),
      ),
    );
  }

  void _navigateToShopDetail(ShopModel shop) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${shop.name}.. .')),
    );
  }

  // Check if user is logged in before accessing protected features
  void _requireAuth({required VoidCallback onAuthenticated}) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isLoggedIn) {
      onAuthenticated();
    } else {
      // Show login screen
      _showLoginPrompt();
    }
  }

  void _showLoginPrompt() {
    showModalBottomSheet(
      context:  context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius. vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize. min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.inputBorderGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.login,
                color: AppColors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Sign in Required',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Please sign in to access this feature, unlock contacts, and send messages.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height:  24),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child:  ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleMessagesTab() {
    _requireAuth(
      onAuthenticated: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InboxScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: const MenuDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Tab Pills
            _buildTabPills(),

            // Search Input
            GradientSearchInput(
              controller: _inputController,
              onSubmitted: (_) => _handleSend(),
              onVoiceTap: _handleVoiceInput,
            ),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = context.watch<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical:  12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:  [
          // Menu Button
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Iconsax.menu,
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),

          // Logo
          Text(
            AppConfig.appName,
            style: AppTextStyles.logoSmall,
          ),

          // User Avatar or Sign In Button
          GestureDetector(
            onTap: () {
              if (authProvider.isLoggedIn) {
                _scaffoldKey.currentState?.openDrawer();
              } else {
                _showLoginPrompt();
              }
            },
            child: Container(
              width: 40,
              height:  40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: authProvider.isLoggedIn
                  ? ClipRRect(
                      borderRadius:  BorderRadius.circular(10),
                      child: authProvider.user?.avatarUrl != null
                          ?  Image.network(
                              authProvider.user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildUserIcon(authProvider),
                            )
                          :  _buildUserIcon(authProvider),
                    )
                  :  const Icon(
                      Iconsax.user,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserIcon(AuthProvider authProvider) {
    return Center(
      child: Text(
        authProvider.user?.name.isNotEmpty == true
            ?  authProvider.user! .name[0].toUpperCase()
            : 'U',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTabPills() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: AppConfig.mainTabs.map((tab) {
          final isActive = _activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (tab == 'Messages') {
                  _handleMessagesTab(); // Requires auth
                } else {
                  setState(() => _activeTab = tab);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds:  200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration:  BoxDecoration(
                  color: isActive ?  AppColors.white : AppColors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isActive
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  tab,
                  style:  TextStyle(
                    color: isActive ? AppColors.textDark : AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_activeTab == 'Shops') {
      return _buildShopsTab();
    }

    return Consumer<DataProvider>(
      builder:  (context, dataProvider, _) {
        final messages = dataProvider.chatMessages;

        if (messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical:  8),
          itemCount: messages. length + (dataProvider.aiTyping ?  1 : 0),
          itemBuilder: (context, index) {
            // Show typing indicator
            if (index == messages.length && dataProvider. aiTyping) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Searching...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              );
            }

            final message = messages[index];
            return ChatMessageWidget(
              message:  message,
              onProfessionalTap: _navigateToProfessionalDetail,
              onShopTap: _navigateToShopDetail,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Hint text
          Center(
            child: Column(
              children: [
                Text(
                  'Ask for any service you need.. .',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try:  "I need an electrician" or "Find me a tutor"',
                  style:  TextStyle(
                    fontSize:  14,
                    color:  AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height:  40),

          // Categories
          const Text(
            'Browse Categories',
            Text('Browse Categories', style: AppTextStyles.h3,)
          ),
          const SizedBox(height: 16),

          Consumer<DataProvider>(
            builder:  (context, dataProvider, _) {
              return CategoryGrid(
                categories: dataProvider.categories,
                onCategoryTap: (category) {
                  _inputController.text = 'Find me a ${category.name. toLowerCase()}';
                  _handleSend();
                },
              );
            },
          ),

          const SizedBox(height:  32),

          // Quick suggestions
          const Text(
            'Popular Searches',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height:  16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Electrician near me'),
              _buildSuggestionChip('Plumber available today'),
              _buildSuggestionChip('Home cleaning service'),
              _buildSuggestionChip('AC repair'),
              _buildSuggestionChip('Private tutor'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _inputController.text = text;
        _handleSend();
      },
      child:  Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildShopsTab() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, _) {
        return SingleChildScrollView(
          padding:  const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Browse Shops',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 8),
              Text(
                'Find local shops and businesses',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              CategoryGrid(
                categories: dataProvider.categories,
                showAsShops: true,
                onCategoryTap: (category) {
                  _inputController.text = 'Show me ${category.name.toLowerCase()} shops';
                  setState(() => _activeTab = 'Services');
                  _handleSend();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}