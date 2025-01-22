import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../api_service.dart';

class AddEditReviewScreen extends StatefulWidget {
  final String username;
  final Map<String, dynamic>? review;

  const AddEditReviewScreen({Key? key, required this.username, this.review}) : super(key: key);

  @override
  _AddEditReviewScreenState createState() => _AddEditReviewScreenState();
}

class _AddEditReviewScreenState extends State<AddEditReviewScreen> {
  final _titleController = TextEditingController();
  final _ratingController = TextEditingController();
  final _commentController = TextEditingController();
  final _apiService = ApiService();
  File? _selectedImage;
  final _picker = ImagePicker();
  String? _existingImageUrl;
  @override
  void initState() {
    super.initState();
    if (widget.review != null) {
      _titleController.text = widget.review!['title'];
      _ratingController.text = widget.review!['rating'].toString();
      _commentController.text = widget.review!['comment'];
      _existingImageUrl = widget.review!['imageUrl']; 
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _saveReview() async {
    final title = _titleController.text.trim();
    final rating = int.tryParse(_ratingController.text.trim()) ?? 0;
    final comment = _commentController.text.trim();

    // Validasi input
    if (title.isEmpty || rating < 1 || rating > 10 || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data tidak valid. Judul, komentar, dan rating (1-10) harus diisi.')),
      );
      return;
    }

    bool success;
    if (widget.review == null) {

      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap pilih gambar untuk ulasan baru.')),
        );
        return;
      }
      success = await _apiService.addReview(widget.username, title, rating, comment, _selectedImage!);
    } else {
      if (_selectedImage != null) {
        success = await _apiService.updateReviewWithImage(widget.review!['_id'], widget.username, title, rating, comment, _selectedImage!);
      } else {
        success = await _apiService.updateReview(widget.review!['_id'], widget.username, title, rating, comment, _existingImageUrl!);
      }
    }

    if (success) {
      Navigator.pop(context, true); // Berhasil, kembali ke layar sebelumnya
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan ulasan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.review == null ? 'Tambah Ulasan' : 'Edit Ulasan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextField(
                controller: _ratingController,
                decoration: const InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(labelText: 'Komentar'),
              ),
              const SizedBox(height: 10),
              _selectedImage != null
                  ? Image.file(_selectedImage!, height: 150)
                  : _existingImageUrl != null
                      ? Image.network(_existingImageUrl!, height: 150, fit: BoxFit.cover)
                      : const Text('Tidak ada gambar yang dipilih.'),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pilih Gambar'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveReview,
                child: Text(widget.review == null ? 'Tambah Ulasan' : 'Update Ulasan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}