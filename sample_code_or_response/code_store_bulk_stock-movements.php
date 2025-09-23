public function storeBulk(Request $request)
    {
        DB::beginTransaction();
        
        try {
            $validated = $request->validate([
                'movement_date' => 'required',
                'notes' => 'nullable|string',
                'stock_items' => 'required|array|min:1',
                'stock_items.*.product_id' => 'required|exists:products,id',
                'stock_items.*.quantity_change' => 'required|numeric|not_in:0',
                'stock_items.*.source_type' => [
                    'required',
                    Rule::in([
                        'purchase', 'sale', 'manual_adjustment', 'return_in', 'return_out',
                        'transfer_in', 'transfer_out', 'damage', 'expired', 'lost', 
                        'found', 'initial_stock', 'other'
                    ])
                ],
                'stock_items.*.unit_cost' => 'nullable|numeric|min:0',
                'stock_items.*.notes' => 'nullable|string',
            ]);

            // Verify warehouse ownership
            $warehouse = Warehouse::orderBy('id', 'desc')
                                 //  ->where('id', $validated['warehouse_id'])
                                 ->where('user_id', Auth::id())
                                 ->first();

            if (!$warehouse) {
                return response()->json([
                    'success' => false,
                    'message' => 'Warehouse not found or access denied.',
                ], 404);
            }

            $createdMovements = [];
            $errors = [];

            foreach ($validated['stock_items'] as $index => $itemData) {
                try {
                    // Get product and verify ownership
                    $product = Product::where('id', $itemData['product_id'])
                                     ->where('user_id', Auth::id())
                                     ->first();

                    if (!$product) {
                        $errors[] = "Item {$index}: Product not found or access denied.";
                        continue;
                    }

                    // Calculate stock quantities
                    $quantityBefore = $product->stock_quantity;
                    $quantityAfter = $quantityBefore + $itemData['quantity_change'];

                    // Prevent negative stock
                    if ($quantityAfter < 0) {
                        $errors[] = "Item {$index}: Insufficient stock for {$product->name}. Current stock: {$quantityBefore}";
                        continue;
                    }

                    // Calculate costs
                    $unitCost = $itemData['unit_cost'] ?? $product->cost_price ?? 0;
                    $totalCost = abs($itemData['quantity_change']) * $unitCost;

                    // Determine movement type
                    $movementType = $itemData['quantity_change'] > 0 ? 'in' : 'out';

                    // Create stock movement
                    $stockMovement = StockMovement::create([
                        'user_id' => Auth::id(),
                        'product_id' => $product->id,
                        'warehouse_id' => $warehouse->id,
                        'product_name' => $product->name,
                        'product_sku' => $product->sku,
                        'quantity_before' => $quantityBefore,
                        'quantity_change' => $itemData['quantity_change'],
                        'quantity_after' => $quantityAfter,
                        'movement_type' => $movementType,
                        'source_type' => $itemData['source_type'],
                        'notes' => $itemData['notes'] ?? $validated['notes'],
                        'movement_date' => Carbon::parse($validated['movement_date']),
                        'unit_cost' => $unitCost,
                        'total_cost' => $totalCost,
                        'ip_address' => $request->ip(),
                        'user_agent' => $request->userAgent(),
                    ]);

                    // Update product stock
                    $product->update(['stock_quantity' => $quantityAfter]);

                    $createdMovements[] = $stockMovement;
                } catch (\Exception $e) {
                    $errors[] = "Item {$index}: " . $e->getMessage();
                }
            }

            if (!empty($errors) && empty($createdMovements)) {
                DB::rollBack();
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to create any stock movements.',
                    'errors' => $errors,
                ], 422);
            }

            DB::commit();

            $response = [
                'success' => true,
                'message' => count($createdMovements) . ' stock movements created successfully.',
                'data' => [
                    'stock_movements' => collect($createdMovements)->load(['product', 'warehouse']),
                    'created_count' => count($createdMovements),
                    'total_items' => count($validated['stock_items']),
                ],
            ];

            if (!empty($errors)) {
                $response['warnings'] = $errors;
            }

            return response()->json($response, 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Validation failed.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to create bulk stock movements.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }