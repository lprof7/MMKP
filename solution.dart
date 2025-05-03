import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'dart:math';

// --- Data Structures (Item, OrdredItem, BagInstance, InstanceData) ---
// (No changes needed in these basic data structures)
class Item {
  int profit;
  List<int> resourceUsage;

  Item({required this.profit, required this.resourceUsage});

  @override
  String toString() {
    return 'Item(profit: $profit, resourceUsage: $resourceUsage)';
  }
}

class OrdredItem {
  Item item;
  int index;
  late double ratio;
  OrdredItem(this.item, this.index);

  // Calculate ratio in an improved way
  void calculateRatio() {
    // Avoid division by zero and indirectly handle negative profits
    int totalResourceUsage = item.resourceUsage.fold(
        0,
        (sum, r) =>
            sum +
            max(1,
                r)); // Avoid division by zero or overly high ratios for zero usage

    // Improvement to handle zero or negative profit
    if (item.profit <= 0) {
      ratio =
          -double.infinity; // Items with no profit should not be prioritized
    } else if (totalResourceUsage == 0) {
      // Theoretically, if usage is zero and profit is positive, ratio is infinite
      // Practically, give it a very high but limited value
      ratio = item.profit * 1e9;
    } else {
      // Simple improvement to handle zero usage
      double weightedUsage = 0;
      for (int i = 0; i < item.resourceUsage.length; ++i) {
        weightedUsage += item.resourceUsage[i];
      }
      ratio = item.profit / max(1.0, weightedUsage); // Use max(1, usage)
    }
  }
}

class BagInstance {
  List<int> capacity;
  HashSet<int>
      items; // Can potentially be removed if Solution manages items solely

  BagInstance({required this.capacity}) : items = HashSet<int>();

  @override
  String toString() {
    return 'Bag(capacity: $capacity)';
  }
}

class InstanceData {
  int numItems;
  int numResources;
  int numBags;
  List<Item> items;
  List<BagInstance> bags;

  InstanceData({
    required this.numItems,
    required this.numResources,
    required this.numBags,
    required this.items,
    required this.bags,
  });

  @override
  String toString() {
    return 'InstanceData(numItems: $numItems, numResources: $numResources, numBags: $numBags, ${items.length} items, ${bags.length} bags)';
  }
}

// --- File Reading (readInstance, printInstanceData) ---
// (No changes needed)
Future<InstanceData> readInstance(String filePath) async {
  final file = File(filePath);
  final lines = await file.readAsLines(encoding: utf8);

  int lineIndex = 0;

  // Skip header line "NbrObjets NbrRessource"
  lineIndex++;

  // Read num_items and num_resources
  final counts =
      lines[lineIndex++].trim().split(RegExp(r'\s+')).map(int.parse).toList();
  final int numItems = counts[0];
  final int numResources = counts[1];

  // Skip header "les valeurs des objets"
  lineIndex++;

  // Read item profits
  List<int> profits = [];
  for (int i = 0; i < numItems; i++) {
    profits.add(int.parse(lines[lineIndex++].trim()));
  }

  // Skip header "les quatités des resources consommées pour chaque objet (ligne)"
  lineIndex++;

  // Read resource usage for each item and create Item objects
  List<Item> items = [];
  for (int i = 0; i < numItems; i++) {
    final usage =
        lines[lineIndex++].trim().split(RegExp(r'\s+')).map(int.parse).toList();
    if (usage.length != numResources) {
      throw FormatException(
          'Incorrect number of resource usages for item $i at line ${lineIndex}');
    }
    items.add(Item(profit: profits[i], resourceUsage: usage));
  }

  // Skip header "les quantités des ressources"
  lineIndex++;

  // Read bag capacities
  List<BagInstance> bags = [];
  while (lineIndex < lines.length) {
    // Skip bag header like "sac # 1"
    final line = lines[lineIndex].trim();
    if (line.isEmpty) {
      // Handle empty lines gracefully
      lineIndex++;
      continue;
    }
    if (!line.startsWith('sac #')) {
      // Handle potential empty lines or unexpected format at the end
      // Allow skipping empty lines or lines not starting with 'sac #' at the end
      if (lineIndex == lines.length - 1 && line.isEmpty) break;

      throw FormatException(
          'Expected bag header "sac #" at line ${lineIndex + 1}, found: "$line"');
    }
    lineIndex++;

    List<int> currentBagCapacity = [];
    for (int j = 0; j < numResources; j++) {
      // Check for unexpected end of file BEFORE reading the line
      if (lineIndex >= lines.length) {
        throw FormatException(
            'Unexpected end of file while reading capacities for bag ${bags.length + 1}');
      }
      final capacityLine = lines[lineIndex++].trim();
      if (capacityLine.isEmpty) {
        throw FormatException(
            'Empty line encountered while reading capacities for bag ${bags.length + 1} resource ${j + 1}');
      }
      currentBagCapacity.add(int.parse(capacityLine));
    }
    // // No need to check length again, already handled by the loop condition
    // if (currentBagCapacity.length != numResources) {
    //   throw FormatException(
    //       'Incorrect number of capacities for bag ${bags.length + 1}');
    // }
    bags.add(BagInstance(capacity: currentBagCapacity));
  }

  final int numBags = bags.length;

  // Data Validation
  if (numItems != items.length) {
    throw FormatException(
        'Mismatch between declared numItems ($numItems) and actual items read (${items.length})');
  }
  if (numBags != bags.length) {
    print(
        'Warning: Mismatch between expected number of bags based on loops and actual bags read. Found ${bags.length} bags.');
    // Allow proceeding if some bags were read, but maybe log this issue.
    // Or, if strictness is required:
    // throw FormatException('Mismatch between calculated numBags ($numBags based on loops/headers) and actual bags read (${bags.length})');
  }

  return InstanceData(
    numItems: numItems,
    numResources: numResources,
    numBags: numBags, // Use the actual number of bags read
    items: items,
    bags: bags,
  );
}

void printInstanceData(InstanceData data) {
  print('--- Instance Details ---');
  print('Number of Items (N): ${data.numItems}');
  print('Number of Resources (R): ${data.numResources}');
  print('Number of Bags (K): ${data.numBags}');

  print('\n--- Items (value, [resource usage]) ---');
  for (int i = 0; i < data.items.length; i++) {
    // print('Item ${i + 1}: ${data.items[i]}'); // Less verbose for large instances
  }
  print('First 5 Items (or fewer):');
  for (int i = 0; i < min(5, data.items.length); i++) {
    print('Item ${i + 1}: ${data.items[i]}');
  }
  if (data.items.length > 5) print('...');

  print('\n--- Bags ([capacities]) ---');
  for (int k = 0; k < data.bags.length; k++) {
    print('Bag ${k + 1}: ${data.bags[k]}');
  }
}

// --- Solution Class (Enhanced with Incremental Evaluation support) ---
class Solution {
  int numItems;
  int numBags;
  int numResources;

  // Stores which bag item `i` is in (-1 if unassigned)
  List<int> itemAssignment;
  // Stores current resource usage for each bag [bag][resource]
  List<List<int>> currentUsage;
  double profit;
  int iterationLastImproved;
  double diversity; // Compared to other elite solutions

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.writeln('Profit: $profit');
    // sb.writeln('Iteration Last Improved: $iterationLastImproved');
    // sb.writeln('Diversity Score: ${diversity.toStringAsFixed(4)}');

