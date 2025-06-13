import 'package:card_watch/models/carousel_item.dart';
import 'package:flutter/material.dart';



class CarouselWidget extends StatelessWidget {
  final List<CarouselItem> items;

  const CarouselWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240, // Altezza aumentata per la didascalia
      child: PageView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Image.network(items[index].url, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  items[index].description,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}