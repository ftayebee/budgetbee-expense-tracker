<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    public function test_forgot_password_returns_generic_success_and_creates_a_token(): void
    {
        User::factory()->create(['email' => 'reset@example.com']);

        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'reset@example.com'])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseHas('password_reset_tokens', ['email' => 'reset@example.com']);
    }

    public function test_forgot_password_does_not_reveal_unknown_emails(): void
    {
        // Unknown email still returns 200 with the same generic message.
        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'nobody@example.com'])
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_forgot_password_requires_a_valid_email(): void
    {
        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'not-an-email'])
            ->assertStatus(422)->assertJsonValidationErrors('email');
    }

    public function test_user_can_reset_password_with_a_valid_token(): void
    {
        $user = User::factory()->create(['email' => 'reset@example.com']);
        $token = Password::createToken($user);

        $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'reset@example.com',
            'token' => $token,
            'password' => 'brand-new-pass',
            'password_confirmation' => 'brand-new-pass',
        ])->assertOk();

        $this->assertTrue(Hash::check('brand-new-pass', $user->fresh()->password));
    }

    public function test_reset_password_fails_with_an_invalid_token(): void
    {
        User::factory()->create(['email' => 'reset@example.com']);

        $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'reset@example.com',
            'token' => 'totally-invalid-token',
            'password' => 'brand-new-pass',
            'password_confirmation' => 'brand-new-pass',
        ])->assertStatus(422);
    }

    public function test_reset_password_revokes_existing_api_tokens(): void
    {
        $user = User::factory()->create(['email' => 'reset@example.com']);
        $user->createToken('android');
        $token = Password::createToken($user);

        $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'reset@example.com',
            'token' => $token,
            'password' => 'brand-new-pass',
            'password_confirmation' => 'brand-new-pass',
        ])->assertOk();

        $this->assertEquals(0, $user->fresh()->tokens()->count());
    }
}
