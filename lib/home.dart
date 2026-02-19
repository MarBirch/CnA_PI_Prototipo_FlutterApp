// ignore: depend_on_referenced_packages
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final List<String> Img_list = [
    'assets/images/a.png',
    'assets/images/b.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child:  Center(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 30),
              CarouselSlider(
                options: CarouselOptions(
                  autoPlay: true,
                  enlargeCenterPage: true,
                  height: 250.0,
                  aspectRatio: 16 / 9,
                  initialPage: 0,
                  enableInfiniteScroll: true,
                  scrollDirection: Axis.horizontal,
                ),
                items: Img_list.map(
                  (item) => Image.asset(item, fit: BoxFit.cover),
                ).toList(),
              ),

              SizedBox(height: 50),
              Container(
                width: double.infinity,
                height: 300,
                color: Color.fromARGB(255, 255, 163, 42),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Se alimente bem de maneira rápida e prática.',
                      style: TextStyle(color: Colors.white, fontSize: 20,),textAlign: TextAlign.center,
                    ),
                    Text(
                      'Receba marmitas saudáveis, saborosas e balanceadas onde estiver.',
                      style: TextStyle(color: Colors.white, fontSize: 20,),textAlign: TextAlign.center,
                    ),
                  Text(
                    "A saúde na palma da sua mão, sem complicação!",
                      style: TextStyle(color: Colors.white, fontSize: 20),textAlign: TextAlign.center,
                    ), 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}