/// Show Post Page (Car Details)
/// Displays comprehensive information about a single car listing
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/providers.dart';
import '../../../core/router/route_names.dart';
import '../../../data/providers/car_details_provider.dart';
import '../../../data/providers/saved_cars_provider.dart';
import '../../../data/models/car_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat_room_data.dart';
import '../../widgets/specific/seller_info_card.dart';

class ShowPostPage extends ConsumerStatefulWidget {
  final String carId;

  const ShowPostPage({super.key, required this.carId});

  @override
  ConsumerState<ShowPostPage> createState() => _ShowPostPageState();
}

class _ShowPostPageState extends ConsumerState<ShowPostPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Fetch car details when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(carDetailsProvider.notifier).fetchCarDetails(widget.carId);
      ref.read(carRepositoryProvider).incrementView(widget.carId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(carDetailsProvider);
    final savedCarsState = ref.watch(savedCarsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      body: _buildBody(state, savedCarsState),
      bottomNavigationBar: state.car != null && !state.car!.isOwner
          ? _buildBottomActionBar(state.car!)
          : null,
    );
  }

  Widget _buildBody(CarDetailsState state, SavedCarsState savedCarsState) {
    // Loading state
    if (state.isLoading && state.car == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (state.error != null && state.car == null) {
      return _buildErrorState(state.error!);
    }

    // No data
    if (state.car == null) {
      return const Center(child: Text('Car not found'));
    }

    final car = state.car!;
    final isSaved = savedCarsState.isCarSaved(car.id);

    return CustomScrollView(
      slivers: [
        // Custom App Bar with image carousel
        _buildSliverAppBar(car, isSaved),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Share
                _buildTitleRow(car),

                // Price
                _buildPriceSection(car),
                const SizedBox(height: 5),

                // Seller Information Card
                if (car.seller != null)
                  SellerInfoCard(
                    sellerName: car.seller!.name,
                    sellerProfilePhotoUrl: car.seller!.profilePhoto,
                  ),
                const SizedBox(height: 10),

                // Description
                _buildDescriptionSection(car),
                const SizedBox(height: 20),

                // Specs Cards (Mileage, Fuel Type)
                _buildSpecsCards(car),
                const SizedBox(height: 10),

                // Additional Details Grid
                _buildDetailsGrid(car),
                const SizedBox(height: 20),

                // Views and Posted Date
                _buildMetaInfo(car),

                // Extra padding for bottom bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Sliver App Bar with Image Carousel
  Widget _buildSliverAppBar(CarModel car, bool isSaved) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        // Favorite button
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? AppColors.lightPrimary : Colors.white,
            ),
          ),
          onPressed: () async {
            await ref
                .read(savedCarsProvider.notifier)
                .toggleSave(car.id, car: car);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSaved ? 'Removed from saved' : 'Added to saved',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(background: _buildImageCarousel(car)),
    );
  }

  // Image Carousel
  Widget _buildImageCarousel(CarModel car) {
    final images = car.images.isNotEmpty
        ? car.images
        : ['https://via.placeholder.com/400x300?text=No+Image'];

    return Stack(
      children: [
        // Image PageView
        PageView.builder(
          controller: _pageController,
          itemCount: images.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 64),
                );
              },
            );
          },
        ),

        // Dots Indicator
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? AppColors.lightPrimary
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

        // Image counter badge
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // Title Row with Share Button
  Widget _buildTitleRow(CarModel car) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  car.title,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  car.make,
                  style: TextStyle(color: AppColors.white, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          iconSize: 20,
          onPressed: () => _shareCarDetails(car),
        ),
      ],
    );
  }

  // Price Section
  Widget _buildPriceSection(CarModel car) {
    final priceFormat = NumberFormat('#,###');
    return Text(
      '₩ ${priceFormat.format(car.price)}',
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 20,
        color: Theme.of(context).appBarTheme.foregroundColor,
      ),
    );
  }

  // Specs Cards (Mileage, Fuel Type)
  Widget _buildSpecsCards(CarModel car) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specifications:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSpecCard(
                icon: Icons.speed_outlined,
                label: 'Mileage',
                value: '${NumberFormat('#,###').format(car.mileage)} km',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSpecCard(
                icon: Icons.local_gas_station_outlined,
                label: 'Fuel Type',
                value: _capitalize(car.fuelType),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 22,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  // Additional Details Grid
  Widget _buildDetailsGrid(CarModel car) {
    final details = <Map<String, dynamic>>[
      {
        'icon': Icons.calendar_today,
        'label': 'Year',
        'value': car.year.toString(),
      },
      if (car.condition.isNotEmpty)
        {
          'icon': Icons.star,
          'label': 'Condition',
          'value': _capitalize(car.condition),
        },
      if (car.transmission.isNotEmpty)
        {
          'icon': Icons.settings,
          'label': 'Transmission',
          'value': _capitalize(car.transmission),
        },
      if (car.color.isNotEmpty)
        {
          'icon': Icons.palette,
          'label': 'Color',
          'value': _capitalize(car.color),
        },
      if (car.vin.isNotEmpty)
        {'icon': Icons.confirmation_number, 'label': 'VIN', 'value': car.vin},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: details.map((detail) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                detail['icon'] as IconData,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '${detail['label']}: ${detail['value']}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Description Section
  Widget _buildDescriptionSection(CarModel car) {
    if (car.description.isEmpty) return const SizedBox.shrink();

    const maxLines = 4;
    final isLong = car.description.length > 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        Text(
          'Description:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${car.description}Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
          maxLines: _isDescriptionExpanded ? null : maxLines,
          overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[700], height: 1.5),
        ),
        if (isLong)
          TextButton(
            onPressed: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Text(
              _isDescriptionExpanded ? 'Show less' : 'Read more',
              style: const TextStyle(color: AppColors.lightPrimary),
            ),
          ),
      ],
    );
  }

  // Location Section
  Widget _buildLocationSection(CarModel car) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '${car.city}${car.state.isNotEmpty ? ', ${car.state}' : ''}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Meta Info (Views, Posted Date)
  Widget _buildMetaInfo(CarModel car) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Row(
      children: [
        Icon(Icons.visibility, color: Colors.grey[400], size: 16),
        const SizedBox(width: 4),
        Text(
          '${car.viewsCount} views',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(width: 16),
        Icon(Icons.access_time, color: Colors.grey[400], size: 16),
        const SizedBox(width: 4),
        Text(
          dateFormat.format(car.createdAt),
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(width: 16),
        Icon(Icons.location_on, color: Colors.grey[400], size: 16),
        const SizedBox(width: 4),
        Text(
          '${car.city}${car.state.isNotEmpty ? ', ${car.state}' : ''}',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Bottom Action Bar
  Widget _buildBottomActionBar(CarModel car) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Chat Button
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleChatButtonPressed(car),
              ),
            ),
            // Call Button (Show only if not chat-only)
            if (!car.chatOnly) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone_outlined),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lightPrimary,
                    side: const BorderSide(color: AppColors.lightPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: car.seller?.phone != null
                      ? () => _makePhoneCall(car.seller!.phone!)
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Handle Chat Button Press
  Future<void> _handleChatButtonPressed(CarModel car) async {
    // Check authentication
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      // Navigate to login if not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to chat with the seller')),
      );
      context.push(RouteNames.login);
      return;
    }

    if (car.seller == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seller information not available')),
        );
      }
      return;
    }

    // Create ChatRoomData for lazy conversation creation
    // Conversation will be created when user sends first message
    final chatRoomData = ChatRoomData.pending(
      sellerId: car.seller!.id,
      sellerName: car.seller!.name,
      sellerAvatar: car.seller!.profilePhoto,
      carId: car.id,
      carTitle: car.title,
      carImageUrl: car.images.firstOrNull,
      carPrice: car.price.toDouble(),
    );

    // Navigate to chat room with pending conversation
    if (mounted) {
      context.push('/chat/new', extra: chatRoomData);
    }
  }

  // Error State
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load car details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () {
                ref
                    .read(carDetailsProvider.notifier)
                    .fetchCarDetails(widget.carId);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Share car details
  void _shareCarDetails(CarModel car) {
    final priceFormat = NumberFormat('#,###');
    final shareText =
        '''
Check out this ${car.title}!

Price: \$${priceFormat.format(car.price)}
Year: ${car.year}
Mileage: ${NumberFormat('#,###').format(car.mileage)} km
Location: ${car.city}${car.state.isNotEmpty ? ', ${car.state}' : ''}

${car.description.isNotEmpty ? car.description : ''}
''';

    Share.share(shareText, subject: car.title);
  }

  // Helper: Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  // Helper: Capitalize string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
