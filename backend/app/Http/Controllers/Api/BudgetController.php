<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\BudgetRequest;
use App\Http\Resources\BudgetResource;
use App\Models\Budget;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class BudgetController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        return $this->success(BudgetResource::collection($request->user()->budgets()->with('category')->latest('year')->latest('month')->get()));
    }

    public function store(BudgetRequest $request)
    {
        $budget = Budget::updateOrCreate(
            $request->safe()->only(['category_id', 'month', 'year']) + ['user_id' => $request->user()->id],
            ['amount' => $request->amount, 'period' => $request->period]
        );
        return $this->success(new BudgetResource($budget->load('category')), 'Budget saved', 201);
    }

    public function show(Request $request, Budget $budget)
    {
        abort_unless($budget->user_id === $request->user()->id, 404);
        return $this->success(new BudgetResource($budget->load('category')));
    }

    public function update(BudgetRequest $request, Budget $budget)
    {
        abort_unless($budget->user_id === $request->user()->id, 404);
        $budget->update($request->validated());
        return $this->success(new BudgetResource($budget->load('category')), 'Budget updated');
    }

    public function destroy(Request $request, Budget $budget)
    {
        abort_unless($budget->user_id === $request->user()->id, 404);
        $budget->delete();
        return $this->success(null, 'Budget deleted');
    }
}
