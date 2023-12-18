import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '../models/product.dart';
import '../services/cart/cart_service.dart';

import '../widgets/designs/product_details_design.dart';
import 'cart_page.dart';

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({
    Key? key,
    required this.product,
  }) : super(key: key);

  final Product product;

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _bookmarksCollection =
  FirebaseFirestore.instance.collection('bookmarks');
  late TapGestureRecognizer readMoreGestureRecognizer;
  bool showMore = false;
  bool addingToCart = false; // Track whether the product is being added to the cart
  bool isBookmarked = false; // Variable to track bookmark status


  void addToCart() {
    // Add the product to the cart
    CartService().addToCart(widget.product);

    // Set state to trigger UI changes
    setState(() {
      addingToCart = true;
    });

    // Simulate a delay to show the loading indicator
    Future.delayed(const Duration(seconds: 2), () {
      // Reset addingToCart after the delay
      setState(() {
        addingToCart = false;
        // Display a snackbar message when the product is added to the cart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added to cart'),
            duration: Duration(seconds: 1),
          ),
        );
      });
    });
  }
  void toggleBookmark() {
    setState(() {
      isBookmarked = !isBookmarked;
    });
    _toggleBookmark(!isBookmarked);
  }

  Future<void> _toggleBookmark(bool isBookmarked) async {
    User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        if (isBookmarked) {
          // Remove bookmark
          await _bookmarksCollection
              .where('productId', isEqualTo: widget.product.id)
              .where('userId', isEqualTo: currentUser.uid)
              .get()
              .then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.delete();
            }
          });

          // Show SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product removed from bookmarks.'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          // Add bookmark
          await _bookmarksCollection.add({
            'productId': widget.product.id,
            'userId': currentUser.uid,
          });

          // Show SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product added to bookmarks.'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } catch (error) {
        print('Error toggling bookmark: $error');

        // Handle the error as needed
      }
    } else {
      // Handle the case when the user is not authenticated
      print('User is not authenticated.');
    }
  }

  @override
  void initState() {
    super.initState();
    readMoreGestureRecognizer = TapGestureRecognizer()
      ..onTap = () {
        setState(() {
          showMore = !showMore;
        });
      };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: ProductDetailsDesign(
        product: widget.product,
        showMore: showMore,
        readMoreGestureRecognizer: readMoreGestureRecognizer,
        addToCart: addToCart,
        addingToCart: addingToCart,
        receiverUserEmail: widget.product.postedByUser.email,
        receiverUserId: widget.product.postedByUser.uid,
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: const Text("Details"),
      actions: [
        // Inside ProductDetailsPage build method
        StreamBuilder(
          stream: _bookmarksCollection
              .where('productId', isEqualTo: widget.product.id)
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            bool isBookmarked = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            return IconButton(
              onPressed: () {
                toggleBookmark();
              },
              iconSize: 18,
              icon: isBookmarked
                  ? const Icon(IconlyBold.bookmark)
                  : const Icon(IconlyLight.bookmark),
            );
          },
        ),
      ],
    );
  }
}