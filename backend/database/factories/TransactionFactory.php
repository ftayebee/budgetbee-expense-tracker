<?php

namespace Database\Factories;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Transaction>
 */
class TransactionFactory extends Factory
{
    protected $model = Transaction::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'account_id' => null,
            'category_id' => null,
            'title' => fake()->sentence(3),
            'type' => fake()->randomElement(['income', 'expense']),
            'amount' => fake()->randomFloat(2, 1, 5000),
            'transaction_date' => fake()->dateTimeBetween('-3 months', 'now')->format('Y-m-d'),
            'note' => fake()->optional()->sentence(),
            'payment_method' => fake()->randomElement(['Cash', 'Card', 'bKash', 'Bank Transfer']),
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
}
