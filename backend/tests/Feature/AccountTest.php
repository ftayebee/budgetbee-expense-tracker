<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AccountTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    }

    public function test_creating_an_account_sets_current_balance_to_opening_balance(): void
    {
        $this->postJson('/api/v1/accounts', [
            'name' => 'Savings',
            'type' => 'bank',
            'opening_balance' => 2500,
        ])->assertCreated()
            ->assertJsonPath('data.current_balance', 2500);
    }

    public function test_only_one_account_can_be_default(): void
    {
        $first = Account::factory()->for($this->user)->create(['is_default' => true]);

        $this->postJson('/api/v1/accounts', [
            'name' => 'New Default',
            'type' => 'cash',
            'opening_balance' => 0,
            'is_default' => true,
        ])->assertCreated();

        $this->assertFalse($first->fresh()->is_default);
        $this->assertEquals(1, Account::where('user_id', $this->user->id)->where('is_default', true)->count());
    }

    public function test_an_account_with_transactions_cannot_be_deleted(): void
    {
        $account = Account::factory()->for($this->user)->create();
        $cat = Category::factory()->expense()->for($this->user)->create();
        Transaction::factory()->for($this->user)->create(['account_id' => $account->id, 'category_id' => $cat->id]);

        $this->deleteJson("/api/v1/accounts/{$account->id}")->assertStatus(409);
        $this->assertDatabaseHas('accounts', ['id' => $account->id]);
    }

    public function test_an_empty_account_can_be_deleted(): void
    {
        $account = Account::factory()->for($this->user)->create();
        $this->deleteJson("/api/v1/accounts/{$account->id}")->assertOk();
        $this->assertDatabaseMissing('accounts', ['id' => $account->id]);
    }

    public function test_updating_an_account_does_not_change_current_balance_via_opening_balance(): void
    {
        $account = Account::factory()->for($this->user)->create([
            'opening_balance' => 100,
            'current_balance' => 350,
        ]);

        $this->putJson("/api/v1/accounts/{$account->id}", [
            'name' => 'Renamed',
            'type' => $account->type,
            'opening_balance' => 9999,
        ])->assertOk();

        $this->assertEquals(350.00, $account->fresh()->current_balance);
    }
}
