import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mytank/models/user_model.dart';
import 'package:mytank/services/user_service.dart';
import 'package:mytank/utilities/route_manager.dart';
import 'package:mytank/utilities/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:mytank/providers/auth_provider.dart';
import 'package:mytank/providers/update_data_provider.dart';

// Helper method to replace deprecated withOpacity
Color withValues(Color color, double opacity) =>
    Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), opacity);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  User? _user;
  bool _isLoading = true;
  String _errorMessage = '';

  final String _bio =
      'Passionate about water conservation and efficient water management. '
      'Committed to sustainable water usage practices and monitoring water consumption patterns.';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Add a small delay to show the shimmer effect (for demonstration purposes)
      // In production, you might want to remove this delay
      await Future.delayed(const Duration(seconds: 2));

      final user = await UserService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load user data: \$e';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) return;
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) return;
      }
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));

        // Upload the image to Cloudinary
        _uploadImageToCloudinary();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_selectedImage == null) return;

    final updateDataProvider = Provider.of<UpdateDataProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      // Log image details
      debugPrint('📸 Selected image path: ${_selectedImage!.path}');
      debugPrint('📸 Selected image exists: ${await _selectedImage!.exists()}');
      debugPrint(
        '📸 Selected image size: ${await _selectedImage!.length()} bytes',
      );

      final success = await updateDataProvider.uploadAvatar(
        _selectedImage!,
        authProvider,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh user data to show the updated avatar
        _fetchUserData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updateDataProvider.errorMessage ??
                  'Failed to update profile picture',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error in profile screen while uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: withValues(Constants.greyColor, 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Change Profile Picture',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Constants.blackColor,
                    ),
                  ),
                ),
                Divider(color: withValues(Constants.greyColor, 0.2)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: withValues(Constants.accentColor, 0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Constants.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            'Take Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Constants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: withValues(Constants.accentColor, 0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.photo_library_rounded,
                              color: Constants.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            'Choose from Gallery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Constants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.pushNamed(context, RouteManager.updateDataRoute),
        backgroundColor: Constants.primaryColor,
        elevation: 4,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: Constants.primaryColor,
              elevation: innerBoxIsScrolled ? 4 : 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: withValues(Colors.white, 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: withValues(Colors.white, 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // Navigate to settings when implemented
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: null, // Remove default title
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E3A8A), // Deeper blue
                        Constants.primaryColor,
                        Constants.secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          // Custom positioned title
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: withValues(Colors.white, 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Smart Tank',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                collapseMode: CollapseMode.parallax,
              ),
            ),
          ];
        },
        body:
            _isLoading
                ? _buildLoadingContent()
                : _errorMessage.isNotEmpty
                ? _buildErrorContent()
                : _buildMainContent(),
      ),
    );
  }

  // New improved shimmer implementation
  Widget _buildLoadingContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildShimmerProfileHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildShimmerInfoCard(),
                const SizedBox(height: 20),
                _buildShimmerBioCard(),
                const SizedBox(height: 20),
                _buildShimmerStatsCard(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildShimmerActionButton()),
                    const SizedBox(width: 15),
                    Expanded(child: _buildShimmerActionButton()),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer base widget to avoid code duplication
  Widget _buildShimmerBase({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }

  // Shimmer container for consistent styling
  Widget _buildShimmerContainer({
    required double width,
    required double height,
    double borderRadius = 8,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius:
            shape == BoxShape.rectangle
                ? BorderRadius.circular(borderRadius)
                : null,
      ),
    );
  }

  Widget _buildShimmerProfileHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: withValues(Constants.primaryColor, 0.06),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 30,
            bottom: 30,
            right: 40,
            left: 40,
          ),
          child: _buildShimmerBase(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShimmerContainer(
                  width: 130,
                  height: 130,
                  shape: BoxShape.circle,
                ),
                const SizedBox(height: 20),
                _buildShimmerContainer(
                  width: 150,
                  height: 24,
                  borderRadius: 12,
                ),
                const SizedBox(height: 8),
                _buildShimmerContainer(
                  width: 200,
                  height: 30,
                  borderRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerInfoCard() {
    return _buildShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildShimmerBase(
                child: _buildShimmerContainer(
                  width: 46,
                  height: 46,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(width: 15),
              _buildShimmerBase(
                child: _buildShimmerContainer(
                  width: 150,
                  height: 20,
                  borderRadius: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShimmerInfoRow(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _buildShimmerInfoRow(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _buildShimmerInfoRow(),
        ],
      ),
    );
  }

  Widget _buildShimmerBioCard() {
    return _buildShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildShimmerBase(
                child: _buildShimmerContainer(
                  width: 46,
                  height: 46,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(width: 15),
              _buildShimmerBase(
                child: _buildShimmerContainer(
                  width: 100,
                  height: 20,
                  borderRadius: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShimmerBase(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildShimmerContainer(
                  width: double.infinity,
                  height: 12,
                  borderRadius: 6,
                ),
                const SizedBox(height: 8),
                _buildShimmerContainer(
                  width: double.infinity,
                  height: 12,
                  borderRadius: 6,
                ),
                const SizedBox(height: 8),
                _buildShimmerContainer(width: 200, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerStatsCard() {
    return _buildShimmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildShimmerBase(
                child: _buildShimmerContainer(
                  width: 46,
                  height: 46,
                  borderRadius: 14,
                ),
              ),
              const SizedBox(width: 15),
              _buildShimmerBase(
                child: _buildShimmerContainer(
                  width: 150,
                  height: 20,
                  borderRadius: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShimmerStatRow(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _buildShimmerStatRow(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _buildShimmerStatRow(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          _buildShimmerStatRow(),
        ],
      ),
    );
  }

  Widget _buildShimmerInfoRow() {
    return _buildShimmerBase(
      child: Row(
        children: [
          _buildShimmerContainer(width: 24, height: 24, shape: BoxShape.circle),
          const SizedBox(width: 10),
          _buildShimmerContainer(width: 200, height: 16, borderRadius: 8),
        ],
      ),
    );
  }

  Widget _buildShimmerStatRow() {
    return _buildShimmerBase(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildShimmerContainer(width: 100, height: 16, borderRadius: 8),
            _buildShimmerContainer(width: 50, height: 16, borderRadius: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerActionButton() {
    return _buildShimmerBase(
      child: _buildShimmerContainer(
        width: double.infinity,
        height: 60,
        borderRadius: 16,
      ),
    );
  }

  Widget _buildShimmerCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: withValues(Constants.greyColor, 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(22), child: child),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Constants.warningColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Profile',
            style: TextStyle(
              color: Constants.blackColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Constants.greyColor, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildProfileHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildInfoCard(),
                const SizedBox(height: 20),
                _buildBioCard(),
                const SizedBox(height: 20),
                _buildStatsCard(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.history_rounded,
                        label: 'Usage History',
                        color: Constants.warningColor,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.water_drop_rounded,
                        label: 'My Tanks',
                        color: Constants.primaryColor,
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              RouteManager.tanksRoute,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: withValues(Constants.primaryColor, 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Add some space at the top for better visual balance
          const SizedBox(height: 12),

          // Profile image with camera icon
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: withValues(Constants.accentColor, 0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  // Profile image
                  CircleAvatar(
                    radius: 70, // Slightly larger avatar
                    backgroundColor: Constants.accentColor.withAlpha(60),
                    backgroundImage:
                        _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : _user?.avatarUrl != null &&
                                _user!.avatarUrl.isNotEmpty
                            ? NetworkImage(_user!.avatarUrl)
                            : null,
                    child:
                        (_selectedImage == null &&
                                (_user?.avatarUrl == null ||
                                    _user!.avatarUrl.isEmpty))
                            ? Text(
                              _user?.name.isNotEmpty == true
                                  ? _user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                            : null,
                  ),

                  // Camera icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: withValues(Constants.primaryColor, 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Name with increased spacing
          const SizedBox(height: 24),
          Text(
            _user?.name ?? 'User',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28, // Slightly larger font
              fontWeight: FontWeight.bold,
              color: Constants.blackColor,
              letterSpacing: 0.5,
            ),
          ),

          // Role badge with improved spacing
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: withValues(Constants.accentColor, 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: withValues(Constants.accentColor, 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Water Conservation Specialist',
              style: TextStyle(
                fontSize: 14,
                color: Constants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard() => _buildCard(
    titleIcon: Icons.info_outline_rounded,
    title: 'About Me',
    child: Text(
      _bio,
      style: TextStyle(
        fontSize: 15,
        color: withValues(Constants.blackColor, .7),
        height: 1.5,
      ),
    ),
  );

  Widget _buildStatsCard() => _buildCard(
    titleIcon: Icons.bar_chart_rounded,
    title: 'Account Statistics',
    child: Column(
      children: [
        _buildStatRow('Total Tanks', '${_user?.tanks.length ?? 0}'),
        Divider(color: Colors.grey.withAlpha(100)),
        _buildStatRow('Total Bills', '${_user?.bills.length ?? 0}'),
        Divider(color: Colors.grey.withAlpha(100)),
        _buildStatRow(
          'Identity Number',
          _user?.identityNumber ?? 'Not available',
        ),
        Divider(color: Colors.grey.withAlpha(100)),
        _buildStatRow('Account Status', 'Active'),
      ],
    ),
  );

  Widget _buildCard({
    required IconData titleIcon,
    required String title,
    required Widget child,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: withValues(Constants.primaryColor, 0.06),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: withValues(Constants.accentColor, 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(titleIcon, color: Constants.primaryColor, size: 22),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Constants.blackColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );

  Widget _buildInfoCard() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: withValues(Constants.primaryColor, 0.06),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: withValues(Constants.accentColor, 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: Constants.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 15),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Constants.blackColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            Icons.email_rounded,
            _user?.email ?? 'Email not available',
          ),
          Divider(color: withValues(Constants.greyColor, 0.15), height: 24),
          _buildInfoRow(
            Icons.phone_rounded,
            _user?.phone ?? 'Phone not available',
          ),
          Divider(color: withValues(Constants.greyColor, 0.15), height: 24),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            _user?.getFormattedJoinDate() ?? 'Join date not available',
          ),
        ],
      ),
    ),
  );

  Widget _buildInfoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: withValues(Constants.accentColor, 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Constants.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Constants.blackColor,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildStatRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Constants.greyColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: withValues(Constants.accentColor, 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Constants.primaryColor,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: withValues(Constants.primaryColor, 0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: withValues(color, 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Constants.blackColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
