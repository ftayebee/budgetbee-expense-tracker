<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CategoryRequest;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use App\Support\ApiResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    use ApiResponse;

    public function index(Request $request)
    {
        $query = Category::whereNull('user_id')->orWhere('user_id', $request->user()->id);
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
        abort_unless($category->user_id === $request->user()->id, 404);
        $category->update($request->validated());
        return $this->success(new CategoryResource($category), 'Category updated');
    }

    public function destroy(Request $request, Category $category)
    {
        abort_unless($category->user_id === $request->user()->id, 404);
        if ($category->transactions()->exists() || $category->budgets()->exists()) {
            return $this->error('Category is in use and cannot be deleted.', [], 409);
        }
        $category->delete();
        return $this->success(null, 'Category deleted');
    }
}