    for (int k = 0; k < numBags; k++) {
      List<int> bagItems = [];
      for (int i = 0; i < numItems; i++) {
        if (itemAssignment[i] == k) {
          bagItems.add(i); // Display 1-based index
        }
      }
      if (bagItems.isNotEmpty) {
        // sb.writeln('Bag ${k + 1} (Usage: ${currentUsage[k]}): ${bagItems.join(', ')}');
        sb.writeln(
            'Bag ${k + 1}: Items ${bagItems.join(', ')}'); // Simpler output
      } else {
        // sb.writeln('Bag ${k + 1} (Usage: ${currentUsage[k]}): Empty');
        sb.writeln('Bag ${k + 1}: Empty'); // Simpler output
      }
    }
    final unassigned = countUnassignedItems();
    if (unassigned > 0) {
      sb.writeln('Unassigned Items: $unassigned');
    }
    //sb.writeln('###################################');

    return sb.toString();
  }

  Solution(InstanceData data)
      : numItems = data.numItems,
        numBags = data.numBags,
        numResources = data.numResources,
        itemAssignment = List.filled(data.numItems, -1), // -1: unassigned
        currentUsage = List.generate(
            data.numBags, (_) => List.filled(data.numResources, 0)),
        profit = 0.0,
        iterationLastImproved = 0,
        diversity = 0.0;

  Solution.copy(Solution other)
      : numItems = other.numItems,
        numBags = other.numBags,
        numResources = other.numResources,
        itemAssignment = List.from(other.itemAssignment),
        // Deep copy of usage is crucial
        currentUsage = List.generate(
            other.numBags, (k) => List.from(other.currentUsage[k])),
        profit = other.profit,
        iterationLastImproved = other.iterationLastImproved,
        diversity = other.diversity;

  // --- Incremental Update Methods ---

  bool canAddItem(int itemIndex, int bagIndex, InstanceData data) {
    Item item = data.items[itemIndex];
    for (int r = 0; r < numResources; r++) {
      if (currentUsage[bagIndex][r] + item.resourceUsage[r] >
          data.bags[bagIndex].capacity[r]) {
        return false;
      }
    }
    return true;
  }

  bool canSwapItems(int itemOutIndex, int bagOutIndex, int itemInIndex,
      int bagInIndex, InstanceData data) {
    // Check if itemIn fits after itemOut is removed from bagOutIndex
    if (bagOutIndex == bagInIndex) {
      // Intra-bag swap
      Item itemOut = data.items[itemOutIndex];
      Item itemIn = data.items[itemInIndex];
      for (int r = 0; r < numResources; ++r) {
        int usageAfterSwap = currentUsage[bagOutIndex][r] -
            itemOut.resourceUsage[r] +
            itemIn.resourceUsage[r];
        if (usageAfterSwap > data.bags[bagOutIndex].capacity[r]) {
          return false;
        }
      }
    } else {
      // Inter-bag swap or swap with unassigned
      Item itemIn = data.items[itemInIndex];
      // Check capacity for itemIn in bagInIndex (itemOut doesn't affect this)
      if (bagInIndex != -1) {
        // Ensure bagInIndex is valid
        for (int r = 0; r < numResources; ++r) {
          if (currentUsage[bagInIndex][r] + itemIn.resourceUsage[r] >
              data.bags[bagInIndex].capacity[r]) {
            return false;
          }
        }
      }
      // itemOut will be removed from bagOutIndex, no capacity check needed there
    }
    return true;
  }

  void addItem(int itemIndex, int bagIndex, InstanceData data) {
    if (itemAssignment[itemIndex] != -1 || // Already assigned
        !canAddItem(itemIndex, bagIndex, data)) {
      // Consider throwing an error or logging if addItem is called inappropriately
      print("Error: Cannot add item $itemIndex to bag $bagIndex");
      return;
    }
    Item item = data.items[itemIndex];
    itemAssignment[itemIndex] = bagIndex;
    profit += item.profit;
    for (int r = 0; r < numResources; r++) {
      currentUsage[bagIndex][r] += item.resourceUsage[r];
    }
  }

  void removeItem(int itemIndex, InstanceData data) {
    int currentBag = itemAssignment[itemIndex];
    if (currentBag == -1) {
      // Not assigned
      print("Warning: Cannot remove unassigned item $itemIndex");
      return;
    }
    Item item = data.items[itemIndex];
    itemAssignment[itemIndex] = -1;
    profit -= item.profit;
    for (int r = 0; r < numResources; r++) {
      // Ensure usage doesn't go negative (shouldn't happen with correct logic)
      currentUsage[currentBag][r] =
          max(0, currentUsage[currentBag][r] - item.resourceUsage[r]);
    }
  }

  void moveItem(int itemIndex, int toBagIndex, InstanceData data) {
    int fromBagIndex = itemAssignment[itemIndex];
    if (fromBagIndex == toBagIndex) return; // No move needed
    if (fromBagIndex == -1) {
      // If item is unassigned, it's an add operation
      if (canAddItem(itemIndex, toBagIndex, data)) {
        addItem(itemIndex, toBagIndex, data);
      } else {
        print(
            "Error: Cannot move unassigned item $itemIndex to bag $toBagIndex (capacity)");
      }
      return;
    }

    // Check if item fits in the destination bag
    Item item = data.items[itemIndex];
    bool canMove = true;
    for (int r = 0; r < numResources; r++) {
      if (currentUsage[toBagIndex][r] + item.resourceUsage[r] >
          data.bags[toBagIndex].capacity[r]) {
        canMove = false;
        break;
      }
    }

    if (canMove) {
      // Remove from original bag
      for (int r = 0; r < numResources; r++) {
        currentUsage[fromBagIndex][r] =
            max(0, currentUsage[fromBagIndex][r] - item.resourceUsage[r]);
      }
      // Add to new bag
      itemAssignment[itemIndex] = toBagIndex;
      for (int r = 0; r < numResources; r++) {
        currentUsage[toBagIndex][r] += item.resourceUsage[r];
      }
      // Profit remains the same for a simple move
    } else {
      print(
          "Error: Cannot move item $itemIndex from $fromBagIndex to $toBagIndex (capacity)");
    }
  }

  // Swap item itemOutIndex (in bagOutIndex) with itemInIndex (currently unassigned or in bagInIndex)
  // Handles both swap with unassigned and inter/intra-bag swaps.
  void swapItems(int itemOutIndex, int itemInIndex, InstanceData data) {
    int bagOutIndex = itemAssignment[itemOutIndex];
    int bagInIndex = itemAssignment[itemInIndex]; // -1 if itemIn is unassigned

    if (bagOutIndex == -1) {
      print("Error: Cannot swap FROM an unassigned item ($itemOutIndex)");
      return;
    }

    Item itemOut = data.items[itemOutIndex];
    Item itemIn = data.items[itemInIndex];

    // Check feasibility *before* making changes
    bool feasible = true;

    // 1. Check if itemIn fits in bagOutIndex (after itemOut is removed)
    List<int> tempBagOutUsage = List.from(currentUsage[bagOutIndex]);
    for (int r = 0; r < numResources; ++r)
      tempBagOutUsage[r] -= itemOut.resourceUsage[r];
    if (bagInIndex != bagOutIndex) {
      // No need to check if swapping within same bag
      for (int r = 0; r < numResources; ++r) {
        if (tempBagOutUsage[r] + itemIn.resourceUsage[r] >
            data.bags[bagOutIndex].capacity[r]) {
          feasible = false;
          print(
              "Feasibility Check Failed: item $itemInIndex won't fit in bag $bagOutIndex after swap.");
          break;
        }
      }
    }

    // 2. Check if itemOut fits in bagInIndex (after itemIn is removed, if itemIn was assigned)
    if (feasible && bagInIndex != -1) {
      List<int> tempBagInUsage = List.from(currentUsage[bagInIndex]);
      for (int r = 0; r < numResources; ++r)
        tempBagInUsage[r] -= itemIn.resourceUsage[r];
      for (int r = 0; r < numResources; ++r) {
        if (tempBagInUsage[r] + itemOut.resourceUsage[r] >
            data.bags[bagInIndex].capacity[r]) {
          feasible = false;
          print(
              "Feasibility Check Failed: item $itemOutIndex won't fit in bag $bagInIndex after swap.");
          break;
        }
      }
    }

    if (!feasible) {
      //print("Error: Swap between item $itemOutIndex (bag $bagOutIndex) and item $itemInIndex (bag $bagInIndex) is infeasible.");
      return; // Abort swap
    }

    // --- Execute the swap ---

    // A. Update bagOutIndex
    profit -= itemOut.profit;
    for (int r = 0; r < numResources; r++) {
      currentUsage[bagOutIndex][r] =
          max(0, currentUsage[bagOutIndex][r] - itemOut.resourceUsage[r]);
    }
    if (bagInIndex != bagOutIndex) {
      // If not intra-bag swap, add itemIn
      itemAssignment[itemInIndex] = bagOutIndex;
      profit += itemIn.profit;
      for (int r = 0; r < numResources; r++) {
        currentUsage[bagOutIndex][r] += itemIn.resourceUsage[r];
      }
    }

    // B. Update bagInIndex (if itemIn was assigned)
    if (bagInIndex != -1 && bagInIndex != bagOutIndex) {
      profit -= itemIn.profit; // Already removed if intra-bag swap
      for (int r = 0; r < numResources; r++) {
        currentUsage[bagInIndex][r] =
            max(0, currentUsage[bagInIndex][r] - itemIn.resourceUsage[r]);
      }
      itemAssignment[itemOutIndex] = bagInIndex;
      profit += itemOut.profit;
      for (int r = 0; r < numResources; r++) {
        currentUsage[bagInIndex][r] += itemOut.resourceUsage[r];
      }
    } else if (bagInIndex == -1) {
      // itemIn was unassigned
      itemAssignment[itemOutIndex] = -1; // itemOut becomes unassigned
      // itemIn was already added to bagOutIndex in step A
    } else {
      // Intra-bag swap case (bagInIndex == bagOutIndex)
      // ItemIn already assigned to bagOutIndex in step A
      itemAssignment[itemOutIndex] =
          bagOutIndex; // Assign ItemOut back to the same bag
      profit += itemOut.profit; // Add ItemOut's profit back
      // Update usage for ItemOut in the same bag
      for (int r = 0; r < numResources; ++r) {
        currentUsage[bagOutIndex][r] += itemOut.resourceUsage[r];
      }
    }
  }

  // --- Other Helper Methods ---

  void calculateInitialProfitAndUsage(InstanceData data) {
    profit = 0;
    for (int k = 0; k < numBags; k++) {
      currentUsage[k].fillRange(0, numResources, 0);
    }

    for (int i = 0; i < numItems; i++) {
      int bagIndex = itemAssignment[i];
      if (bagIndex != -1) {
        Item item = data.items[i];
        profit += item.profit;
        for (int r = 0; r < numResources; r++) {
          currentUsage[bagIndex][r] += item.resourceUsage[r];
        }
      }
    }
  }

  // Verify if the incremental state matches a full calculation (for debugging)
  bool verifyState(InstanceData data) {
    double calculatedProfit = 0;
    List<List<int>> calculatedUsage =
        List.generate(numBags, (_) => List.filled(numResources, 0));
    bool constraintsOk = true;

    for (int i = 0; i < numItems; i++) {
      int bagIndex = itemAssignment[i];
      if (bagIndex != -1) {
        Item item = data.items[i];
        calculatedProfit += item.profit;
        for (int r = 0; r < numResources; r++) {
          calculatedUsage[bagIndex][r] += item.resourceUsage[r];
          if (calculatedUsage[bagIndex][r] > data.bags[bagIndex].capacity[r]) {
            print(
                "Verification Failed: Constraint violation for item $i in bag $bagIndex, resource $r (${calculatedUsage[bagIndex][r]} > ${data.bags[bagIndex].capacity[r]})");
            constraintsOk = false;
          }
        }
      }
    }

    if ((calculatedProfit - profit).abs() > 1e-9) {
      print(
          "Verification Failed: Profit mismatch. Stored: $profit, Calculated: $calculatedProfit");
      return false;
    }

    for (int k = 0; k < numBags; k++) {
      for (int r = 0; r < numResources; r++) {
        if (calculatedUsage[k][r] != currentUsage[k][r]) {
          print(
              "Verification Failed: Usage mismatch for bag $k, resource $r. Stored: ${currentUsage[k][r]}, Calculated: ${calculatedUsage[k][r]}");
          return false;
        }
      }
    }

    return constraintsOk;
  }

  int countAssignedItems() {
    int count = 0;
    for (int assignment in itemAssignment) {
      if (assignment != -1) {
        count++;
      }
    }
    return count;
  }

  int countUnassignedItems() {
    int count = 0;
    for (int assignment in itemAssignment) {
      if (assignment == -1) {
        count++;
      }
    }
    return count;
  }

  // Hamming distance based on item assignment
  int distanceTo(Solution other) {
    int distance = 0;
    for (int i = 0; i < numItems; i++) {
      if (itemAssignment[i] != other.itemAssignment[i]) {
        distance++;
      }
    }
    return distance;
  }

  // Check full constraint satisfaction (less frequent use now)
  bool satisfyConstraints(InstanceData data) {
    for (int k = 0; k < numBags; k++) {
      for (int r = 0; r < numResources; r++) {
        if (currentUsage[k][r] > data.bags[k].capacity[r]) {
          return false; // Incremental usage already violates
        }
      }
    }
    // No need to check double assignment with itemAssignment representation
    return true;
  }
}

