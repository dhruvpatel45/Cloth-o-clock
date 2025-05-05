import 'package:flutter/material.dart';
import 'package:hello/seller/home_page.dart';
import 'package:hello/seller/uploadproducts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:hello/settings/theme_notifier.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AddProducts extends StatefulWidget {
  final List<File> selectedImages;

  AddProducts({required this.selectedImages});

  @override
  _AddProductsState createState() => _AddProductsState();
}

class _AddProductsState extends State<AddProducts> {
  final ImagePicker _picker = ImagePicker();
  List<File> _resizedImages = [];
  int _quantity = 1;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  List<String> sizes = ["-","XS", "S", "M", "L", "XL", "2XL", "3XL"];
  String? selectedSize;

  List<String> categories = [
    "Casual Wear",
    "Formal Wear",
    "Party Wear",
    "Wedding Wear",
    "Sports Wear",
    "Others"
  ];
  String? selectedCategory;

  List<String> genders = ["Male", "Female", "Other"];
  String? selectedGender;

  String? selectedOption;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _resizedImages = widget.selectedImages;
    _pageController.addListener(() {
      setState(() {
        _currentPageIndex = _pageController.page!.toInt();
      });
    });
    _upiController.text = "Upload UPI image to detect ID";
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<File?> _resizeImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      final img.Image resized = img.copyResize(image, width: 300);
      final directory = await getTemporaryDirectory();
      final resizedFilePath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final resizedFile = File(resizedFilePath);
      await resizedFile.writeAsBytes(img.encodeJpg(resized));

      return resizedFile;
    } catch (e) {
      print("❌ Error in resizing image: $e");
      return null;
    }
  }

  Future<void> _pickUPIImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      File selected = File(picked.path);
      if (await selected.exists()) {
        await _detectUPI(selected);
      } else {
        _showSnackbar("Selected image could not be loaded.");
      }
    }
  }

  Future<void> _detectUPI(File image) async {
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(image);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text;

      print("Extracted Text:\n$fullText");

      final upiRegex = RegExp(r'\b[\w.-]+@[\w]+\b');
      final matches = upiRegex.allMatches(fullText);

      if (matches.isNotEmpty) {
        String detectedUpi = matches.first.group(0)!;
        setState(() {
          _upiController.text = detectedUpi;
        });
      } else {
        _showSnackbar("No UPI ID found in the image. Please try another image.");
        setState(() {
          _upiController.text = "No UPI ID found - try another image";
        });
      }
    } catch (e) {
      _showSnackbar("Failed to process image: $e");
      setState(() {
        _upiController.text = "Error processing image - try again";
      });
    } finally {
      textRecognizer.close();
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildImagePreview() {
    if (_resizedImages.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No Images Selected',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _resizedImages.length,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _resizedImages[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),

          if (_resizedImages.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_resizedImages.length, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPageIndex ? Colors.white : Colors.grey,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  void _uploadProductDetails(String option) {
    String productName = _nameController.text;
    String productPrice = _priceController.text;
    String productDesc = _descController.text;
    String upiId = _upiController.text;

    if (_resizedImages.isEmpty || productName.isEmpty || productPrice.isEmpty || selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields!")),
      );
      return;
    }

    // Check if UPI ID is valid (not the default or error messages)
    if (upiId.isEmpty ||
        upiId == "Upload UPI image to detect ID" ||
        upiId == "No UPI ID found - try another image" ||
        upiId == "Error processing image - try again") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please upload a valid UPI ID image!")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadProducts(
          option: option,
          images: _resizedImages,
          productName: productName,
          productPrice: productPrice,
          productDesc: productDesc,
          productSize: selectedSize!,
          quantity: _quantity,
          category: selectedCategory!,
          gender: selectedGender!,
          upiId: upiId,
        ),
      ),
    );
  }

  void _increaseQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decreaseQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Provider.of<ThemeNotifier>(context).isDarkMode;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        leading: Padding(
          padding: EdgeInsets.only(top: 28),
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Scrollbar(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 10),
            child: Column(
              children: [
                _buildImagePreview(),
                SizedBox(height: 35),

                // Product Name
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Product Name",
                      labelStyle: TextStyle(
                        fontSize: 18,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),

                // Product Price
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Product Price",
                      labelStyle: TextStyle(
                        fontSize: 18,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Product Description
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      labelText: "Product Description",
                      labelStyle: TextStyle(
                        fontSize: 18,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // UPI ID Field with Image Upload Option
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "UPI ID",
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _upiController,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  fontStyle: _upiController.text == "Upload UPI image to detect ID" ||
                                      _upiController.text == "No UPI ID found - try another image" ||
                                      _upiController.text == "Error processing image - try again"
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Upload UPI image to detect ID",
                                  filled: true,
                                  fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.image, color: isDarkMode ? Colors.white : Colors.black),
                              onPressed: _pickUPIImage,
                              tooltip: "Upload UPI Image",
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          "Upload an image containing your UPI ID",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Size, Category and Gender Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Size Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedSize,
                          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          decoration: InputDecoration(
                            labelText: "Size",
                            labelStyle: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: sizes.map((size) {
                            return DropdownMenuItem<String>(
                              value: size,
                              child: Text(
                                size,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSize = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10),

                      // Quantity Selector
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Quantity",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove, size: 18),
                                  onPressed: _decreaseQuantity,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                Text(
                                  '$_quantity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add, size: 18),
                                  onPressed: _increaseQuantity,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),

                // Category and Gender Dropdowns
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Category Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          decoration: InputDecoration(
                            labelText: "Category",
                            labelStyle: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 20),

                      // Gender Dropdown
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedGender,
                          dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                          decoration: InputDecoration(
                            labelText: "Gender",
                            labelStyle: TextStyle(
                              fontSize: 16,
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: genders.map((gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(
                                gender,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedGender = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // Rent & Sell Buttons with Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rent Button
                    SizedBox(
                      width: screenWidth * 0.4,
                      child: ElevatedButton.icon(
                        onPressed: () => _uploadProductDetails("Rent"),
                        icon: Icon(Icons.lock_clock, size: 20),
                        label: Text(
                          "Rent",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Sell Button
                    SizedBox(
                      width: screenWidth * 0.4,
                      child: ElevatedButton.icon(
                        onPressed: () => _uploadProductDetails("Sell"),
                        icon: Icon(Icons.shopping_bag, size: 20),
                        label: Text(
                          "Sell",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.green[800] : Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}