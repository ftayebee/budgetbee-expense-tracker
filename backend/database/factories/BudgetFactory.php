<?php

namespace Database\Factories;

use App\Models\Budget;
use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Budget>
 */
class BudgetFactory extends Factory
{
    protected $model = Budget::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'category_id' => Category::factory()->expense(),
            'amount' => fake()->randomFloat(2, 1000, 20000),
            'period' => 'monthly',
            'month' => (int) now()->month,
            'year' => (int) now()->year,
        ];
    }
}
