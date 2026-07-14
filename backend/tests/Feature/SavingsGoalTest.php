<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\SavingsGoal;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SavingsGoalTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
        Sanctum::actingAs($this->user);
    }

    public function test_a_user_can_create_a_savings_goal(): void
    {
        $this->postJson('/api/v1/savings-goals', [
            'name' => 'Emergency Fund',
            'target_amount' => 50000,
            'target_date' => now()->addMonths(10)->toDateString(),
        ])->assertCreated()
            ->assertJsonPath('data.name', 'Emergency Fund')
            ->assertJsonPath('data.status', 'active')
            ->assertJsonPath('data.current_amount', 0);
    }

    public function test_target_date_cannot_be_in_the_past(): void
    {
        $this->postJson('/api/v1/savings-goals', [
            'name' => 'Late',
            'target_amount' => 1000,
            'target_date' => now()->subDay()->toDateString(),
        ])->assertStatus(422)->assertJsonValidationErrors('target_date');
    }

    public function test_contributing_updates_progress_and_current_amount(): void
    {
        $goal = SavingsGoal::factory()->for($this->user)->create([
            'target_amount' => 1000,
            'current_amount' => 0,
        ]);

        $response = $this->postJson("/api/v1/savings-goals/{$goal->id}/contributions", ['amount' => 250])
            ->assertCreated();

        $this->assertEquals(250, $response->json('data.current_amount'));
        $this->assertEquals(25.0, $response->json('data.progress'));
        $this->assertEquals(750, $response->json('data.remaining_amount'));
        $this->assertEquals(250.00, $goal->fresh()->current_amount);
    }

    public function test_goal_is_completed_when_target_is_reached(): void
    {
        $goal = SavingsGoal::factory()->for($this->user)->create(['target_amount' => 1000]);

        $response = $this->postJson("/api/v1/savings-goals/{$goal->id}/contributions", ['amount' => 1000])
            ->assertCreated()
            ->assertJsonPath('data.status', 'completed');

        $this->assertEquals(100.0, $response->json('data.progress'));
    }

    public function test_removing_a_contribution_recalculates_the_goal(): void
    {
        $goal = SavingsGoal::factory()->for($this->user)->create(['target_amount' => 1000]);

        $create = $this->postJson("/api/v1/savings-goals/{$goal->id}/contributions", ['amount' => 1000])
            ->assertCreated();
        $contributionId = $create->json('data.contributions.0.id');
        $this->assertEquals('completed', $goal->fresh()->status);

        $response = $this->deleteJson("/api/v1/savings-goals/{$goal->id}/contributions/{$contributionId}")
            ->assertOk()
            ->assertJsonPath('data.status', 'active');

        $this->assertEquals(0, $response->json('data.current_amount'));
    }

    public function test_a_user_cannot_contribute_to_another_users_goal(): void
    {
        $othersGoal = SavingsGoal::factory()->create();

        $this->postJson("/api/v1/savings-goals/{$othersGoal->id}/contributions", ['amount' => 100])
            ->assertNotFound();
    }

    public function test_a_user_only_lists_their_own_goals(): void
    {
        SavingsGoal::factory()->for($this->user)->count(2)->create();
        SavingsGoal::factory()->count(3)->create();

        $this->getJson('/api/v1/savings-goals')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_cannot_link_another_users_account(): void
    {
        $othersAccount = Account::factory()->create();

        $this->postJson('/api/v1/savings-goals', [
            'name' => 'Goal',
            'target_amount' => 1000,
            'account_id' => $othersAccount->id,
        ])->assertStatus(422)->assertJsonValidationErrors('account_id');
    }
}