// --- EliteSet Class ---
// (No major changes needed, relies on Solution's distanceTo and profit)
class EliteSet {
  List<Solution> solutions;
  int maxSize;
  double minDiversityThreshold;
  int numItems; // Needed for diversity calculation

  EliteSet(this.maxSize, this.minDiversityThreshold, this.numItems)
      : solutions = [];

  // إضافة حل إلى مجموعة النخبة إذا كان مؤهلاً
  bool add(Solution solution) {
    // Do not add if an identical solution (by assignment) exists
    for (var existing in solutions) {
      if (solution.distanceTo(existing) == 0) {
        // Potentially update if profit is higher? Unlikely with TS.
        return false;
      }
    }

    // إذا كانت المجموعة فارغة، أضف الحل مباشرة
    if (solutions.isEmpty) {
      solutions.add(
          Solution.copy(solution)..diversity = 1.0); // Max diversity initially
      return true;
    }

    // حساب التنوع بالنسبة للحلول الموجودة
    double minDiversity = double.infinity;
    for (var existingSolution in solutions) {
      int distance = solution.distanceTo(existingSolution);
      double diversity = (numItems > 0) ? distance / numItems : 0.0;
      if (diversity < minDiversity) {
        minDiversity = diversity;
      }
    }

    solution.diversity = minDiversity; // Assign calculated diversity

    // إعادة حساب تنوع الحلول الحالية (قد يتأثر بالحل الجديد) - اختياري لكن جيد
    _recalculateDiversity();

    // Find worst solution based on combined metric (lower is worse)
    int worstIndex = -1;
    double worstValue = double.infinity;
    for (int i = 0; i < solutions.length; i++) {
      // قيمة مركبة تجمع بين الربح والتنوع النسبي
      // Normalize profit roughly? Maybe not necessary if scale isn't extreme.
      double value = solutions[i].profit *
          (1 + solutions[i].diversity); // Lower value is worse
      if (value < worstValue) {
        worstValue = value;
        worstIndex = i;
      }
    }

    // إذا كانت المجموعة غير ممتلئة، أضف الحل إذا كان متنوعًا بما فيه الكفاية
    if (solutions.length < maxSize) {
      if (minDiversity >= minDiversityThreshold || solutions.isEmpty) {
        solutions.add(Solution.copy(solution));
        _recalculateDiversity(); // Recalculate after adding
        return true;
      } else {
        // Optionally add even if below threshold if space available?
        // Depends on strategy - current logic prioritizes diversity first.
        return false; // Not diverse enough and space is available (strict)
      }
    } else {
      // المجموعة ممتلئة، نقارن مع الأسوأ
      // قيمة الحل الجديد
      double newValue = solution.profit * (1 + minDiversity);

      // استبدال أسوأ حل إذا كان الحل الجديد أفضل ويفي بالحد الأدنى للتنوع
      if (newValue > worstValue && minDiversity >= minDiversityThreshold) {
        solutions[worstIndex] = Solution.copy(solution);
        _recalculateDiversity(); // Recalculate after replacing
        return true;
      } else if (newValue > worstValue) {
        // It's better but doesn't meet diversity. Should we replace anyway?
        // Maybe replace if significantly better? Adds complexity.
        // Current logic: Only replace if meets diversity threshold too.
        return false;
      }
    }

    return false; // Didn't meet criteria for adding/replacing
  }

