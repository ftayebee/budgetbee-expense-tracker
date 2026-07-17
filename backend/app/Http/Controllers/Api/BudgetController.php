<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\BudgetRequest;
use App\Http\Resources\BudgetResource;
use App\Models\Budget;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class BudgetController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        return $this->success(BudgetResource::collection($request->user()->budgets()->with('category')->latest('year')->latest('month')->get()));
    }

    public function store(BudgetRequest $request)
    {
        $validated = $request->validated();
        $budget = Budget::updateOrCreate(
            $request->safe()->only(['category_id', 'month', 'year']) + ['user_id' => $request->user()->id],
            $validated
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
        try {
            $validated = $request->validated();
            Log::info('Budget update requested', [
                'user_id' => $request->user()->id,
                'resource_id' => $budget->id,
                'request_method' => $request->method(),
                'validated_fields' => array_keys($validated),
            ]);
            $budget->update($validated);
            return $this->success(new BudgetResource($budget->load('category')), 'Budget updated');
        } catch (Throwable $exception) {
            Log::error('Budget update failed', [
                'user_id' => $request->user()->id,
                'resource_id' => $budget->id,
                'request_method' => $request->method(),
                'exception' => $exception->getMessage(),
                'trace' => $exception->getTraceAsString(),
            ]);
            throw $exception;
        }
    }

    public function destroy(Request $request, Budget $budget)
    {
        abort_unless($budget->user_id === $request->user()->id, 404);
        try {
            $budget->delete();
        } catch (Throwable $exception) {
            Log::error('Budget delete failed', [
                'user_id' => $request->user()->id,
                'resource_id' => $budget->id,
                'request_method' => $request->method(),
                'exception' => $exception->getMessage(),
                'trace' => $exception->getTraceAsString(),
            ]);
            throw $exception;
        }
        return $this->success(null, 'Budget deleted');
    }
}
