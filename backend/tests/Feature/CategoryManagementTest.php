<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CategoryManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_custom_category_can_be_updated_and_unused_category_deleted(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        $category = Category::factory()->expense()->for($user)->create();

        $this->putJson("/api/v1/categories/{$category->id}", [
            'name' => 'Dining',
            'type' => 'expense',
            'icon' => 'food',
            'color' => '#112233',
        ])->assertOk()
            ->assertJsonPath('data.name', 'Dining')
            ->assertJsonPath('data.color', '#112233');

        $this->deleteJson("/api/v1/categories/{$category->id}")
            ->assertOk();
        $this->assertDatabaseMissing('categories', ['id' => $category->id]);
    }

    public function test_used_category_returns_a_meaningful_conflict_without_deleting_transactions(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);
        $category = Category::factory()->expense()->for($user)->create();
        $account = Account::factory()->for($user)->create();
        $transaction = Transaction::factory()
            ->for($user)
            ->for($account)
            ->for($category)
            ->create(['type' => 'expense']);

        $this->deleteJson("/api/v1/categories/{$category->id}")
            ->assertStatus(409)
            ->assertJsonPath(
                'message',
                'This category is used by existing transactions and cannot be deleted.'
            );

        $this->assertDatabaseHas('transactions', ['id' => $transaction->id]);
        $this->assertDatabaseHas('categories', ['id' => $category->id]);
    }

    public function test_shared_category_edit_creates_an_owned_copy_and_moves_only_the_users_transactions(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $shared = Category::factory()->expense()->create([
            'user_id' => null,
            'name' => 'Food',
            'is_default' => true,
        ]);
        $account = Account::factory()->for($user)->create();
        $transaction = Transaction::factory()
            ->for($user)
            ->for($account)
            ->for($shared)
            ->create(['type' => 'expense']);
        Sanctum::actingAs($user);

        $response = $this->putJson("/api/v1/categories/{$shared->id}", [
            'name' => 'Dining',
            'type' => 'expense',
            'icon' => 'restaurant',
            'color' => '#F59E0B',
        ])->assertOk()->assertJsonPath('data.name', 'Dining');

        $personalId = $response->json('data.id');
        $this->assertNotSame($shared->id, $personalId);
        $this->assertDatabaseHas('categories', [
            'id' => $shared->id,
            'user_id' => null,
            'name' => 'Food',
        ]);
        $this->assertDatabaseHas('transactions', [
            'id' => $transaction->id,
            'category_id' => $personalId,
        ]);

        Sanctum::actingAs($other);
        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonFragment(['id' => $shared->id, 'name' => 'Food']);
    }

    public function test_deleting_an_unused_shared_category_hides_it_for_only_that_user(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $shared = Category::factory()->expense()->create([
            'user_id' => null,
            'name' => 'Health',
            'is_default' => true,
        ]);
        Sanctum::actingAs($user);

        $this->deleteJson("/api/v1/categories/{$shared->id}")->assertOk();
        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonMissing(['id' => $shared->id, 'name' => 'Health']);

        Sanctum::actingAs($other);
        $this->getJson('/api/v1/categories')
            ->assertOk()
            ->assertJsonFragment(['id' => $shared->id, 'name' => 'Health']);
    }
}
