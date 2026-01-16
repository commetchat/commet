import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:tiamat/tiamat.dart' as tiamat;

class PhotoAlbumCreatorDescription extends StatelessWidget {
  const PhotoAlbumCreatorDescription({super.key});

  final images = const [
    AssetImage("assets/images/placeholders/photos/pexels-fr3nks-287229.jpg"),
    AssetImage(
        "assets/images/placeholders/photos/pexels-stijn-dijkstra-1306815-16747816.jpg"),
    AssetImage("assets/images/placeholders/photos/pexels-rdne-8474967.jpg"),
    AssetImage(
        "assets/images/placeholders/photos/pexels-james-lee-932763-2017111.jpg"),
    AssetImage(
        "assets/images/placeholders/photos/pexels-kostiantyn-35582290.jpg"),
    AssetImage(
        "assets/images/placeholders/photos/pexels-mikhail-nilov-8221589.jpg"),
    AssetImage("assets/images/placeholders/photos/pexels-nivdex-796206.jpg"),
    AssetImage("assets/images/placeholders/photos/pexels-krisof-1252873.jpg"),
    AssetImage("assets/images/placeholders/photos/pexels-byrahul-2162909.jpg"),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tiamat.Text.labelLow(
            "Share photos and videos with your friends or community!"),
        SizedBox(
          height: 30,
        ),
        MasonryGridView.extent(
          shrinkWrap: true,
          maxCrossAxisExtent: 170,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: images.length,
          itemBuilder: (context, index) {
            return ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(8),
                child: Image(image: images[index]));
          },
        )
      ],
    );
  }
}

class PhotoAlbumCreatorForm extends StatefulWidget {
  const PhotoAlbumCreatorForm({super.key});

  @override
  State<PhotoAlbumCreatorForm> createState() => _PhotoAlbumCreatorFormState();
}

class _PhotoAlbumCreatorFormState extends State<PhotoAlbumCreatorForm> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
