import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  AnalysisResult? _result;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _scanFood() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: kIsWeb ? ImageSource.gallery : ImageSource.camera);

      if (image != null) {
        AnalysisResult res;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          res = await ApiService.analyzeFood('', fileBytes: bytes, fileName: image.name);
        } else {
          res = await ApiService.analyzeFood(image.path);
        }
        
        // Log it to Firebase
        if (mounted) {
          await context.read<FirebaseService>().logFood(res);
        }

        setState(() { _result = res; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Widget _buildResultCard() {
    if (_result == null) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _result != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(_result!.foodName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
             const SizedBox(height: 10),
             Text(_result!.verdict, style: const TextStyle(fontSize: 16, color: Colors.white70)),
             const SizedBox(height: 20),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _stat('Cal', '${_result!.calories}'),
                 _stat('Pro', '${_result!.protein}g'),
                 _stat('Carb', '${_result!.carbs}g'),
                 _stat('Fat', '${_result!.fats}g'),
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NutriLens', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          if (_isLoading)
            Center(
              child: RotationTransition(
                turns: _animationController,
                child: Icon(Icons.change_circle_outlined, size: 80, color: Theme.of(context).primaryColor),
              ),
            )
          else
            Center(
              child: GestureDetector(
                onTap: _scanFood,
                child: Container(
                  height: 180, width: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 40)]
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 50, color: Colors.white),
                      SizedBox(height: 10),
                      Text('LOG MEAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 40),
          _buildResultCard(),
          const Spacer(),
        ],
      ),
    );
  }
}
