/* --- Common functions --- */

/* --- Intended to have private scope (not called by entities) --- */

/** Shuffle an array using Fisher-Yates Algorithm; Shuffled in-place */
function _shuffleArray(arr) {
    local len = arr.len();
    // Start from the last element and swap with a random element before it
    for (local i = len - 1; i > 0; i--) {
        // Generate a random index from 0 to i (inclusive)
        local j = RandomInt(0, i);
        
        // Swap array[i] with array[j]
        local temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}

/** Moves an element (matching value) to the front of an array, if present */
function _moveElementToFront(arr, val) {
    // Find the index of the value in the array
    local index = arr.find(val);
    
    // If find returns null, the element doesn't exist
    if (index != null) {
        // remove() returns the value at the given index
        // insert() puts it at the specified position (0 for front)
        arr.insert(0, arr.remove(index));
    }
    return arr;
}

/** Prints the elements of an array, space separated */
function _printlArray(arr) {
    foreach (index, value in arr) {
        print(value);
        // Print a space if it's not the last element
        if (index < arr.len() - 1) {
            print(" ");
        }
    }
    print("\n"); // Print the final newline
}

/**
 * Randomly selects up to 'count' non-consecutive numbers from the range [from, to]
 */
function _pickRandomNonConsecutive(from, to, count) {
    local selected = [];
    local invalid = {};

    local numbersPool = [];
    for (local i = from; i <= to; i++) { numbersPool.append(i); }
    _shuffleArray(numbersPool);

    foreach (num in numbersPool) {
        if (num in invalid) continue; // skip if number has been invalidated
        selected.append(num);

        // Mark the selected number, along its neighbours, as invalid
        invalid[num - 1] <- true;
        invalid[num] <- true;
        invalid[num + 1] <- true;

        if (selected.len() == count) break;
    }
    return selected;
}