  // Recalculate diversity for all solutions in the set
  void _recalculateDiversity() {
    if (solutions.length <= 1) {
      if (solutions.isNotEmpty) solutions[0].diversity = 1.0;
      return;
    }
    for (int i = 0; i < solutions.length; ++i) {
      double minDiv = double.infinity;
      for (int j = 0; j < solutions.length; ++j) {
        if (i == j) continue;
        int dist = solutions[i].distanceTo(solutions[j]);
        double div = (numItems > 0) ? dist / numItems : 0.0;
        if (div < minDiv) minDiv = div;
      }
      solutions[i].diversity = minDiv;
    }
  }

  // الحصول على أفضل حل في المجموعة (حسب الربح)
  Solution getBestSolution() {
    if (solutions.isEmpty) throw StateError("Elite set is empty");
    Solution best = solutions[0];
    for (var solution in solutions) {
      if (solution.profit > best.profit) {
        best = solution;
      }
    }
    return Solution.copy(best);
  }

  // الحصول على حل عشوائي من المجموعة
  Solution getRandomSolution(Random random) {
    if (solutions.isEmpty) throw StateError("Elite set is empty");
    int index = random.nextInt(solutions.length);
    return Solution.copy(solutions[index]);
  }

  // الحصول على الحل الأكثر تنوعًا بالنسبة لحل معين
  Solution getMostDiverseSolution(Solution reference) {
    if (solutions.isEmpty) throw StateError("Elite set is empty");
    Solution mostDiverse = solutions[0];
    int maxDistance = reference.distanceTo(mostDiverse);

    for (var solution in solutions.skip(1)) {
      int distance = reference.distanceTo(solution);
      if (distance > maxDistance) {
        maxDistance = distance;
        mostDiverse = solution;
      }
    }
    return Solution.copy(mostDiverse);
  }
}

// --- Helper Functions (order_items, satisfyConstraints (now in Solution)) ---
List<OrdredItem> order_items(InstanceData data) {
  List<OrdredItem> result = [];
  for (int i = 0; i < data.items.length; i++) {
    result.add(OrdredItem(data.items[i], i));
    result.last.calculateRatio();
  }
  // Handle potential NaN or Infinity ratios robustly during sort
  result.sort((a, b) {
    if (a.ratio.isFinite && b.ratio.isFinite) {
      return b.ratio.compareTo(a.ratio); // Higher ratio first
    } else if (a.ratio.isInfinite && !b.ratio.isInfinite) {
      return -1; // Infinity is better than finite
    } else if (!a.ratio.isInfinite && b.ratio.isInfinite) {
      return 1;
    } else if (a.ratio.isNaN && !b.ratio.isNaN) {
      return 1; // NaN is worse than anything else
    } else if (!a.ratio.isNaN && b.ratio.isNaN) {
      return -1;
    } else {
      return 0; // Both infinite, both NaN, or identical finite
    }
  });
  return result;
}

// --- Tabu List (Enhanced with Adaptive Tenure) ---
class TabuList {
  List<int> list; // Stores iteration when item becomes non-tabu
  int baseTenure;
  int minTenure;
  int maxTenure;
  int currentIteration; // Needed to check if tabu
  Random random = Random();
  // Optional: Store tabu for specific moves (more complex)
  // Map<String, int> moveTabuList;

  TabuList(int numItems, this.baseTenure, this.minTenure, this.maxTenure)
      : list = List.generate(numItems, (_) => 0), // 0 means not tabu
        currentIteration = 0
  // moveTabuList = {}
  ;

  bool isTabu(int itemIndex) => list[itemIndex] > currentIteration;
  // bool isMoveTabu(String moveKey) => (moveTabuList[moveKey] ?? 0) > currentIteration;

  // Called at the START of each iteration
  void updateIteration(int iteration) {
    currentIteration = iteration;
  }

  // Update tenure based on search progress
  int calculateDynamicTenure(int iterationsSinceImprovement) {
    // Increase tenure if stuck
    int tenure = baseTenure;
    if (iterationsSinceImprovement > 100) {
      // Threshold needs tuning
      tenure += (iterationsSinceImprovement ~/ 50); // Increase more gradually
    }

    // Add random variation
    tenure += random.nextInt(max(1, baseTenure ~/ 4)) -
        max(1, baseTenure ~/ 8); // Smaller random range

    // Clamp tenure
    return tenure.clamp(minTenure, maxTenure);
  }

  void add(int itemIndex, int dynamicTenure) {
    list[itemIndex] = currentIteration + dynamicTenure;
  }

  // void addMove(String moveKey, int dynamicTenure){
  //      moveTabuList[moveKey] = currentIteration + dynamicTenure;
  //      // Optional: Clean up old moves from the map periodically
  // }

  // void decrement() {
  //  // No longer needed if storing target iteration
  // }

  // إعادة تعيين القائمة المحظورة (عند إعادة البدء)
  void reset() {
    list.fillRange(0, list.length, 0);
    // moveTabuList.clear();
  }
}

