# MMKP Tabu Search Solver 🔍🎒

A Dart implementation of a Tabu Search algorithm for the Multiple-choice Multidimensional Knapsack Problem (MMKP).

## 🚧 Features

- **Data Structures**  
  - `Item`, `OrderedItem`, `BagInstance`, `InstanceData`

- **File I/O**  
  - `readInstance()`, `printInstanceData()`

- **Solution Class**  
  - Deep‐copyable  
  - Incremental evaluation of fitness

- **EliteSet Class**  
  - Maintains best solutions

- **Helper Functions**  
  - `order_items()`  
  - `satisfyConstraints()` 

- **Tabu List**  
  - Adaptive tenure strategy

- **Initial Solution**  
  - Multiple generation strategies

- **Path Relinking**  
  - Bidirectional enhancement

- **Perturbation & Restart**  
  - Strategic diversification

- **Long‐Term Memory**  
  - Frequency‐based move counters

- **Configuration**  
  - Customizable parameters

- **Main Algorithm**  
  - Core Tabu Search loop with aspiration criteria, termination checks, and logging

## 🚀 Getting Started

1. Install Dart SDK ≥ 2.18  
2. Run:  
   ```bash
   dart run bin/main.dart --instance data/your_instance.mmkp
