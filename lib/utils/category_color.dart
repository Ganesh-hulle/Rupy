import 'dart:ui';
import 'package:flutter/material.dart';

/// Returns a consistent color for a given category name.
Color getCategoryColor(String categoryName) {
  if (categoryName.isEmpty) return Colors.grey;
  
  // Use hash code to pick a color from a predefined palette
  final hash = categoryName.hashCode;
  final index = hash.abs() % Colors.primaries.length;
  
  return Colors.primaries[index];
}
