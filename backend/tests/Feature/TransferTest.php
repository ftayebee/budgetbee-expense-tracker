<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TransferTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Account $from;

    private Account $to;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
        $this->from = Account::factory()->for($this->user)->create(['opening_balance' => 1000, 'current_balance' => 1000]);
        $this->to = Account::factory()->for($this->user)->create(['opening_balance' => 0, 'current_balance' => 0]);
    }

    public function test_a_transfer_moves_money_between_accounts(): void
    {
        $this->postJson('/api/v1/transactions', [
            'title' => 'Move to savings',
            'type' => 'transfer',
            'amount' => 400,
            'from_account_id' => $this->from->id,
            'to_account_id' => $this->to->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $this->assertEquals(600.00, $this->from->fresh()->current_balance);
        $this->assertEquals(400.00, $this->to->fresh()->current_balance);
    }

    public function test_a_transfer_is_excluded_from_income_and_expense_totals(): void
    {
        $this->postJson('/api/v1/transactions', [
            'title' => 'Transfer',
            'type' => 'transfer',
            'amount' => 400,
            'from_account_id' => $this->from->id,
            'to_account_id' => $this->to->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $dashboard = $this->getJson('/api/v1/dashboard')->assertOk();
        $this->assertEquals(0.0, $dashboard->json('data.total_income'));
        $this->assertEquals(0.0, $dashboard->json('data.total_expense'));
        // Net balance across accounts is unchanged by a transfer.
        $this->assertEquals(1000.0, $dashboard->json('data.current_balance'));
    }

    public function test_cannot_transfer_to_the_same_account(): void
    {
        $this->postJson('/api/v1/transactions', [
            'title' => 'Invalid',
            'type' => 'transfer',
            'amount' => 100,
            'from_account_id' => $this->from->id,
            'to_account_id' => $this->from->id,
            'transaction_date' => now()->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors('from_account_id');
    }

    public function test_cannot_transfer_more_than_the_source_balance(): void
    {
        $this->postJson('/api/v1/transactions', [
            'title' => 'Too much',
            'type' => 'transfer',
            'amount' => 5000,
            'from_account_id' => $this->from->id,
            'to_account_id' => $this->to->id,
            'transaction_date' => now()->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors('amount');
    }

    public function test_deleting_a_transfer_restores_both_balances(): void
    {
        $create = $this->postJson('/api/v1/transactions', [
            'title' => 'Transfer',
            'type' => 'transfer',
            'amount' => 400,
            'from_account_id' => $this->from->id,
            'to_account_id' => $this->to->id,
            'transaction_date' => now()->toDateString(),
        ])->assertCreated();

        $this->deleteJson('/api/v1/transactions/'.$create->json('data.id'))->assertOk();

        $this->assertEquals(1000.00, $this->from->fresh()->current_balance);
        $this->assertEquals(0.00, $this->to->fresh()->current_balance);
    }
}
