<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CategoryRequest;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use App\Support\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class CategoryController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $userId = $request->user()->id;
        $personalizedSources = Category::where('user_id', $userId)
            ->whereNotNull('source_category_id')
            ->pluck('source_category_id');
        $query = Category::where(function ($categoryQuery) use ($userId, $personalizedSources) {
            $categoryQuery
                ->where(fn ($owned) => $owned
                    ->where('user_id', $userId)
                    ->where('is_hidden', false))
                ->orWhere(fn ($shared) => $shared
                    ->whereNull('user_id')
                    ->whereNotIn('id', $personalizedSources));
        });
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        return $this->success(CategoryResource::collection($query->orderBy('type')->orderBy('name')->get()));
    }

    public function store(CategoryRequest $request)
    {
        return $this->success(new CategoryResource(Category::create($request->validated() + ['user_id' => $request->user()->id])), 'Category created', 201);
    }

    public function show(Request $request, Category $category)
    {
        abort_unless($category->user_id === null || $category->user_id === $request->user()->id, 404);
        return $this->success(new CategoryResource($category));
    }

    public function update(CategoryRequest $request, Category $category)
    {
        $userId = $request->user()->id;
        abort_unless($category->user_id === null || (int) $category->user_id === (int) $userId, 404);
        try {
            $validated = $request->validated();
            if ($validated['type'] !== $category->type
                && $category->transactions()->where('user_id', $userId)->exists()) {
                Log::warning('Category update blocked because transactions exist', [
                    'user_id' => $userId,
                    'resource_id' => $category->id,
                    'request_method' => $request->method(),
                ]);
                return $this->error(
                    'Move existing transactions before changing this category’s transaction type.',
                    [],
                    409
                );
            }
            if ($validated['type'] !== 'expense'
                && $category->budgets()->where('user_id', $userId)->exists()) {
                Log::warning('Category update blocked because budgets exist', [
                    'user_id' => $userId,
                    'resource_id' => $category->id,
                    'request_method' => $request->method(),
                ]);
                return $this->error(
                    'Remove this category’s budgets before changing it to an income category.',
                    [],
                    409
                );
            }
            Log::info('Category update requested', [
                'user_id' => $request->user()->id,
                'resource_id' => $category->id,
                'request_method' => $request->method(),
                'validated_payload' => $validated,
            ]);
            $updated = DB::transaction(function () use ($category, $validated, $userId) {
                if ($category->user_id !== null) {
                    $category->update($validated);
                    return $category->refresh();
                }

                $personal = Category::updateOrCreate(
                    [
                        'user_id' => $userId,
                        'source_category_id' => $category->id,
                    ],
                    $validated + [
                        'is_default' => false,
                        'is_hidden' => false,
                    ]
                );
                \App\Models\Transaction::where('user_id', $userId)
                    ->where('category_id', $category->id)
                    ->update(['category_id' => $personal->id]);
                \App\Models\Budget::where('user_id', $userId)
                    ->where('category_id', $category->id)
                    ->update(['category_id' => $personal->id]);

                return $personal->refresh();
            });
            return $this->success(new CategoryResource($updated), 'Category updated');
        } catch (Throwable $exception) {
            Log::error('Category update failed', [
                'user_id' => $request->user()->id,
                'resource_id' => $category->id,
                'request_method' => $request->method(),
                'exception' => $exception->getMessage(),
                'trace' => $exception->getTraceAsString(),
            ]);
            throw $exception;
        }
    }

    public function destroy(Request $request, Category $category)
    {
        $userId = $request->user()->id;
        abort_unless($category->user_id === null || (int) $category->user_id === (int) $userId, 404);
        $managedCategory = $category->user_id === null
            ? Category::where('user_id', $userId)
                ->where('source_category_id', $category->id)
                ->first() ?? $category
            : $category;
        Log::info('Category delete requested', [
            'user_id' => $request->user()->id,
            'resource_id' => $category->id,
            'request_method' => $request->method(),
        ]);
        $transactionsInUse = $managedCategory->transactions()
            ->where('user_id', $userId)
            ->exists();
        if ($transactionsInUse) {
            Log::warning('Category delete blocked because transactions exist', [
                'user_id' => $userId,
                'resource_id' => $category->id,
                'request_method' => $request->method(),
            ]);
            return $this->error(
                'This category is used by existing transactions and cannot be deleted.',
                [],
                409
            );
        }
        $budgetsInUse = $managedCategory->budgets()
            ->where('user_id', $userId)
            ->exists();
        if ($budgetsInUse) {
            Log::warning('Category delete blocked because budgets exist', [
                'user_id' => $userId,
                'resource_id' => $category->id,
                'request_method' => $request->method(),
            ]);
            return $this->error('Delete this category’s budgets before deleting the category.', [], 409);
        }
        try {
            if ($managedCategory->user_id === null) {
                Category::updateOrCreate(
                    [
                        'user_id' => $userId,
                        'source_category_id' => $category->id,
                    ],
                    [
                        'name' => $category->name,
                        'type' => $category->type,
                        'icon' => $category->icon,
                        'color' => $category->color,
                        'is_default' => false,
                        'is_hidden' => true,
                    ]
                );
            } elseif ($managedCategory->source_category_id !== null) {
                $managedCategory->update(['is_hidden' => true]);
            } else {
                $managedCategory->delete();
            }
        } catch (Throwable $exception) {
            Log::error('Category delete failed', [
                'user_id' => $request->user()->id,
                'resource_id' => $category->id,
                'request_method' => $request->method(),
                'exception' => $exception->getMessage(),
                'trace' => $exception->getTraceAsString(),
            ]);
            throw $exception;
        }
        return $this->success(null, 'Category deleted');
    }
}