// --- Initial Solution Generation (Improved Strategies) ---
Solution generateImprovedInitialSolution(
    InstanceData data, List<OrdredItem> ordred, Random random) {
  // Strategy 1: Basic Greedy (First Fit based on ratio)
  Solution basicSolution = _buildGreedySolution(data, ordred, firstFit: true);

  // Strategy 2: Alternative Greedy (Round Robin assignment)
  Solution roundRobinSolution =
      _buildGreedySolution(data, ordred, roundRobin: true);

  // Strategy 3: Resource Fit Heuristic
  Solution resourceFitSolution = _buildResourceFitSolution(data, ordred);

  // Strategy 4: Random Greedy subset (Adds Robustness)
  List<OrdredItem> shuffledOrdred = List.from(ordred)..shuffle(random);
  Solution randomGreedySolution = _buildGreedySolution(
      data, shuffledOrdred.sublist(0, (data.numItems * 0.8).round()),
      firstFit: true); // Use a subset

  List<Solution> initialSolutions = [
    basicSolution,
    roundRobinSolution,
    resourceFitSolution,
    randomGreedySolution
  ];

  // Calculate profit/usage for all generated solutions AFTER construction
  for (var sol in initialSolutions) {
    sol.calculateInitialProfitAndUsage(data);
    // Verify constraints just in case
    if (!sol.verifyState(data)) {
      print("WARNING: Initial solution verification failed!");
      // Optionally remove the invalid solution? Or try to repair?
      // For now, just warn.
    }
  }

  initialSolutions.sort((a, b) => b.profit.compareTo(a.profit));
  print(
      "Generated ${initialSolutions.length} initial solutions. Best profit: ${initialSolutions.first.profit}");
  return initialSolutions.first; // Return the best one
}

Solution _buildGreedySolution(
    InstanceData data, List<OrdredItem> itemsToConsider,
    {bool firstFit = false, bool roundRobin = false}) {
  Solution solution = Solution(data);
  List<bool> itemAssigned = List.filled(data.numItems, false);
  int currentBagIndex = 0;

  for (var element in itemsToConsider) {
    int itemIndex = element.index;
    // Skip if already assigned by another process or is invalid index
    if (itemIndex < 0 || itemIndex >= data.numItems || itemAssigned[itemIndex])
      continue;

    bool assignedThisItem = false;
    if (roundRobin) {
      // Try current bag first, then cycle
      int startBag = currentBagIndex;
      do {
        if (solution.canAddItem(itemIndex, currentBagIndex, data)) {
          solution.addItem(itemIndex, currentBagIndex, data);
          itemAssigned[itemIndex] = true;
          assignedThisItem = true;
          break; // Assigned
        }
        currentBagIndex = (currentBagIndex + 1) % data.numBags;
      } while (currentBagIndex != startBag);
      // Move to next bag for next item if round robin succeeded or failed
      if (assignedThisItem) {
        // only advance if assigned successfully
        currentBagIndex = (currentBagIndex + 1) % data.numBags;
      }
    } else if (firstFit) {
      // Try all bags sequentially
      for (int k = 0; k < data.numBags; k++) {
        if (solution.canAddItem(itemIndex, k, data)) {
          solution.addItem(itemIndex, k, data);
          itemAssigned[itemIndex] = true;
          assignedThisItem = true;
          break; // Assigned to the first bag that fits
        }
      }
    }
    // If neither strategy specified or item wasn't assigned, it remains unassigned.
  }

  // Final calculation is done outside this helper
  // solution.calculateInitialProfitAndUsage(data);
  return solution;
}

Solution _buildResourceFitSolution(InstanceData data, List<OrdredItem> ordred) {
  Solution solution = Solution(data);
  List<bool> itemAssigned = List.filled(data.numItems, false);

  for (var element in ordred) {
    int itemIndex = element.index;
    if (itemIndex < 0 || itemIndex >= data.numItems || itemAssigned[itemIndex])
      continue;

    int bestBag = -1;
    double bestFitScore = -double.infinity; // Higher score is better fit

    for (int k = 0; k < data.numBags; k++) {
      // Check basic feasibility first
      if (!solution.canAddItem(itemIndex, k, data)) {
        continue;
      }

      // Calculate fitness score (e.g., minimize remaining capacity ratio difference)
      double currentFit = 0;
      List<int> usageAfterAdding = List.from(solution.currentUsage[k]);
      for (int r = 0; r < data.numResources; ++r)
        usageAfterAdding[r] += data.items[itemIndex].resourceUsage[r];

      for (int r = 0; r < data.numResources; r++) {
        int capacity = data.bags[k].capacity[r];
        if (capacity > 0) {
          // Penalize bags where the item consumes a large fraction of *remaining* capacity
          double remainingCapacity =
              (capacity - solution.currentUsage[k][r]).toDouble();
          double consumptionRatio = (remainingCapacity > 0)
              ? data.items[itemIndex].resourceUsage[r] / remainingCapacity
              : 1.0; // If no remaining, consumes 100%
          currentFit -= consumptionRatio; // We want smaller consumption ratios

          // Alternative: Reward higher utilization after adding
          // double utilizationAfter = usageAfterAdding[r] / capacity;
          // currentFit += utilizationAfter;
        } else {
          // Handle zero capacity bags? Should not happen with valid input.
        }
      }

      if (currentFit > bestFitScore) {
        bestFitScore = currentFit;
        bestBag = k;
      }
    }

    if (bestBag != -1) {
      solution.addItem(itemIndex, bestBag, data);
      itemAssigned[itemIndex] = true;
    }
  }
  // Final calculation done outside
  // solution.calculateInitialProfitAndUsage(data);
  return solution;
}

// --- Path Relinking (Enhanced: Bidirectional) ---
Solution pathRelinking(Solution source, Solution target, InstanceData data,
    Random random, TabuList? localTabuList) {
  // Run PR from source to target
  Solution bestS2T = _pathRelinkingOneWay(
      Solution.copy(source), target, data, random, localTabuList);

  // Run PR from target to source
  Solution bestT2S = _pathRelinkingOneWay(
      Solution.copy(target), source, data, random, localTabuList);

  // Return the better of the two results
  return (bestS2T.profit >= bestT2S.profit) ? bestS2T : bestT2S;
}

Solution _pathRelinkingOneWay(Solution start, Solution guide, InstanceData data,
    Random random, TabuList? localTabuList) {
  Solution current = Solution.copy(start); // Work on a copy
  Solution bestIntermediate = Solution.copy(start);

  // Identify differences (items with different assignments)
  List<int> differentItems = [];
  for (int i = 0; i < data.numItems; i++) {
    if (current.itemAssignment[i] != guide.itemAssignment[i]) {
      differentItems.add(i);
    }
  }

  differentItems.shuffle(random); // Process differences in random order

  for (int itemIndex in differentItems) {
    int currentBag = current.itemAssignment[itemIndex];
    int targetBag = guide.itemAssignment[itemIndex];

    if (currentBag == targetBag)
      continue; // Should not happen based on list generation

    // --- Try to apply the move towards the target assignment ---
    Solution tempNext = Solution.copy(current); // Create a temporary state
    bool moveApplied = false;

    // Check if item is tabu for this specific move (if localTabuList provided)
    bool tabu = localTabuList?.isTabu(itemIndex) ?? false;

    if (targetBag == -1) {
      // Target is unassigned -> Remove
      if (!tabu ||
          tempNext.profit - data.items[itemIndex].profit >
              bestIntermediate.profit) {
        // Allow tabu if aspiration
        tempNext.removeItem(itemIndex, data);
        moveApplied = true;
      }
    } else {
      // Target is an assigned bag
      if (currentBag == -1) {
        // Current is unassigned -> Add
        if (tempNext.canAddItem(itemIndex, targetBag, data)) {
          if (!tabu ||
              tempNext.profit + data.items[itemIndex].profit >
                  bestIntermediate.profit) {
            tempNext.addItem(itemIndex, targetBag, data);
            moveApplied = true;
          }
        }
      } else {
        // Current is assigned -> Move
        // Create a temporary solution to check feasibility of move
        Solution checkSol = Solution.copy(tempNext);
        checkSol.removeItem(itemIndex, data); // Remove first conceptually
        if (checkSol.canAddItem(itemIndex, targetBag, data)) {
          // Then check add
          if (!tabu || tempNext.profit > bestIntermediate.profit) {
            // Move profit is neutral, use regular aspiration
            tempNext.moveItem(itemIndex, targetBag, data); // Apply actual move
            moveApplied = true;
          }
        }
      }
    }

    // If the move was applied and feasible (implicit in move/add methods)
    if (moveApplied) {
      // current.verifyState(data); // DEBUG: Check consistency
      current = tempNext; // Commit the move to the main path walker

      // Update the best solution found along this path
      if (current.profit > bestIntermediate.profit) {
        bestIntermediate = Solution.copy(current);
      }
    }
    // If move was not applied (infeasible or tabu without aspiration), continue to next different item
  }

  // Return the best solution encountered on the path
  return bestIntermediate;
}

