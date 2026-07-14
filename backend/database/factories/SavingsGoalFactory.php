<?php

namespace Database\Factories;

use App\Models\SavingsGoal;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SavingsGoal>
 */
class SavingsGoalFactory extends Factory
{
    protected $model = SavingsGoal::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'account_id' => null,
            'name' => fake()->randomElement(['Emergency Fund', 'Laptop', 'Travel', 'Wedding']),
            'target_amount' => fake()->randomFloat(2, 5000, 100000),
            'current_amount' => 0,
            'target_date' => now()->addMonths(6)->toDateString(),
            'icon' => 'savings',
            'color' => fake()->hexColor(),
            'status' => 'active',
        ];
    }
}
