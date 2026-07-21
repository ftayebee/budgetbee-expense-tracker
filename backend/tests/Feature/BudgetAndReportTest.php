<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class BudgetAndReportTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Account $account;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
        $this->account = Account::factory()->for($this->user)->create();
    }

    public function test_budget_spent_and_remaining_reflect_transactions(): void
    {
        $cat = Category::factory()->expense()->for($this->user)->create();
        Transaction::factory()->for($this->user)->expense()->create([
            'account_id' => $this->account->id,
            'category_id' => $cat->id,
            'amount' => 1200,
            'transaction_date' => now()->toDateString(),
        ]);

        $this->postJson('/api/v1/budgets', [
            'category_id' => $cat->id,
            'amount' => 5000,
            'period' => 'monthly',
            'month' => (int) now()->month,
            'year' => (int) now()->year,
        ])->assertCreated();

        $budgets = $this->getJson('/api/v1/budgets')->assertOk();
        $this->assertEquals(1200.0, $budgets->json('data.0.spent'));
        $this->assertEquals(3800.0, $budgets->json('data.0.remaining'));
    }

    public function test_budget_requires_an_expense_category(): void
    {
        $incomeCat = Category::factory()->income()->for($this->user)->create();

        $this->postJson('/api/v1/budgets', [
            'category_id' => $incomeCat->id,
            'amount' => 5000,
            'period' => 'monthly',
            'month' => (int) now()->month,
            'year' => (int) now()->year,
        ])->assertStatus(422)->assertJsonValidationErrors('category_id');
    }

    public function test_creating_a_budget_for_existing_period_updates_it(): void
    {
        $cat = Category::factory()->expense()->for($this->user)->create();
        $payload = [
            'category_id' => $cat->id,
            'period' => 'monthly',
            'month' => (int) now()->month,
            'year' => (int) now()->year,
        ];

        $this->postJson('/api/v1/budgets', $payload + ['amount' => 1000])->assertCreated();
        $this->postJson('/api/v1/budgets', $payload + ['amount' => 2000])->assertCreated();

        $this->assertEquals(1, Budget::where('user_id', $this->user->id)->count());
        $this->assertEquals(2000.00, Budget::first()->amount);
    }

    public function test_category_summary_report_groups_by_category(): void
    {
        $food = Category::factory()->expense()->for($this->user)->create(['name' => 'Food']);
        $transport = Category::factory()->expense()->for($this->user)->create(['name' => 'Transport']);

        Transaction::factory()->for($this->user)->expense()->create(['account_id' => $this->account->id, 'category_id' => $food->id, 'amount' => 300]);
        Transaction::factory()->for($this->user)->expense()->create(['account_id' => $this->account->id, 'category_id' => $food->id, 'amount' => 200]);
        Transaction::factory()->for($this->user)->expense()->create(['account_id' => $this->account->id, 'category_id' => $transport->id, 'amount' => 100]);

        $report = $this->getJson('/api/v1/reports/category-summary')->assertOk();
        $totals = collect($report->json('data'))->pluck('total', 'category_id');
        $this->assertEquals(500, (float) $totals[$food->id]);
        $this->assertEquals(100, (float) $totals[$transport->id]);
    }

    public function test_analytics_dataset_is_bounded_filtered_and_excludes_transfers(): void
    {
        $food = Category::factory()->expense()->for($this->user)->create(['name' => 'Food']);
        $salary = Category::factory()->income()->for($this->user)->create(['name' => 'Salary']);
        $otherUser = User::factory()->create();
        $otherAccount = Account::factory()->for($otherUser)->create();

        Transaction::factory()->for($this->user)->expense()->create([
            'account_id' => $this->account->id,
            'category_id' => $food->id,
            'amount' => 300,
            'transaction_date' => '2026-07-12',
        ]);
        Transaction::factory()->for($this->user)->income()->create([
            'account_id' => $this->account->id,
            'category_id' => $salary->id,
            'amount' => 1000,
            'transaction_date' => '2026-07-14',
        ]);
        Transaction::factory()->for($otherUser)->expense()->create([
            'account_id' => $otherAccount->id,
            'category_id' => Category::factory()->expense()->for($otherUser)->create()->id,
            'amount' => 9999,
            'transaction_date' => '2026-07-12',
        ]);
        Transaction::factory()->for($this->user)->create([
            'type' => 'transfer',
            'account_id' => null,
            'category_id' => null,
            'from_account_id' => $this->account->id,
            'to_account_id' => Account::factory()->for($this->user)->create()->id,
            'amount' => 500,
            'transaction_date' => '2026-07-13',
        ]);

        $response = $this->getJson('/api/v1/reports/analytics?from=2026-07-01&to=2026-07-31')
            ->assertOk()
            ->assertJsonPath('data.from', '2026-07-01')
            ->assertJsonPath('data.to', '2026-07-31');

        $this->assertCount(2, $response->json('data.transactions'));
        $this->assertEquals(
            round((float) $this->user->accounts()->sum('opening_balance') + 700, 2),
            (float) $response->json('data.closing_balance'),
        );
        $this->assertEqualsCanonicalizing(
            ['expense', 'income'],
            collect($response->json('data.transactions'))->pluck('type')->all(),
        );

        $expenseOnly = $this->getJson('/api/v1/reports/analytics?from=2026-07-01&to=2026-07-31&type=expense')
            ->assertOk();
        $this->assertCount(1, $expenseOnly->json('data.transactions'));
        $this->assertSame('Food', $expenseOnly->json('data.transactions.0.category.name'));
    }

    public function test_empty_analytics_report_is_successful_and_logged(): void
    {
        Log::spy();

        $response = $this->getJson('/api/v1/reports/analytics?from=2026-07-01&to=2026-07-31')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(0, 'data.transactions');

        $this->assertSame(
            (float) $this->account->opening_balance,
            (float) $response->json('data.opening_balance'),
        );
        Log::shouldHaveReceived('info')
            ->withArgs(fn (string $message, array $context): bool =>
                $message === 'Reports API request received'
                && $context['report'] === 'analytics'
                && $context['user_id'] === $this->user->id);
        Log::shouldHaveReceived('info')
            ->withArgs(fn (string $message, array $context): bool =>
                $message === 'Reports API response successful'
                && $context['record_count'] === 0
                && isset($context['execution_ms']));
    }

    public function test_analytics_report_rejects_invalid_date_range(): void
    {
        $this->getJson('/api/v1/reports/analytics?from=2026-08-01&to=2026-07-01')
            ->assertUnprocessable()
            ->assertJsonPath('success', false)
            ->assertJsonStructure(['errors' => ['to']]);
    }
}