// --- Perturbation Function (for Restart Strategy) ---
Solution perturbSolution(Solution solution, InstanceData data, Random random,
    double perturbationFactor, List<OrdredItem> ordredItems) {
  print(
      "Applying perturbation with factor: ${perturbationFactor.toStringAsFixed(2)}");
  Solution perturbed = Solution.copy(solution);
  List<int> assignedItems = [];
  for (int i = 0; i < data.numItems; i++) {
    if (perturbed.itemAssignment[i] != -1) {
      assignedItems.add(i);
    }
  }
  assignedItems.shuffle(random);

  int itemsToRemove = (assignedItems.length * perturbationFactor).round();
  print("Attempting to remove $itemsToRemove items");
  int removedCount = 0;
  for (int i = 0; i < itemsToRemove && i < assignedItems.length; i++) {
    perturbed.removeItem(assignedItems[i], data);
    removedCount++;
  }
  print("Removed $removedCount items.");

  // Refill greedily using the ordered list (consider only currently unassigned items)
  print("Attempting to refill...");
  int filledCount = 0;
  List<bool> currentlyAssigned =
      List.generate(data.numItems, (i) => perturbed.itemAssignment[i] != -1);
  for (var element in ordredItems) {
    int itemIndex = element.index;
    if (itemIndex >= 0 &&
        itemIndex < data.numItems &&
        !currentlyAssigned[itemIndex]) {
      // If unassigned after perturbation
      for (int k = 0; k < data.numBags; k++) {
        if (perturbed.canAddItem(itemIndex, k, data)) {
          perturbed.addItem(itemIndex, k, data);
          currentlyAssigned[itemIndex] = true; // Mark as assigned now
          filledCount++;
          break; // Added to first fit bag
        }
      }
    }
  }
  print("Added $filledCount items during refill.");

  perturbed.calculateInitialProfitAndUsage(data); // Recalculate just in case
  print("Perturbed solution profit: ${perturbed.profit}");
  perturbed.verifyState(data); // Verify final state
  return perturbed;
}

// --- Long Term Memory (Frequency Counter) ---
class LongTermMemory {
  List<int> itemFrequency; // How often item included in elite/best solutions
  int numItems;
  double penaltyFactor; // How much to penalize frequent items

  LongTermMemory(this.numItems, this.penaltyFactor)
      : itemFrequency = List.filled(numItems, 0);

  void update(Solution solution) {
    for (int i = 0; i < numItems; ++i) {
      if (solution.itemAssignment[i] != -1) {
        itemFrequency[i]++;
      }
    }
    // Optional: Decay frequencies over time? Adds complexity.
  }

  // Get a penalty/bonus score for a potential move involving itemIndex
  double getMoveScoreAdjustment(int itemIndex, bool isAddingOrMovingIn) {
    if (!isAddingOrMovingIn)
      return 0.0; // Only penalize additions of frequent items

    // Normalize frequency? Maybe relative to max frequency?
    int maxFreq = itemFrequency.fold(0, (max, freq) => freq > max ? freq : max);
    if (maxFreq == 0) return 0.0; // Avoid division by zero

    double normalizedFreq = itemFrequency[itemIndex] / maxFreq;

    // Penalize based on normalized frequency and factor
    // Higher penalty means the item must be *very* profitable to overcome frequency penalty
    return -(normalizedFreq * penaltyFactor);
  }

  void reset() {
    itemFrequency.fillRange(0, numItems, 0);
  }
}

// --- Tabu Search Configuration (Extended) ---
class TabuSearchConfig {
  final int maxIterations;
  final int eliteSetMaxSize;
  final double eliteSetMinDiversity;
  final double tenurePercentage; // Base tenure % of numItems
  final int minTenure;
  final int maxTenure;
  final int maxIterationsWithoutImprovement; // For restart trigger
  final int pathRelinkingFrequency;
  final double restartPerturbationFactor; // % items to remove on restart
  final double
      swapMoveProbability; // Probability to try swap moves in a neighborhood exploration
  final double
      longTermMemoryPenaltyFactor; // How strongly to penalize frequent items

  TabuSearchConfig({
    required this.maxIterations,
    this.eliteSetMaxSize = 15, // Increased size
    this.eliteSetMinDiversity = 0.05, // Slightly stricter diversity
    this.tenurePercentage = 0.03, // Adjust base tenure
    this.minTenure = 5, // Lower min
    this.maxTenure = 80, // Lower max (adjust based on instance)
    this.maxIterationsWithoutImprovement = 1500, // Increased tolerance
    this.pathRelinkingFrequency = 100, // More frequent PR
    this.restartPerturbationFactor = 0.3, // Remove 30% on restart
    this.swapMoveProbability = 0.15, // Try swaps 15% of the time
    this.longTermMemoryPenaltyFactor = 0.1, // Moderate LTM penalty
  });
}

