import 'package:flutter/material.dart';

/// Level N needs N*100 XP to reach level N+1 (wireframe: Level 5, 420/500).
({int level, int into, int need}) levelFor(int totalXp) {
  int level = 1, rem = totalXp;
  while (rem >= level * 100) {
    rem -= level * 100;
    level++;
  }
  return (level: level, into: rem, need: level * 100);
}
