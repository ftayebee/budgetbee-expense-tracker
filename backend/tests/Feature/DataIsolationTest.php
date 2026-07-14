<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DataIsolationTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_user_only_sees_their_own_transactions(): void
    {
        $me = User::factory()->create();
        $other = User::factory()->create();

        $myAccount = Account::factory()->for($me)->create();
        $myCat = Category::factory()->expense()->for($me)->create();
        Transaction::factory()->for($me)->create(['account_id' => $myAccount->id, 'category_id' => $myCat->id]);

        $otherAccount = Account::factory()->for($other)->create();
        $otherCat = Category::factory()->expense()->for($other)->create();
        Transaction::factory()->for($other)->create(['account_id' => $otherAccount->id, 'category_id' => $otherCat->id]);

        Sanctum::actingAs($me);
        $this->getJson('/api/v1/transactions')->assertOk()->assertJsonCount(1, 'data.data');
    }

    public function test_a_user_cannot_view_another_users_transaction(): void
    {
        $other = User::factory()->create();
        $account = Account::factory()->for($other)->create();
        $tx = Transaction::factory()->for($other)->create(['account_id' => $account->id]);

        Sanctum::actingAs(User::factory()->create());
        $this->getJson("/api/v1/transactions/{$tx->id}")->assertNotFound();
    }

    public function test_a_user_cannot_delete_another_users_account(): void
    {
        $other = User::factory()->create();
        $account = Account::factory()->for($other)->create();

        Sanctum::actingAs(User::factory()->create());
        $this->deleteJson("/api/v1/accounts/{$account->id}")->assertNotFound();
        $this->assertDatabaseHas('accounts', ['id' => $account->id]);
    }

    public function test_a_user_cannot_update_another_users_budget(): void
    {
        $other = User::factory()->create();
        // Use a global (default) expense category so validation passes and the
        // request reaches the controller's ownership check (which returns 404).
        $globalCat = Category::factory()->expense()->default()->create();
        $budget = Budget::factory()->for($other)->create(['category_id' => $globalCat->id]);

        Sanctum::actingAs(User::factory()->create());
        $this->putJson("/api/v1/budgets/{$budget->id}", [
            'category_id' => $globalCat->id,
            'amount' => 999,
            'period' => 'monthly',
            'month' => $budget->month,
            'year' => $budget->year,
        ])->assertNotFound();
    }
}
