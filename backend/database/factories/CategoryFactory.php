<?php

namespace Database\Factories;

use App\Models\Category;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Category>
 */
class CategoryFactory extends Factory
{
    protected $model = Category::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => fake()->unique()->word(),
            'type' => fake()->randomElement(['income', 'expense']),
            'icon' => 'category',
            'color' => fake()->hexColor(),
            'is_default' => false,
        ];
    }

    public function income(): static
    {
        return $this->state(fn () => ['type' => 'income']);
    }

    public function expense(): static
    {
        return $this->state(fn () => ['type' => 'expense']);
    }

    public function default(): static
    {
        return $this->state(fn () => ['user_id' => null, 'is_default' => true]);
    }
}
