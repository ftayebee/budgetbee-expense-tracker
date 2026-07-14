<?php

namespace Database\Seeders;

use App\Models\Account;
use App\Models\Category;
use App\Models\SavingsGoal;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $income = [
            ['Salary', 'work', '#22c55e'], ['Business', 'briefcase', '#0ea5e9'],
            ['Freelance', 'laptop', '#14b8a6'], ['Gift', 'redeem', '#a855f7'],
            ['Investment', 'trending_up', '#16a34a'], ['Other', 'add_circle', '#64748b'],
        ];
        $expense = [
            ['Food', 'restaurant', '#f59e0b'], ['Transport', 'directions_car', '#06b6d4'],
            ['Shopping', 'shopping_bag', '#ef4444'], ['Bills', 'receipt', '#eab308'],
            ['Health', 'local_hospital', '#f43f5e'], ['Education', 'school', '#3b82f6'],
            ['Entertainment', 'movie', '#8b5cf6'], ['Rent', 'home', '#6366f1'],
            ['Fuel', 'local_gas_station', '#f97316'], ['Other', 'category', '#64748b'],
        ];

        foreach ($income as [$name, $icon, $color]) {
            Category::firstOrCreate(['user_id' => null, 'name' => $name, 'type' => 'income'], ['icon' => $icon, 'color' => $color, 'is_default' => true]);
        }
        foreach ($expense as [$name, $icon, $color]) {
            Category::firstOrCreate(['user_id' => null, 'name' => $name, 'type' => 'expense'], ['icon' => $icon, 'color' => $color, 'is_default' => true]);
        }

        $user = User::factory()->create([
            'name' => 'Demo User',
            'email' => 'demo@example.com',
            'password' => Hash::make('password'),
            'currency' => 'BDT',
        ]);

        $cash = Account::create(['user_id' => $user->id, 'name' => 'Cash Wallet', 'type' => 'cash', 'opening_balance' => 5000, 'current_balance' => 5000, 'color' => '#14b8a6', 'icon' => 'wallet', 'is_default' => true]);
        $bank = Account::create(['user_id' => $user->id, 'name' => 'City Bank', 'type' => 'bank', 'opening_balance' => 25000, 'current_balance' => 25000, 'color' => '#0ea5e9', 'icon' => 'account_balance']);
        $bkash = Account::create(['user_id' => $user->id, 'name' => 'bKash', 'type' => 'mobile_banking', 'opening_balance' => 3000, 'current_balance' => 3000, 'color' => '#e2136e', 'icon' => 'phone_android']);

        $rows = [
            [$bank, 'income', 'Salary', 'April Salary', 45000, 'Bank Transfer', now()->subDays(8)],
            [$bank, 'income', 'Freelance', 'Landing page project', 12000, 'Bank Transfer', now()->subDays(5)],
            [$cash, 'expense', 'Food', 'Grocery shopping', 2400, 'Cash', now()->subDays(4)],
            [$bkash, 'expense', 'Transport', 'Ride sharing', 650, 'Mobile Banking', now()->subDays(3)],
            [$bank, 'expense', 'Rent', 'Apartment rent', 16000, 'Bank Transfer', now()->subDays(2)],
            [$cash, 'expense', 'Entertainment', 'Movie night', 900, 'Cash', now()->subDay()],
        ];

        foreach ($rows as [$account, $type, $category, $title, $amount, $method, $date]) {
            $cat = Category::where('type', $type)->where('name', $category)->firstOrFail();
            Transaction::create([
                'user_id' => $user->id,
                'account_id' => $account->id,
                'category_id' => $cat->id,
                'title' => $title,
                'type' => $type,
                'amount' => $amount,
                'transaction_date' => $date->toDateString(),
                'payment_method' => $method,
            ]);
            $account->increment('current_balance', $type === 'income' ? $amount : -$amount);
        }

        $emergency = SavingsGoal::create([
            'user_id' => $user->id,
            'account_id' => $bank->id,
            'name' => 'Emergency Fund',
            'target_amount' => 100000,
            'current_amount' => 0,
            'target_date' => now()->addMonths(10)->toDateString(),
            'icon' => 'savings',
            'color' => '#14b8a6',
        ]);
        $emergency->contributions()->create(['amount' => 15000, 'contributed_at' => now()->subMonth()->toDateString()]);
        $emergency->contributions()->create(['amount' => 10000, 'contributed_at' => now()->subDays(5)->toDateString()]);
        $emergency->update(['current_amount' => 25000]);

        SavingsGoal::create([
            'user_id' => $user->id,
            'name' => 'New Laptop',
            'target_amount' => 120000,
            'current_amount' => 0,
            'target_date' => now()->addMonths(6)->toDateString(),
            'icon' => 'laptop',
            'color' => '#6366f1',
        ]);
    }
}