// --- Main Tabu Search Algorithm (Enhanced) ---
Solution tabuSearch(InstanceData data, TabuSearchConfig config, Random random) {
  List<OrdredItem> ordredItems = order_items(data);

  Solution current = generateImprovedInitialSolution(data, ordredItems, random);
  current.verifyState(data);
  Solution best = Solution.copy(current);
  print("Initial solution profit: ${current.profit}");

  TabuList tabuList = TabuList(
      data.numItems,
      (data.numItems * config.tenurePercentage)
          .round()
          .clamp(config.minTenure, config.maxTenure),
      config.minTenure,
      config.maxTenure);
  LongTermMemory ltm =
      LongTermMemory(data.numItems, config.longTermMemoryPenaltyFactor);
  EliteSet eliteSet = EliteSet(
      config.eliteSetMaxSize, config.eliteSetMinDiversity, data.numItems);
  eliteSet.add(best);
  ltm.update(best); // Initialize LTM

  int iterationsSinceImprovement = 0;
  int restartCounter = 0;
  final int maxRestarts =
      10; // Limit restarts to prevent infinite loops if something is wrong

  for (int iter = 0;
      iter < config.maxIterations && restartCounter <= maxRestarts;
      iter++) {
    tabuList.updateIteration(iter); // Update current iteration for tabu checks

    // --- Neighbor Exploration ---
    Solution? bestNeighbor;
    double bestNeighborScore =
        -double.infinity; // Score includes profit + LTM adjustment
    int bestMoveItem1 = -1; // Item involved in the best move
    int bestMoveItem2 = -1; // Second item for swaps
    int bestMoveBagTo = -1; // Destination bag (-1 for removal)
    // int bestMoveBagFrom = -1; // Source bag (can be derived from current)
    String bestMoveType = ""; // "add", "remove", "move", "swap"

    bool trySwaps = random.nextDouble() < config.swapMoveProbability;
    int dynamicTenure =
        tabuList.calculateDynamicTenure(iterationsSinceImprovement);

    // Explore Add, Remove, Move neighborhood
    if (!trySwaps) {
      // Iterate through all items
      for (int i = 0; i < data.numItems; i++) {
        int currentBag = current.itemAssignment[i];
        bool isItemTabu = tabuList.isTabu(i);

        // 1. Try Removing item i (if assigned)
        if (currentBag != -1) {
          double moveProfitChange = -data.items[i].profit.toDouble();
          double moveScore = current.profit + moveProfitChange; // Base score
          // LTM Adjustment (removing is neutral for LTM)

          // Aspiration: Allow tabu if it leads to a new overall best
          bool aspiration = isItemTabu && (moveScore > best.profit);

          if (!isItemTabu || aspiration) {
            if (moveScore > bestNeighborScore) {
              bestNeighborScore = moveScore;
              bestMoveItem1 = i;
              bestMoveBagTo = -1; // Indicates removal
              bestMoveType = "remove";
              // No need to create the full neighbor object yet
            }
          }
        }

        // 2. Try Moving item i (if assigned) to another bag k
        if (currentBag != -1) {
          for (int k = 0; k < data.numBags; k++) {
            if (k == currentBag) continue; // Don't move to same bag

            // Check feasibility incrementally (create a copy for check)
            Solution checkSol = Solution.copy(current);
            checkSol.removeItem(i, data);
            if (checkSol.canAddItem(i, k, data)) {
              double moveProfitChange = 0; // Profit is neutral for move
              double moveScore = current.profit +
                  moveProfitChange +
                  ltm.getMoveScoreAdjustment(i, true); // Adjust score

              bool aspiration = isItemTabu && (moveScore > best.profit);

              if (!isItemTabu || aspiration) {
                if (moveScore > bestNeighborScore) {
                  bestNeighborScore = moveScore;
                  bestMoveItem1 = i;
                  bestMoveBagTo = k;
                  bestMoveType = "move";
                }
              }
            }
          }
        }

        // 3. Try Adding item i (if unassigned) to bag k
        if (currentBag == -1) {
          for (int k = 0; k < data.numBags; k++) {
            if (current.canAddItem(i, k, data)) {
              double moveProfitChange = data.items[i].profit.toDouble();
              double moveScore = current.profit +
                  moveProfitChange +
                  ltm.getMoveScoreAdjustment(i, true);

              bool aspiration = isItemTabu && (moveScore > best.profit);

              if (!isItemTabu || aspiration) {
                if (moveScore > bestNeighborScore) {
                  bestNeighborScore = moveScore;
                  bestMoveItem1 = i;
                  bestMoveBagTo = k;
                  bestMoveType = "add";
                }
              }
            }
          }
        }
      } // End for loop items (add/remove/move)
    }
    // Explore Swap neighborhood
    else {
      // Simplified Swap: Randomly pick an assigned item and try swapping with a random unassigned item
      List<int> assignedIndices = [];
      List<int> unassignedIndices = [];
      for (int i = 0; i < data.numItems; ++i) {
        if (current.itemAssignment[i] != -1)
          assignedIndices.add(i);
        else
          unassignedIndices.add(i);
      }

      if (assignedIndices.isNotEmpty && unassignedIndices.isNotEmpty) {
        int itemsToTrySwapping = min(
            assignedIndices.length, 50); // Limit swap attempts per iteration

        for (int swapTry = 0; swapTry < itemsToTrySwapping; ++swapTry) {
          int itemOutIdx =
              assignedIndices[random.nextInt(assignedIndices.length)];
          int itemInIdx =
              unassignedIndices[random.nextInt(unassignedIndices.length)];
          int bagOut = current.itemAssignment[itemOutIdx];

          // Check feasibility incrementally (using a check method)
          if (current.canSwapItems(itemOutIdx, bagOut, itemInIdx, -1, data)) {
            // Swapping out from bagOut, into bagOut for itemIn

            double profitChange = data.items[itemInIdx].profit -
                data.items[itemOutIdx].profit.toDouble();
            double moveScore = current.profit +
                profitChange +
                ltm.getMoveScoreAdjustment(
                    itemInIdx, true); // LTM for incoming item

            // Tabu check (simplified: tabu if either item is tabu)
            bool isSwapTabu =
                tabuList.isTabu(itemOutIdx) || tabuList.isTabu(itemInIdx);
            bool aspiration =
                isSwapTabu && (current.profit + profitChange > best.profit);

            if (!isSwapTabu || aspiration) {
              if (moveScore > bestNeighborScore) {
                bestNeighborScore = moveScore;
                bestMoveItem1 = itemOutIdx; // Item being removed
                bestMoveItem2 = itemInIdx; // Item being added
                bestMoveBagTo = bagOut; // Destination for itemInIdx
                bestMoveType = "swap";
              }
            }
          }
        } // End swap attempt loop
      } // End if has items to swap
    } // End else (trySwaps)

    // --- Apply Best Move Found ---
    if (bestMoveType != "") {
      // Construct the best neighbor based on the stored move details
      bestNeighbor = Solution.copy(current);
      if (bestMoveType == "add") {
        bestNeighbor.addItem(bestMoveItem1, bestMoveBagTo, data);
        tabuList.add(bestMoveItem1, dynamicTenure); // Make item tabu
      } else if (bestMoveType == "remove") {
        bestNeighbor.removeItem(bestMoveItem1, data);
        tabuList.add(bestMoveItem1, dynamicTenure);
      } else if (bestMoveType == "move") {
        bestNeighbor.moveItem(bestMoveItem1, bestMoveBagTo, data);
        tabuList.add(bestMoveItem1, dynamicTenure);
      } else if (bestMoveType == "swap") {
        bestNeighbor.swapItems(
            bestMoveItem1, bestMoveItem2, data); // Executes the swap
        tabuList.add(bestMoveItem1, dynamicTenure); // Make both items tabu
        tabuList.add(bestMoveItem2, dynamicTenure);
      }

      // Verify the state after the move (for debugging)
      if (!bestNeighbor.verifyState(data)) {
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        print(
            "ERROR: State verification failed after applying $bestMoveType move.");
        print("Iteration: $iter");
        print("Current Profit: ${current.profit}");
        print("Neighbor Profit: ${bestNeighbor.profit}");
        print(
            "Best Move: $bestMoveType, Item1: $bestMoveItem1, Item2: $bestMoveItem2, BagTo: $bestMoveBagTo");
        print("Current State:\n$current");
        print("Intended Neighbor State:\n$bestNeighbor");
        // Potentially halt or revert
        // bestNeighbor = null; // Discard invalid neighbor
      } else {
        current = bestNeighbor; // Accept the move
      }
    }
    // If bestNeighbor is still null after verification failure
    if (bestNeighbor == null && bestMoveType != "") {
      // Failed to find a *valid* move (maybe only invalid neighbors generated or verification failed)
      print(
          "Warning: No valid neighbor found in iteration $iter, type=$bestMoveType. Incrementing stagnation counter.");
      iterationsSinceImprovement++;
    } else if (bestNeighbor != null) {
      // --- Update Best Solution and Elite Set ---
      if (current.profit > best.profit) {
        best = Solution.copy(current);
        best.iterationLastImproved = iter;
        iterationsSinceImprovement = 0;

        bool addedToElite = eliteSet.add(best);
        if (addedToElite) {
          ltm.update(
              best); // Update long term memory only when elite set changes
          // print("Added new solution to elite set (Profit: ${best.profit.toStringAsFixed(2)}, Size: ${eliteSet.solutions.length})");
        }

        print(
            "Iter $iter: New best profit = ${best.profit.toStringAsFixed(2)} (Elite size: ${eliteSet.solutions.length})");
        print(best);
        // print(best); // Optional: Print new best solution details
      } else {
        iterationsSinceImprovement++;
        // Allow adding good non-improving solutions to elite set?
        if (current.profit > (best.profit * 0.95)) {
          // Example: Add if within 95% of best
          bool added = eliteSet.add(current);
          // if(added) print("Added good non-improving solution to elite set (Profit: ${current.profit.toStringAsFixed(2)})");
        }
      }
    } else {
      // No move found at all (potentially empty neighborhood or all moves tabu without aspiration)
      iterationsSinceImprovement++;
      // if (iter % 1000 == 0) { // Reduce logging frequency
      //  print("Iter $iter: No improving or non-tabu move found.");
      //}
    }

    // --- Periodic Output ---
    if (iter % 1000 == 0 && iter > 0) {
      // Less frequent check-in
      print(
          "Iter $iter: Current Profit=${current.profit.toStringAsFixed(2)}, Best Profit=${best.profit.toStringAsFixed(2)}, Elite Size=${eliteSet.solutions.length}, Iters Since Improve=$iterationsSinceImprovement");
    }

    // --- Restart Strategy ---
    if (iterationsSinceImprovement >= config.maxIterationsWithoutImprovement) {
      print(
          "\n>>> Iter $iter: Max iterations without improvement reached. Applying RESTART strategy ($restartCounter) <<<\n");
      restartCounter++;
      iterationsSinceImprovement = 0;
      tabuList.reset();
      ltm.reset(); // Reset long term memory as well? Or keep it? Resetting is safer.

      if (eliteSet.solutions.length > 1) {
        // Option 1: Start from best elite
        // current = Solution.copy(eliteSet.getBestSolution());
        // Option 2: Start from most diverse relative to current best
        current = eliteSet.getMostDiverseSolution(best);
        // Option 3: Random elite solution
        // current = eliteSet.getRandomSolution(random);

        // Perturb the chosen elite solution
        current = perturbSolution(current, data, random,
            config.restartPerturbationFactor, ordredItems);
      } else {
        // If elite set is small or empty, generate a completely new initial solution
        print("Elite set small, generating new initial solution for restart.");
        current = generateImprovedInitialSolution(data, ordredItems, random);
      }

      // Update best if the perturbed/new solution is somehow better (unlikely but possible)
      if (current.profit > best.profit) {
        best = Solution.copy(current);
        eliteSet.add(best); // Add the new potentially better solution
        ltm.update(best);
      }
      // Make sure the 'best' solution known is still in the elite set after restart/perturb
      eliteSet.add(Solution.copy(best));

      continue; // Skip path relinking immediately after restart
    }

    // --- Path Relinking Strategy ---
    if (iter > 0 &&
        iter % config.pathRelinkingFrequency == 0 &&
        eliteSet.solutions.length > 1) {
      // print("--- Iter $iter: Applying Path Relinking ---");

      // Select target for PR (e.g., random from elite set)
      Solution target = eliteSet.getRandomSolution(random);
      // Alternative: Use the best solution as target
      // Solution target = eliteSet.getBestSolution();
      // Alternative: Use most diverse from current
      // Solution target = eliteSet.getMostDiverseSolution(current);

      if (current.distanceTo(target) > 0) {
        // Only run if different
        Solution prSolution = pathRelinking(current, target, data, random,
            null); // Pass null or a temporary TabuList if needed for PR

        // If PR found a better solution than current
        if (prSolution.profit > current.profit) {
          // print("Path Relinking found improved solution (Profit: ${prSolution.profit.toStringAsFixed(2)})");
          current = prSolution; // Adopt the PR solution

          // Update overall best if necessary
          if (current.profit > best.profit) {
            best = Solution.copy(current);
            best.iterationLastImproved = iter;
            iterationsSinceImprovement = 0;
            bool added = eliteSet.add(best);
            if (added) {
              ltm.update(best);
            }
            print(
                "Iter $iter: New best from Path Relinking! Profit = ${best.profit.toStringAsFixed(2)}");
          } else {
            // Add good non-improving PR solution to elite?
            eliteSet.add(current);
          }
        }
      }
    }
    print(best);
  } // End main iteration loop

  print("\n--- Tabu Search Finished ---");
  print("Total Iterations: ${config.maxIterations}");
  print("Restarts Applied: $restartCounter");
  print("Final Elite Set Size: ${eliteSet.solutions.length}");
  if (eliteSet.solutions.isNotEmpty) {
    print(
        "Best elite profit: ${eliteSet.getBestSolution().profit.toStringAsFixed(2)}");
  }

  // Return the best solution found overall
  return best;
}

