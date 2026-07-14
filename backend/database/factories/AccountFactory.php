<?php

namespace Database\Factories;

use App\Models\Account;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Account>
 */
class AccountFactory extends Factory
{
    protected $model = Account::class;

    public function definition(): array
    {
        $opening = fake()->randomFloat(2, 0, 50000);

        return [
            'user_id' => User::factory(),
            'name' => fake()->words(2, true),
            'type' => fake()->randomElement(['cash', 'bank', 'mobile_banking', 'card', 'other']),
            'opening_balance' => $opening,
            'current_balance' => $opening,
            'color' => fake()->hexColor(),
            'icon' => 'wallet',
            'is_default' => false,
        ];
    }
}
