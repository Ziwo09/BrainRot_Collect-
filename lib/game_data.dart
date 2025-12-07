import 'package:flutter/material.dart';

enum Rarity { common, rare, epic, legendary }

// Extensie pentru a lua culorile și numele ușor
extension RarityExtension on Rarity {
  String get name {
    switch (this) {
      case Rarity.common:
        return "Common";
      case Rarity.rare:
        return "Rare";
      case Rarity.epic:
        return "Epic";
      case Rarity.legendary:
        return "Legendary";
    }
  }

  Color get color {
    switch (this) {
      case Rarity.common:
        return const Color(0xFFA0A0A0); // Gri
      case Rarity.rare:
        return const Color(0xFF0070DD); // Albastru
      case Rarity.epic:
        return const Color(0xFFA335EE); // Mov
      case Rarity.legendary:
        return const Color(0xFFFF8000); // Portocaliu
    }
  }

  int get tradeRequirement => 5; // Ai nevoie de 5 pentru a face upgrade
}

class GameCard {
  final String id;
  final String name;
  final String imagePath;
  final Rarity rarity;
  final String description;

  GameCard({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.rarity,
    required this.description,
  });
}

// Baza de date statică a tuturor cărților din joc
final List<GameCard> masterCardList = [
  // --- COMMON ---
  GameCard(
      id: 'c1',
      name: 'Batul',
      imagePath: 'assets/images/batul.jpg',
      rarity: Rarity.common,
      description: 'Un băț simplu. Periculos la nevoie.'),
  GameCard(
      id: 'c2',
      name: 'Aeroplanino',
      imagePath: 'assets/images/aeroplanino.jpg',
      rarity: Rarity.common,
      description: 'Zboară jos.'),
  GameCard(
      id: 'c3',
      name: 'Tree',
      imagePath: 'assets/images/tree.jpg',
      rarity: Rarity.common,
      description: 'Înțeleptul pădurii.'),

  // --- RARE ---
  GameCard(
      id: 'r1',
      name: 'Bananito',
      imagePath: 'assets/images/bananito.jpg',
      rarity: Rarity.rare,
      description: 'Alunecos și stilat.'),
  GameCard(
      id: 'r2',
      name: 'Ananasita',
      imagePath: 'assets/images/ananasita.jpg',
      rarity: Rarity.rare,
      description: 'O prezență exotică.'),
  GameCard(
      id: 'r3',
      name: 'Brimbrum',
      imagePath: 'assets/images/brimbrum.jpg',
      rarity: Rarity.rare,
      description: 'Pește zburător motorizat.'),

  // --- EPIC ---
  GameCard(
      id: 'e1',
      name: 'Ballerina',
      imagePath: 'assets/images/ballerina.jpg',
      rarity: Rarity.epic,
      description: 'Grație mortală.'),
  GameCard(
      id: 'e2',
      name: 'Bambini',
      imagePath: 'assets/images/bambini.jpg',
      rarity: Rarity.epic,
      description: 'Croissant cu picioare.'),
  GameCard(
      id: 'e3',
      name: 'Cactufant',
      imagePath: 'assets/images/cactufant.jpg',
      rarity: Rarity.epic,
      description: 'Jumătate cactus, jumătate elefant.'),

  // --- LEGENDARY ---
  GameCard(
      id: 'l1',
      name: 'Shark',
      imagePath: 'assets/images/shark.jpg',
      rarity: Rarity.legendary,
      description: 'Regele apelor în adidași.'),
  GameCard(
      id: 'l2',
      name: 'Croco',
      imagePath: 'assets/images/croco.jpg',
      rarity: Rarity.legendary,
      description: 'Avionul crocodil.'),
  GameCard(
      id: 'l3',
      name: 'Ananasopotam',
      imagePath: 'assets/images/ananasopotam.jpg',
      rarity: Rarity.legendary,
      description: 'Hibridul suprem.'),
];
