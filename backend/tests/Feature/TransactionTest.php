<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TransactionTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Account $account;

    private Category $expenseCat;

    private Category $incomeCat;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
        $this->account = Account::factory()->for($this->user)->create([
            'opening_balance' => 1000,
            'current_balance' => 1000,
        ]);
        $this->expenseCat = Category::factory()->expense()->for($this->user)->create();
        $this->incomeCat = Category::factory()->income()->for($this->user)->create();
    }

    public function test_creating_an_expense_decreases_the_account_balance(): void
    {
        $this->postJson('/api/v1/transactions', [
            'title' => 'Groceries',
            'type' => 'expense',
            'amount' => 250,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $this->assertEquals(750.00, $this->account->fresh()->current_balance);
        $this->assertDatabaseHas('transactions', ['title' => 'Groceries', 'user_id' => $this->user->id]);
    }

    public function test_creating_an_income_increases_the_account_balance(): void
    {
        $this->postJson('/api/v1/transactions', [
            'title' => 'Salary',
            'type' => 'income',
            'amount' => 500,
            'account_id' => $this->account->id,
            'category_id' => $this->incomeCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $this->assertEquals(1500.00, $this->account->fresh()->current_balance);
    }

    public function test_updating_a_transaction_reverses_the_old_effect_and_applies_the_new(): void
    {
        $create = $this->postJson('/api/v1/transactions', [
            'title' => 'Dinner',
            'type' => 'expense',
            'amount' => 200,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $id = $create->json('data.id');
        $this->assertEquals(800.00, $this->account->fresh()->current_balance);

        $this->putJson("/api/v1/transactions/{$id}", [
            'title' => 'Dinner',
            'type' => 'expense',
            'amount' => 500,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertOk();

        // 1000 - 500 (not 1000 - 200 - 500)
        $this->assertEquals(500.00, $this->account->fresh()->current_balance);
    }

    public function test_deleting_a_transaction_restores_the_account_balance(): void
    {
        $create = $this->postJson('/api/v1/transactions', [
            'title' => 'Shoes',
            'type' => 'expense',
            'amount' => 300,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $id = $create->json('data.id');
        $this->assertEquals(700.00, $this->account->fresh()->current_balance);

        $this->deleteJson("/api/v1/transactions/{$id}")->assertOk();
        $this->assertEquals(1000.00, $this->account->fresh()->current_balance);
        $this->assertDatabaseMissing('transactions', ['id' => $id]);
    }

    public function test_update_and_delete_return_consistent_json_envelopes(): void
    {
        $create = $this->postJson('/api/v1/transactions', [
            'title' => 'Production contract',
            'type' => 'expense',
            'amount' => 100,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $id = $create->json('data.id');
        $this->putJson("/api/v1/transactions/{$id}", [
            'title' => 'Updated contract',
            'type' => 'expense',
            'amount' => 125,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertOk()->assertJsonPath('success', true)->assertJsonPath('message', 'Transaction updated')->assertJsonPath('data.id', $id);

        $this->deleteJson("/api/v1/transactions/{$id}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Transaction deleted')
            ->assertJsonPath('data', null);
    }

    public function test_transaction_requires_valid_amount(): void
    {
        $this->postJson('/api/v1/transactions', [
            'title' => 'Bad',
            'type' => 'expense',
            'amount' => 0,
            'account_id' => $this->account->id,
            'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors('amount');
    }

    public function test_category_type_must_match_transaction_type(): void
    {
        // Using an income category on an expense transaction should fail.
        $this->postJson('/api/v1/transactions', [
            'title' => 'Mismatch',
            'type' => 'expense',
            'amount' => 100,
            'account_id' => $this->account->id,
            'category_id' => $this->incomeCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors('category_id');
    }

    public function test_cannot_use_another_users_account(): void
    {
        $otherAccount = Account::factory()->create();

        $this->postJson('/api/v1/transactions', [
            'title' => 'Steal',
            'type' => 'expense',
            'amount' => 100,
            'account_id' => $otherAccount->id,
            'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors('account_id');
    }

    public function test_transactions_can_be_searched_and_filtered(): void
    {
        $this->postJson('/api/v1/transactions', [
            'title' => 'Uber ride', 'type' => 'expense', 'amount' => 100,
            'account_id' => $this->account->id, 'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();
        $this->postJson('/api/v1/transactions', [
            'title' => 'Coffee', 'type' => 'expense', 'amount' => 50,
            'account_id' => $this->account->id, 'category_id' => $this->expenseCat->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $this->getJson('/api/v1/transactions?search=Uber')
            ->assertOk()
            ->assertJsonCount(1, 'data.data');
    }

    public function test_filters_sort_pagination_and_account_transfer_membership_work_together(): void
    {
        $destination = Account::factory()->for($this->user)->create([
            'opening_balance' => 0,
            'current_balance' => 0,
        ]);
        $this->postJson('/api/v1/transactions', [
            'title' => 'Wallet transfer',
            'type' => 'transfer',
            'amount' => 300,
            'from_account_id' => $this->account->id,
            'to_account_id' => $destination->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();
        foreach ([25, 75, 150] as $amount) {
            $this->postJson('/api/v1/transactions', [
                'title' => "Expense {$amount}",
                'type' => 'expense',
                'amount' => $amount,
                'account_id' => $destination->id,
                'category_id' => $this->expenseCat->id,
                'transaction_date' => now()->toDateString(),
            ])->assertCreated();
        }

        $this->getJson("/api/v1/transactions?account_id={$destination->id}&min_amount=50&sort=amount_desc&per_page=2")
            ->assertOk()
            ->assertJsonPath('data.meta.total', 3)
            ->assertJsonPath('data.meta.last_page', 2)
            ->assertJsonPath('data.data.0.type', 'transfer')
            ->assertJsonPath('data.data.0.amount', 300)
            ->assertJsonPath('data.data.1.amount', 150);
    }
}