// --- Main Execution ---
void main() async {
  String filename = 'KSMD-instance-500-10-5-.txt';
  print("Attempting to read instance file: $filename");
  try {
    final data = await readInstance(filename);
    print("Instance data read successfully:");
    printInstanceData(data);

    // --- Configuration ---
    TabuSearchConfig config = TabuSearchConfig(
      maxIterations: 500000, // Increase significantly
      eliteSetMaxSize: 20, // Larger elite set
      eliteSetMinDiversity: 0.3, // Stricter diversity needed for larger set
      tenurePercentage: 0.025, // Adjust based on numItems
      minTenure: 4, // Fine-tune
      maxTenure: max(15,
          (data.numItems * 0.05).round()), // Dynamic max tenure based on size
      maxIterationsWithoutImprovement: 4000, // Allow longer stagnation
      pathRelinkingFrequency: 50, // Very frequent PR
      restartPerturbationFactor: 0.35, // Perturb slightly more
      swapMoveProbability: 0.4, // Increase swap chance
      longTermMemoryPenaltyFactor: 0.15, // Slightly stronger LTM penalty
    );

    print('\nRunning Advanced Tabu Search with parameters:');
    print(' Max Iterations: ${config.maxIterations}');
    print(
        ' Elite Set Size: ${config.eliteSetMaxSize}, Min Diversity: ${config.eliteSetMinDiversity}');
    print(
        ' Tenure %: ${config.tenurePercentage}, Min: ${config.minTenure}, Max: ${config.maxTenure}');
    print(' Max Stagnation: ${config.maxIterationsWithoutImprovement}');
    print(' PR Frequency: ${config.pathRelinkingFrequency}');
    print(' Restart Perturbation: ${config.restartPerturbationFactor}');
    print(' Swap Probability: ${config.swapMoveProbability}');
    print(' LTM Penalty Factor: ${config.longTermMemoryPenaltyFactor}');

    Random random = Random(); // Create a single Random instance

    // --- Run Search ---
    final stopwatch = Stopwatch()..start();
    Solution finalBest = tabuSearch(data, config, random);
    stopwatch.stop();

    print('\n--- Final Best Solution Found ---');
    print(finalBest);
    print("------------------------------------");
    print(
        "Search completed in ${stopwatch.elapsedMilliseconds / 1000.0} seconds.");
    print("Final best profit: ${finalBest.profit}");
  } catch (e, stacktrace) {
    // Catch specific errors if needed, like FileSystemException
    print('Error occurred: $e');
    print('Stack trace:\n$stacktrace'); // Print stack trace for debugging
  }
}
